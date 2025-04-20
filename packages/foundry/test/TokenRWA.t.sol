// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/flare/TokenRWA.sol";
import "../contracts/flare/DataVerification.sol";
import {IEVMTransaction} from "dependencies/flare-periphery-0.0.22/src/coston2/IEVMTransaction.sol";

contract TokenRWATest is Test {
    TokenRWA public token;
    DataVerification public dataVerification;
    address public owner;
    address public user1;
    address public user2;

    // Mock function for verification
    function verify(bytes32, bytes memory) external pure returns (bool) {
        return true;
    }

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);
        // Deploy DataVerification contract
        dataVerification = new DataVerification();

        // Set up verification
        dataVerification.setVerificationAddress(address(this));

        // Deploy TokenRWA contract
        token = new TokenRWA(
            "Real World Asset",
            "RWA",
            address(dataVerification)
        );

        // Enable transfers
        token.enableTransfers();
        vm.stopPrank();
    }

    function test_Constructor() public {
        assertEq(token.name(), "Real World Asset");
        assertEq(token.symbol(), "RWA");
        assertEq(address(token.dataVerification()), address(dataVerification));
        assertEq(token.owner(), owner);
    }

    function test_GlobalTransferControl() public {
        // Create proof structure
        IEVMTransaction.RequestBody memory requestBody = IEVMTransaction
            .RequestBody({
                transactionHash: bytes32(0),
                requiredConfirmations: 0,
                provideInput: false,
                listEvents: false,
                logIndices: new uint32[](0)
            });

        IEVMTransaction.ResponseBody memory responseBody = IEVMTransaction
            .ResponseBody({
                blockNumber: 0,
                timestamp: 0,
                sourceAddress: address(0),
                isDeployment: false,
                receivingAddress: address(0),
                value: 0,
                input: hex"",
                status: 1,
                events: new IEVMTransaction.Event[](0)
            });

        IEVMTransaction.Response memory response = IEVMTransaction.Response({
            attestationType: bytes32(0),
            sourceId: bytes32(0),
            votingRound: 0,
            lowestUsedTimestamp: 0,
            requestBody: requestBody,
            responseBody: responseBody
        });

        IEVMTransaction.Proof memory proof = IEVMTransaction.Proof({
            merkleProof: new bytes32[](0),
            data: response
        });

        bytes memory encodedProof = abi.encode(proof);

        // Verify both users first
        bytes32 requestId1 = bytes32("test_request_id1");
        bytes32 requestId2 = bytes32("test_request_id2");

        vm.startPrank(user1);
        token.verifyHolder(requestId1, encodedProof);
        vm.stopPrank();

        vm.startPrank(user2);
        token.verifyHolder(requestId2, encodedProof);
        vm.stopPrank();

        // Now proceed with minting and transfers
        vm.startPrank(owner);
        token.mint(user1, 100 ether);

        vm.startPrank(user1);
        token.transfer(user2, 50 ether);
        assertEq(token.balanceOf(user2), 50 ether);

        vm.startPrank(owner);
        token.disableTransfers();

        vm.startPrank(user1);
        vm.expectRevert("Transfers are disabled");
        token.transfer(user2, 50 ether);
    }

    function test_Mint() public {
        // Create proof structure
        IEVMTransaction.RequestBody memory requestBody = IEVMTransaction
            .RequestBody({
                transactionHash: bytes32(0),
                requiredConfirmations: 0,
                provideInput: false,
                listEvents: false,
                logIndices: new uint32[](0)
            });

        IEVMTransaction.ResponseBody memory responseBody = IEVMTransaction
            .ResponseBody({
                blockNumber: 0,
                timestamp: 0,
                sourceAddress: address(0),
                isDeployment: false,
                receivingAddress: address(0),
                value: 0,
                input: hex"",
                status: 1,
                events: new IEVMTransaction.Event[](0)
            });

        IEVMTransaction.Response memory response = IEVMTransaction.Response({
            attestationType: bytes32(0),
            sourceId: bytes32(0),
            votingRound: 0,
            lowestUsedTimestamp: 0,
            requestBody: requestBody,
            responseBody: responseBody
        });

        IEVMTransaction.Proof memory proof = IEVMTransaction.Proof({
            merkleProof: new bytes32[](0),
            data: response
        });

        bytes memory encodedProof = abi.encode(proof);

        // Verify recipient before minting
        bytes32 requestId = bytes32("test_request_id");

        vm.startPrank(user1);
        token.verifyHolder(requestId, encodedProof);
        vm.stopPrank();

        vm.startPrank(owner);
        token.mint(user1, 100 ether);
        assertEq(token.balanceOf(user1), 100 ether);
    }

    function test_PauseUnpause() public {
        vm.startPrank(owner);
        token.pause();
        assertTrue(token.paused());

        token.unpause();
        assertFalse(token.paused());
    }

    function test_RevertWhenNonOwnerMints() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                user1
            )
        );
        token.mint(user2, 100 ether);
    }

    function test_RevertWhenNonOwnerPauses() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                user1
            )
        );
        token.pause();
    }

    function test_RevertWhenNonOwnerSetsTransferLimit() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                user1
            )
        );
        token.setTransferLimit(user2, 100 ether);
    }

    function test_SetTransferLimit() public {
        vm.startPrank(owner);
        token.setTransferLimit(user1, 100 ether);
        assertEq(token.transferLimits(user1), 100 ether);
    }

    function test_TransferRestrictions() public {
        // Create proof structure
        IEVMTransaction.RequestBody memory requestBody = IEVMTransaction
            .RequestBody({
                transactionHash: bytes32(0),
                requiredConfirmations: 0,
                provideInput: false,
                listEvents: false,
                logIndices: new uint32[](0)
            });

        IEVMTransaction.ResponseBody memory responseBody = IEVMTransaction
            .ResponseBody({
                blockNumber: 0,
                timestamp: 0,
                sourceAddress: address(0),
                isDeployment: false,
                receivingAddress: address(0),
                value: 0,
                input: hex"",
                status: 1,
                events: new IEVMTransaction.Event[](0)
            });

        IEVMTransaction.Response memory response = IEVMTransaction.Response({
            attestationType: bytes32(0),
            sourceId: bytes32(0),
            votingRound: 0,
            lowestUsedTimestamp: 0,
            requestBody: requestBody,
            responseBody: responseBody
        });

        IEVMTransaction.Proof memory proof = IEVMTransaction.Proof({
            merkleProof: new bytes32[](0),
            data: response
        });

        bytes memory encodedProof = abi.encode(proof);

        // Verify both users first
        bytes32 requestId1 = bytes32("test_request_id1");
        bytes32 requestId2 = bytes32("test_request_id2");

        vm.startPrank(user1);
        token.verifyHolder(requestId1, encodedProof);
        vm.stopPrank();

        vm.startPrank(user2);
        token.verifyHolder(requestId2, encodedProof);
        vm.stopPrank();

        // Now proceed with minting and transfers
        vm.startPrank(owner);
        token.mint(user1, 100 ether);
        token.setTransferLimit(user1, 50 ether);

        vm.startPrank(user1);
        // Try to transfer more than limit
        vm.expectRevert("Transfer limit exceeded");
        token.transfer(user2, 51 ether);

        // Transfer within limit should work
        token.transfer(user2, 50 ether);
        assertEq(token.balanceOf(user2), 50 ether);
    }

    function test_VerifyHolder() public {
        vm.startPrank(owner);
        // Set up DataVerification
        dataVerification.setVerificationAddress(address(this));

        vm.startPrank(user1);
        bytes32 requestId = bytes32("test_request_id");

        // Create a properly structured proof
        IEVMTransaction.RequestBody memory requestBody = IEVMTransaction
            .RequestBody({
                transactionHash: bytes32(0),
                requiredConfirmations: 0,
                provideInput: false,
                listEvents: false,
                logIndices: new uint32[](0)
            });

        IEVMTransaction.ResponseBody memory responseBody = IEVMTransaction
            .ResponseBody({
                blockNumber: 0,
                timestamp: 0,
                sourceAddress: address(0),
                isDeployment: false,
                receivingAddress: address(0),
                value: 0,
                input: hex"",
                status: 1,
                events: new IEVMTransaction.Event[](0)
            });

        IEVMTransaction.Response memory response = IEVMTransaction.Response({
            attestationType: bytes32(0),
            sourceId: bytes32(0),
            votingRound: 0,
            lowestUsedTimestamp: 0,
            requestBody: requestBody,
            responseBody: responseBody
        });

        IEVMTransaction.Proof memory proof = IEVMTransaction.Proof({
            merkleProof: new bytes32[](0),
            data: response
        });

        bytes memory encodedProof = abi.encode(proof);
        token.verifyHolder(requestId, encodedProof);

        assertTrue(token.verifiedHolders(user1));
    }
}
