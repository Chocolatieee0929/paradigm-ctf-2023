import subprocess, os
from web3 import Web3
from dotenv import load_dotenv
from foundry.anvil import anvil_setBalance, anvil_setCode

def get_privileged_web3() -> Web3:
    return Web3(
        Web3.HTTPProvider(
            'http://127.0.0.1:8545'
        )
    )

class Challenge():
    def run(self):
        # 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2:1:2:9:10:17:25:26:32:35:36:37:38:39
        self.deploy()

    # def get_anvil_instances(self) -> Dict[str,]:
    #     return {
    #         # "main": self.get_anvil_instance(fork_block_num=18_437_825),
    #     }

    def deploy(self) -> str:
        load_dotenv()

        web3 = get_privileged_web3()
        player = os.getenv("PLAYER")
        amount = 10**20

        anvil_setBalance(web3, player, hex(amount))

        corrupted_addrs = {}

        bitflips = []

        while True:
            bitflip = input("bitflip? ")
            if bitflip == "":
                break

            bitflips.append(bitflip)

            (addr, *bits) = bitflip.split(":")
            addr = Web3.to_checksum_address(addr)
            bits = [int(v) for v in bits]

            print(f"corrupting {addr} {bits}")

            if addr in corrupted_addrs:
                raise Exception("already corrupted this address")

            corrupted_addrs[addr] = True

            balance = web3.eth.get_balance(addr)
            print("balance", balance)
            if balance == 0:
                raise Exception("invalid target")

            code = bytearray(web3.eth.get_code(addr))
            for bit in bits:
                byte_offset = bit // 8
                bit_offset = 7 - bit % 8
                if byte_offset < len(code):
                    code[byte_offset] ^= 1 << bit_offset

            total_bits = len(code) * 8
            corrupted_balance = int(balance * (total_bits - len(bits)) / total_bits)

            print("corrupted_balance", corrupted_balance)

            anvil_setBalance(web3, addr, hex(corrupted_balance))
            anvil_setCode(web3, addr, "0x" + code.hex())

        self.update_metadata({"bitflips": ",".join(bitflips)})

Challenge().run()