import json
import time
import traceback
from threading import Thread

from ctf_server.types import UserData, get_unprivileged_web3, get_additional_account
from eth_abi import abi
from ctf_launchers.daemon import Daemon
from web3 import Web3
from web3.contract.contract import Contract
from web3.middleware.signing import construct_sign_and_send_raw_middleware


class Relayer(Daemon):
    def __init__(self):
        super().__init__(required_properties=["mnemonic", "challenge_address", "bridge_abi"])

    def _run(self, user_data: UserData):
        bridge_abi = user_data["metadata"]["bridge_abi"]

        challenge_addr = user_data["metadata"]["challenge_address"]

        # 使用助记词生成一个新的账户（中继账户）。  
        relayer = get_additional_account(user_data["metadata"]["mnemonic"], 0)
        # 初始化 L1 和 L2 区块链的 Web3 实例，并添加中继账户的签名中间件。
        l1 = get_unprivileged_web3(user_data, "l1")
        l1.middleware_onion.add(construct_sign_and_send_raw_middleware(relayer))
        l1.eth.default_account = relayer.address

        l2 = get_unprivileged_web3(user_data, "l2")
        l2.middleware_onion.add(construct_sign_and_send_raw_middleware(relayer))
        l2.eth.default_account = relayer.address

        # 通过调用链上合约方法获取桥接合约地址
        (bridge_address,) = abi.decode(
            ["address"],
            l1.eth.call(
                {
                    "to": l1.to_checksum_address(challenge_addr),
                    "data": l1.keccak(text="BRIDGE()")[:4].hex(),
                }
            ),
        )
        # 创建 L1 和 L2 上的桥接合约实例。
        l1_bridge = l1.eth.contract(
            address=l1.to_checksum_address(bridge_address), abi=bridge_abi
        )
        l2_bridge = l2.eth.contract(
            address=l2.to_checksum_address(bridge_address), abi=bridge_abi
        )

        # 启动两个线程分别处理 L1 和 L2 的区块同步和事件监听。
        Thread(target=self._relayer_worker, args=(l1, l1_bridge, l2_bridge)).start()
        Thread(target=self._relayer_worker, args=(l2, l2_bridge, l1_bridge)).start()

    def _relayer_worker(
        self, src_web3: Web3, src_bridge: Contract, dst_bridge: Contract
    ):
        _src_chain_id = src_web3.eth.chain_id
        _dst_chain_id = dst_bridge.w3.eth.chain_id
        _last_processed_block_number = src_web3.eth.block_number

        while True:
            try:
                # 持续轮询源链上的新区块，检查每个区块中的交易是否涉及到桥接合约。
                latest_block_number = src_web3.eth.block_number
                if _last_processed_block_number > latest_block_number:
                    print(
                        f"chain {_src_chain_id} overran block {_last_processed_block_number} {latest_block_number}, wtf?"
                    )
                    _last_processed_block_number = latest_block_number

                print(
                    f"chain {_src_chain_id} syncing {_last_processed_block_number + 1} {latest_block_number + 1}"
                )
                for i in range(
                    _last_processed_block_number + 1, latest_block_number + 1
                ):
                    _last_processed_block_number = i
                    found = False
                    for tx_hash in src_web3.eth.get_block(i).transactions:
                        tx = src_web3.eth.get_transaction(tx_hash)
                        print(
                            f'chain {_src_chain_id} checking block {i} tx {tx_hash.hex()} {tx["to"]} {src_bridge.address}'
                        )
                        if tx["to"] == src_bridge.address:
                            found = True
                            break
                    if found:
                        # 如果发现涉及到桥接合约的交易，提取相关事件日志。
                        for event in src_bridge.events:
                            logs = event.get_logs(fromBlock=i, toBlock=i)
                            for log in logs:
                                print(
                                    f"chain {_src_chain_id} got log {src_web3.to_json(log)}"
                                )
                                if log.event == "SendRemoteMessage":
                                    try:

                                        # @audit - 需要对sourceAddress, targetAddress进行校验
                                        if _dst_chain_id == log.args["targetChainId"]:
                                            # 对于符合条件的事件日志，调用目标链上的桥接合约方法进行消息中继
                                            tx_hash = dst_bridge.functions.relayMessage(
                                                log.args["targetAddress"],
                                                _src_chain_id,
                                                log.args["sourceAddress"],
                                                log.args["msgValue"],
                                                log.args["msgNonce"],
                                                log.args["msgData"],
                                            ).transact()

                                            dst_bridge.w3.eth.wait_for_transaction_receipt(
                                                tx_hash
                                            )
                                            time.sleep(1)
                                    except Exception as e:
                                        print(e)
            except:
                traceback.print_exc()
                pass
            finally:
                time.sleep(1)


Relayer().start()
