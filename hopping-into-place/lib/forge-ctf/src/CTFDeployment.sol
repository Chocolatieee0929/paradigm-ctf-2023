// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;

import {Test} from "forge-std/Test.sol";

abstract contract BaseTest is Test {
    address internal challenge;

    address player = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f; // 8
    address system = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720; // 9

    function setUp() public virtual {
        uint256 forkId = vm.createFork(vm.envString("MAINNET_RPC"));
        vm.selectFork(forkId);

        vm.deal(player, 10000 ether);
        vm.deal(system, 10000 ether);

        vm.label(player, "player");
        vm.label(system, "system");
        
    }
    
    function getAdditionalAddress(uint32 index) internal returns (address) {
        return getAddress(index + 2);
    }

    function getPrivateKey(uint32 index) private returns (uint) {
        string memory mnemonic = vm.envOr("MNEMONIC", string("test test test test test test test test test test test junk"));
        return vm.deriveKey(mnemonic, index);
    }

    function getAddress(uint32 index) private returns (address) {
        return vm.addr(getPrivateKey(index));
    }
}