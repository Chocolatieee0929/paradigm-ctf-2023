// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Challenge {
    address public immutable TARGET = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // 1

    uint256 public immutable STARTING_BALANCE;

    constructor() {
        STARTING_BALANCE = address(TARGET).balance;
    }

    function isSolved() external view returns (bool) {
        return TARGET.balance > STARTING_BALANCE + 13.37 ether;
    }
}
