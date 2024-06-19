// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-ctf/CTFDeployment.sol";
import "../src/Challenge.sol";
import "../src/AccountManager.sol";
import "forge-std/console.sol";
import {Account as Acct} from "../src/Account.sol";

contract Solve is BaseTest {

    function setUp() public override {
        super.setUp();

        vm.startBroadcast(system);

        SystemConfiguration configuration = new SystemConfiguration();
        AccountManager manager = new AccountManager(configuration);

        configuration.updateAccountManager(address(manager));
        configuration.updateStablecoin(address(new Stablecoin(configuration)));
        configuration.updateAccountImplementation(address(new Acct()));
        configuration.updateEthUsdPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        configuration.updateSystemContract(address(manager), true);

        challenge = address(new Challenge(configuration));

        vm.stopBroadcast();
    }

    function testExp(address challenge_, address) internal {
        

        assert(validation());
    }

    function validation() internal view returns (bool) {
        return Challenge(challenge).isSolved();
    }
}
