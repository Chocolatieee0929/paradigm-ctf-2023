// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-ctf/CTFDeployment.sol";
import "forge-std/console2.sol";

import "src/Challenge.sol";
import "src/InuToken.sol";
import "@uniswap/merkle-distributor/contracts/MerkleDistributor.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniswapV2Router02 {
    function factory() external returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

     function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
}


contract Deploy is BaseTest {
    InuToken public token;
    MerkleDistributor public distributor;
    Challenge public CHALLENGE;

    IUniswapV2Router02 routerV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function setUp() public override {
        super.setUp();
        bytes32 merkleRoot = vm.envBytes32("MERKLE_ROOT");
        uint256 tokenTotal = vm.envUint("TOKEN_TOTAL");

        vm.startBroadcast(system);

        token = new InuToken(tokenTotal + 100);
        distributor = new MerkleDistributor(address(token), merkleRoot);
        token.transfer(address(distributor), tokenTotal);

        token.approve(address(routerV2), type(uint256).max);
        routerV2.addLiquidityETH{value: 100_000}(address(token), 100, 100, 100_000, system, block.timestamp + 1 days);

        CHALLENGE = new Challenge(distributor);
        challenge = address(CHALLENGE);

        vm.label(address(token), "InuToken");
        vm.label(address(distributor), "MerkleDistributor");
        vm.label(challenge, "Challenge");
        vm.label(address(routerV2), "UniswapV2Router02");

        vm.stopBroadcast();
    }
}

