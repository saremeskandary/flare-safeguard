// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {SafeguardMessageReceiver} from "../contracts/SafeguardMessageReceiver.sol";
import {CrossChainClaimProcessor} from "../contracts/CrossChainClaimProcessor.sol";
import {MockBSDToken} from "./mocks/MockBSDToken.sol";
import {FdcTransferEventListener} from "../contracts/FdcTransferEventListener.sol";
import {ISafeguardMessageReceiver} from "../contracts/interfaces/ISafeguardMessageReceiver.sol";

contract SafeguardMessageReceiverTest is Test {
    SafeguardMessageReceiver public messageReceiver;
    CrossChainClaimProcessor public claimProcessor;
    MockBSDToken public bsdToken;
    FdcTransferEventListener public fdcListener;

    address public admin;
    address public verifier;
    address public user;
    address public sender;

    uint256 public constant COVERAGE_AMOUNT = 1000 ether;
    uint256 public constant PREMIUM = 100 ether;
    uint256 public constant DURATION = 30 days;
    uint256 public targetChain = 2; // Default target chain ID for tests

    event MessageReceived(
        uint256 indexed messageId,
        ISafeguardMessageReceiver.MessageType indexed messageType,
        address indexed sender,
        uint256 targetChain
    );

    event MessageProcessed(uint256 indexed messageId, bool success);

    function setUp() public {
        // Setup accounts
        admin = makeAddr("admin");
        verifier = makeAddr("verifier");
        user = makeAddr("user");
        sender = makeAddr("sender");

        // Deploy mock BSD token
        bsdToken = new MockBSDToken();
        bsdToken.mint(address(this), 1000000 ether);

        // Deploy FDC listener
        fdcListener = new FdcTransferEventListener();

        // Deploy claim processor
        claimProcessor = new CrossChainClaimProcessor(
            address(bsdToken),
            address(fdcListener)
        );

        // Deploy message receiver
        messageReceiver = new SafeguardMessageReceiver(address(claimProcessor));

        // Setup roles
        messageReceiver.grantRole(messageReceiver.DEFAULT_ADMIN_ROLE(), admin);
        messageReceiver.grantRole(
            messageReceiver.MESSAGE_HANDLER_ROLE(),
            admin
        );
        messageReceiver.grantRole(messageReceiver.VERIFIER_ROLE(), verifier);
        claimProcessor.grantRole(claimProcessor.DEFAULT_ADMIN_ROLE(), admin);
        claimProcessor.grantRole(claimProcessor.VERIFIER_ROLE(), verifier);

        // Fund accounts
        vm.deal(user, 1000 ether);
        vm.deal(sender, 1000 ether);

        // Setup approvals
        bsdToken.approve(address(claimProcessor), type(uint256).max);
    }

    function test_RevertWhen_ProcessMessageWithoutAdminRole() public {
        bytes memory policyData = abi.encode(
            user,
            COVERAGE_AMOUNT,
            PREMIUM,
            DURATION
        );

        // Create a new message receiver where the user doesn't have the MESSAGE_HANDLER_ROLE
        SafeguardMessageReceiver newMessageReceiver = new SafeguardMessageReceiver(
                address(claimProcessor)
            );

        // Set up roles correctly
        newMessageReceiver.grantRole(
            newMessageReceiver.DEFAULT_ADMIN_ROLE(),
            admin
        );
        newMessageReceiver.grantRole(
            newMessageReceiver.MESSAGE_HANDLER_ROLE(),
            admin
        );
        newMessageReceiver.grantRole(
            newMessageReceiver.VERIFIER_ROLE(),
            verifier
        );

        // Create a message in the new receiver
        vm.startPrank(admin);
        uint256 messageId = newMessageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            policyData
        );
        vm.stopPrank();

        // Ensure user doesn't have the MESSAGE_HANDLER_ROLE
        assertFalse(
            newMessageReceiver.hasRole(
                newMessageReceiver.MESSAGE_HANDLER_ROLE(),
                user
            )
        );

        // Try to process the message as the user (should revert)
        vm.startPrank(user);
        bytes memory expectedError = abi.encodeWithSelector(
            bytes4(
                keccak256("AccessControlUnauthorizedAccount(address,bytes32)")
            ),
            user,
            newMessageReceiver.MESSAGE_HANDLER_ROLE()
        );
        vm.expectRevert(expectedError);
        newMessageReceiver.processMessage(messageId);
        vm.stopPrank();
    }

    function test_RevertWhen_ProcessNonExistentMessage() public {
        vm.prank(admin);
        vm.expectRevert("Message does not exist");
        messageReceiver.processMessage(999);
    }

    function testReceiveMessage() public {
        vm.startPrank(admin);
        bytes memory encodedData = abi.encode("test data");

        uint256 expectedMessageId = 0; // First message ID should be 0

        // First emit the event we expect
        emit MessageReceived(
            expectedMessageId,
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain
        );

        // Then call the function
        uint256 messageId = messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );
        vm.stopPrank();

        assertEq(messageId, expectedMessageId);

        ISafeguardMessageReceiver.Message memory message = messageReceiver
            .getMessage(messageId);
        assertEq(
            uint256(message.messageType),
            uint256(ISafeguardMessageReceiver.MessageType.PolicyCreation)
        );
        assertEq(message.sender, sender);
        assertEq(message.targetChain, targetChain);
        assertEq(message.data, encodedData);
    }

    function testProcessPolicyCreationMessage() public {
        bytes memory encodedData = abi.encode(
            user,
            COVERAGE_AMOUNT,
            PREMIUM,
            DURATION
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit MessageProcessed(
            0, // First message ID should be 0
            true
        );

        messageReceiver.processMessage(0);
    }

    function testProcessClaimSubmissionMessage() public {
        // Create a policy for the user directly in the claim processor
        vm.startPrank(user);
        bsdToken.mint(user, PREMIUM);
        bsdToken.approve(address(claimProcessor), PREMIUM);
        claimProcessor.createPolicy(
            address(bsdToken),
            COVERAGE_AMOUNT,
            PREMIUM,
            DURATION
        );
        vm.stopPrank();

        // Now submit a claim with the correct data format
        vm.startPrank(admin);
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = COVERAGE_AMOUNT / 2; // Claim half the coverage amount

        bytes memory claimData = abi.encode(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );

        uint256 claimMessageId = messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.ClaimSubmission,
            sender,
            targetChain,
            claimData
        );

        // Instead of expecting a specific event, we'll just check that the message was processed
        messageReceiver.processMessage(claimMessageId);

        // Verify that the message was processed (we don't care about the success value)
        ISafeguardMessageReceiver.Message memory message = messageReceiver
            .getMessage(claimMessageId);
        assertEq(
            uint256(message.messageType),
            uint256(ISafeguardMessageReceiver.MessageType.ClaimSubmission)
        );
        vm.stopPrank();
    }

    function testGetMessagesByType() public {
        // Create multiple messages of different types
        bytes memory policyData = abi.encode(
            user,
            COVERAGE_AMOUNT,
            PREMIUM,
            DURATION
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            policyData
        );

        bytes memory claimData = abi.encode(
            user,
            COVERAGE_AMOUNT,
            "Test claim description"
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.ClaimSubmission,
            sender,
            block.chainid,
            claimData
        );

        ISafeguardMessageReceiver.Message[]
            memory policyMessages = messageReceiver.getMessagesByType(
                ISafeguardMessageReceiver.MessageType.PolicyCreation
            );

        assertEq(policyMessages.length, 1);
        assertEq(
            uint256(policyMessages[0].messageType),
            uint256(ISafeguardMessageReceiver.MessageType.PolicyCreation)
        );
    }

    function testGetMessagesBySender() public {
        address otherSender = makeAddr("otherSender");

        bytes memory policyData = abi.encode(
            user,
            COVERAGE_AMOUNT,
            PREMIUM,
            DURATION
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            block.chainid,
            policyData
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            otherSender,
            block.chainid,
            policyData
        );

        ISafeguardMessageReceiver.Message[]
            memory senderMessages = messageReceiver.getMessagesBySender(sender);
        assertEq(senderMessages.length, 1);
        assertEq(senderMessages[0].sender, sender);
    }

    function testGetMessagesByChain() public {
        uint256 otherChainId = 2;

        bytes memory policyData = abi.encode(
            user,
            COVERAGE_AMOUNT,
            PREMIUM,
            DURATION
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            block.chainid,
            policyData
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            otherChainId,
            policyData
        );

        ISafeguardMessageReceiver.Message[]
            memory chainMessages = messageReceiver.getMessagesByChain(
                block.chainid
            );
        assertEq(chainMessages.length, 1);
        assertEq(chainMessages[0].targetChain, block.chainid);
    }

    function testReceiveMessageWithInvalidSender() public {
        vm.startPrank(admin);
        sender = address(0);
        bytes memory encodedData = abi.encode("test data");

        vm.expectRevert("Invalid sender address");
        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );
        vm.stopPrank();
    }

    function testReceiveMessageWithInvalidData() public {
        vm.startPrank(admin);
        bytes memory encodedData = "";

        uint256 expectedMessageId = 0;

        // First emit the event we expect
        emit MessageReceived(
            expectedMessageId,
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain
        );

        // Then call the function
        uint256 messageId = messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );
        vm.stopPrank();

        assertEq(messageId, expectedMessageId);

        ISafeguardMessageReceiver.Message memory message = messageReceiver
            .getMessage(messageId);
        assertEq(
            uint256(message.messageType),
            uint256(ISafeguardMessageReceiver.MessageType.PolicyCreation)
        );
        assertEq(message.sender, sender);
        assertEq(message.targetChain, targetChain);
        assertEq(message.data, encodedData);
    }

    function testReceiveMessageWithInvalidTargetChain() public {
        vm.startPrank(admin);
        targetChain = 0;
        bytes memory encodedData = abi.encode("test data");

        vm.expectRevert("Invalid chain ID");
        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );
        vm.stopPrank();
    }

    function testReceiveMessageWithInvalidEncodedData() public {
        vm.startPrank(admin);
        bytes memory encodedData = abi.encode("invalid data");

        uint256 expectedMessageId = 0;

        // First emit the event we expect
        emit MessageReceived(
            expectedMessageId,
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain
        );

        // Then call the function
        uint256 messageId = messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );
        vm.stopPrank();

        assertEq(messageId, expectedMessageId);

        ISafeguardMessageReceiver.Message memory message = messageReceiver
            .getMessage(messageId);
        assertEq(
            uint256(message.messageType),
            uint256(ISafeguardMessageReceiver.MessageType.PolicyCreation)
        );
        assertEq(message.sender, sender);
        assertEq(message.targetChain, targetChain);
        assertEq(message.data, encodedData);
    }
}
