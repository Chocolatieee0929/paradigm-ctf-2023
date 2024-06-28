import os
import subprocess
from dotenv import load_dotenv

# 加载.env文件中的环境变量
load_dotenv()
rpc_url=os.getenv("LOCAL_RPC")
target_bytes = int("33ff5f5ff3", 16)
# https://etherscan.io/accounts
def to_pos(binary):
    pos = 0
    count = 0
    out=''
    for b in binary:
        if b == "1":
            out+=f":{pos}"
        pos += 1
    return out

def gen_flip():
    inputAddr = input("addr? ")
    addr = inputAddr
    command = ["cast", "code", addr, "--rpc-url", rpc_url]
    while(addr != ''):
        flip_str = ''
        addr = addr[:-1]
        try:
    # 执行命令并获取输出
            output = subprocess.check_output(command)

            # 处理输出，确保转换为字符串并且去除换行符等额外字符
            output_str = output.decode("utf-8").strip()

            # 输出内容
            # print(f"Command '{' '.join(command)}' executed successfully.")0x8315177aB297bA92A06054cE80a67Ed4DBd7ed3a
            # print(f"Output: {output_str}")

            # 解析输出中的数据（示例）
            try:
                b = int(output_str[4:14], 16)
                xor = target_bytes ^ b
                pos = to_pos(f'{xor:0>40b}')
                flip_str += f'{addr}{pos},'
                # print(inputAddr, flip_str)
            except ValueError as ve:
                print(f"Error parsing output: {ve}")

        except subprocess.CalledProcessError as e:
            print(f"Error executing command: {e}")
        except Exception as e:
            print(f"An error occurred: {e}")
        
    print(f"{inputAddr}{flip_str}")
    
gen_flip()