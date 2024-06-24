import asyncio
import sys
import time
import traceback
import typing
from typing import Dict, List
from web3 import Web3

import requests

class InstanceInfo():
    id: str
    ip: str
    port: int

class UserData():
    instance_id: str
    external_id: str
    created_at: float
    expires_at: float
    # launch_args: Dict[str, LaunchAnvilInstanceArgs]
    anvil_instances: Dict[str, InstanceInfo]
    daemon_instances: Dict[str, InstanceInfo]
    metadata: Dict

def get_unprivileged_web3() -> Web3:
    return Web3(
        Web3.HTTPProvider(
            'http://127.0.0.1:8545'
        )
    )

class Watcher():
    def __init__(self) -> None:
        super().__init__()
        self.__router_address = "0x12975173B87F7595EE45dFFb2Ab812ECE596Bf84"
        self.__price_cache = {}
        self.__pair_cache = {}

    async def _init(self):
        self.__rpc_url = 'http://127.0.0.1:8545'
        # self.__challenge_contract = user_data["metadata"]["challenge_address"]
        # self.__router_address = (
        #     await self.call(
        #         await self.get_block_number(),
        #         self.__challenge_contract,
        #         "ROUTER()(address)",
        #     )
        # ).strip()
        print("router address = ", self.__router_address)

    def start(self):
        # while True:
        #     instance_body = requests.get(
        #         f"{ORCHESTRATOR}/instances/{INSTANCE_ID}"
        #     ).json()
        #     if instance_body["ok"] == False:
        #         raise Exception("oops")

        #     user_data = instance_body["data"]
        #     if any(
        #         [v not in user_data["metadata"] for v in self.__required_properties]
        #     ):
        #         time.sleep(1)
        #         continue

            # break

        self._run()

    def _run(self):
        asyncio.run(self.async_run())

    async def async_run(self, ):
        await self._init()

        while True:
            try:
                # 获取当前区块号
                block_number = await self.get_block_number()

                # 获取 flagCharity 地址
                flag_charity = await self.call(
                    block_number,             # 当前区块号
                    self.__router_address,    # 合约地址
                    "flagCharity()(address)", # 获取 flagCharity 地址的方法签名
                )

                # 获取所有上市代币的地址列表
                listing_tokens = await self.list_array(
                    block_number,                        # 当前区块号
                    self.__router_address,               # 合约地址
                    "listingTokensCount()(uint256)",     # 获取上市代币数量的方法签名
                    "listingTokens(uint256)(address)",   # 获取特定代币地址的方法签名，带有索引参数
                )

                # 获取所有 LP 代币的信息
                lp_tokens = await self.list_array(
                    block_number,                       # 当前区块号
                    self.__router_address,              # 合约地址
                    "lpTokensCount()(uint256)",         # 获取 LP 代币数量的方法签名
                    "lpTokensInfo(uint256)(string,address)", # 获取特定 LP 代币信息的方法签名，带有索引参数
                )

                # 处理 LP 代币信息，将获取到的 LP 代币信息按 '\n' 分割成两部分
                lp_tokens = [info.rsplit("\n", 1) for info in lp_tokens]

                async def calculate_token_price(addr):
                    price = await self.get_token_price(block_number, addr)
                    amount = await self.get_balance(block_number, addr, flag_charity)
                    return price * amount

                async def calculate_lp_token_price(i, res):
                    pool, addr = res
                    amount = await self.get_balance(block_number, addr, flag_charity)
                    (
                        token_amount_a,
                        token_amount_b,
                        total_supply,
                    ) = await self.get_pair_status(block_number, addr)

                    if total_supply == 0:
                        return 0

                    (price_a, price_b) = await self.get_pair_prices(
                        block_number, i, pool
                    )
                    if i in [0, 78, 79, 80, 81]:
                        print(f"index: {i}, price_a: {price_a}, price_b: {price_b}, amount_a: {token_amount_a}, amount_b: {token_amount_b}, amount: {amount}, totoal_supply: {total_supply}")
                    return (
                        ((price_a * token_amount_a) + (price_b * token_amount_b))
                        * amount
                        // total_supply
                    )

                acc = 0

                # Normal tokens
                acc += sum(
                    await asyncio.gather(
                        *[calculate_token_price(addr) for addr in listing_tokens]
                    )
                )

                # LP tokens
                acc += sum(
                    await asyncio.gather(
                        *[
                            calculate_lp_token_price(i, res)
                            for i, res in enumerate(lp_tokens)
                        ]
                    )
                )

                print("user has donated", acc // 10**18)

                # self.update_metadata(
                #     {
                #         "donated": str(acc),
                #     }
                # )
            except:
                traceback.print_exc()
                pass
            finally:
                await asyncio.sleep(5)

    async def get_token_price(self, block_number, addr: str) -> int:
        key = "token_%s" % addr
        if key not in self.__price_cache:
            self.__price_cache[key] = int(
                (
                    await self.call(
                        block_number,
                        self.__router_address,
                        "priceOf(address)(uint256)",
                        addr,
                    )
                ).split(" ")[0]
            )

        return self.__price_cache[key]

    # @audit - type of index is str
    async def get_pair_prices(
        self, block_number: int, index: str, pool_id: str
    ) -> typing.Tuple[int, int]:
        pool_name = "pool_%s" % pool_id
        if pool_name not in self.__pair_cache:
            token_a, token_b = (
                await self.call(
                    block_number,
                    self.__router_address,
                    "lpTokenPair(uint256)(address,address)",
                    str(index),
                )
            ).split()
            self.__pair_cache[pool_name] = (token_a, token_b)

        token_a, token_b = self.__pair_cache[pool_name]

        return (
            await self.get_token_price(block_number, token_a),
            await self.get_token_price(block_number, token_b),
        )

    async def get_pair_status(
        self, block_number: int, pair: str
    ) -> typing.Tuple[int, int, int]:
        result = await self.call(
            block_number,
            self.__router_address,
            "lpTokensStatus(address)(uint256,uint256,uint256)",
            pair,
        )
        return [int(x.split(" ")[0], 0) for x in result.strip().split("\n")]

    async def get_balance(self, block_number: int, token: str, who: str) -> int:
        result = await self.call(block_number, token, "balanceOf(address)", who)
        return int(result.strip(), 0)

    async def list_array(
        self, block_number, address, count_sig, element_sig
    ) -> typing.List[str]:
        res = await self.call(
            block_number,
            address,
            count_sig,
        )
        count = int(res)

        result = await asyncio.gather(
            *[
                self.call(
                    block_number,
                    address,
                    element_sig,
                    str(i),
                )
                for i in range(count)
            ]
        )
        return result

    async def call(self, block_number: int, address: str, sig: str, *call_args) -> str:
        proc = await asyncio.create_subprocess_exec(
            "cast",
            "call",
            "--rpc-url",
            self.__rpc_url,
            "-b",
            str(block_number),
            address,
            sig,
            *call_args,
            stdout=asyncio.subprocess.PIPE,
        )
        stdout, _ = await proc.communicate()
        return stdout.decode()[:-1]

    async def get_block_number(self) -> int:
        proc = await asyncio.create_subprocess_exec(
            "cast",
            "block-number",
            "--rpc-url",
            self.__rpc_url,
            stdout=asyncio.subprocess.PIPE,
        )
        stdout, _ = await proc.communicate()
        return int(stdout)


Watcher().start()
