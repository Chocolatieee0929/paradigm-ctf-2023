// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-ctf/CTFDeployment.sol";

import "src/Challenge.sol";

contract Deploy is BaseTest {
    function setUp() public override{
        uint256 forkId = vm.createFork(vm.envString("LOCAL_RPC"), 18_437_825);
        vm.selectFork(forkId);

        vm.startBroadcast(system);
        challenge = address(new Challenge());
        vm.stopBroadcast();
    }

    function bitflip(address account, uint[] memory bits) public {
        bytes memory bytecode = account.code;
        for (uint i = 0; i < bits.length; i++) {
            uint bit = bits[i];
            uint byteOffset = bit / 8;
            uint bitOffset = 7 - bit % 8;

            if (byteOffset < bytecode.length) {
                // Toggle the specific bit
                bytecode[byteOffset] ^= bytes1(uint8(1 << bitOffset));
            }
        }
        uint totalBits = bytecode.length * 8;
        uint corruptedBalance = account.balance * (totalBits - bits.length) / totalBits;
        
        vm.etch(account, bytecode);
        vm.deal(account, corruptedBalance);
    }
}
