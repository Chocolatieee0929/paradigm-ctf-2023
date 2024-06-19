// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SystemConfiguration.sol";

contract Stablecoin is ERC20("US Dollar Stablecoin", "USDS") {
    SystemConfiguration private immutable SYSTEM_CONFIGURATION;

    constructor(SystemConfiguration configuration) {
        SYSTEM_CONFIGURATION = configuration;
    }

    function mint(address to, uint256 amount) external {
        require(SYSTEM_CONFIGURATION.isAuthorized(msg.sender), "NOT_AUTHORIZED"); // 只有管理员授权的地址能mint

        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(SYSTEM_CONFIGURATION.isAuthorized(msg.sender), "NOT_AUTHORIZED"); // 只有管理员授权的地址能burn

        _burn(from, amount);
    }
}
