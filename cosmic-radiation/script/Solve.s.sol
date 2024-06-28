// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "forge-std/console.sol";
import "../src/Challenge.sol";
import "./Deploy.sol";

contract Solve is Deploy {
    function testSolve() public {

        console2.log(Challenge(challenge).getScore());
    }
    
    
}

/* 
    balance = web3.eth.get_balance(addr)
    if balance == 0: # 自毁合约
        raise Exception("invalid target")

    code = bytearray(web3.eth.get_code(addr))
    for bit in bits:
        byte_offset = bit // 8
        bit_offset = 7 - bit % 8
        if byte_offset < len(code):
            code[byte_offset] ^= 1 << bit_offset

    total_bits = len(code) * 8
    corrupted_balance = int(balance * (total_bits - len(bits)) / total_bits) # 考虑溢出

    anvil_setBalance(web3, addr, hex(corrupted_balance))
    anvil_setCode(web3, addr, "0x" + code.hex())
 */
