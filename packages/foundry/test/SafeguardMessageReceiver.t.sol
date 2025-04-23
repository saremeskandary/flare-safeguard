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
        uint256 targetChain,
        bytes encodedData
    );

    event MessageProcessed(
        uint256 indexed messageId,
        ISafeguardMessageReceiver.MessageType indexed messageType,
        bool success
    );

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

    function testReceiveMessage() public {
        sender = address(0x123);
        targetChain = 2; // Example target chain ID
        bytes memory encodedData = abi.encode("test data");

        vm.expectEmit(true, true, true, true);
        emit MessageReceived(
            1,
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        ISafeguardMessageReceiver.Message memory message = messageReceiver
            .getMessage(1);
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
            1,
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            true
        );

        messageReceiver.processMessage(1);
    }

    function testProcessClaimSubmissionMessage() public {
        // First create a policy
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

        vm.prank(admin);
        messageReceiver.processMessage(1);

        // Now submit a claim
        bytes memory claimData = abi.encode(
            user,
            COVERAGE_AMOUNT,
            "Test claim description"
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.ClaimSubmission,
            sender,
            targetChain,
            claimData
        );

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit MessageProcessed(
            2,
            ISafeguardMessageReceiver.MessageType.ClaimSubmission,
            true
        );

        messageReceiver.processMessage(2);
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

    function testFailProcessMessageWithoutAdminRole() public {
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

        vm.prank(user);
        vm.expectRevert("AccessControl: account 0x");
        messageReceiver.processMessage(1);
    }

    function testFailProcessNonExistentMessage() public {
        vm.prank(admin);
        vm.expectRevert("Message does not exist");
        messageReceiver.processMessage(999);
    }

    function testReceiveMessageWithInvalidSender() public {
        sender = address(0);
        targetChain = 2; // Example target chain ID
        bytes memory encodedData = abi.encode("test data");

        vm.expectEmit(true, true, true, true);
        emit MessageReceived(
            1,
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        ISafeguardMessageReceiver.Message memory message = messageReceiver
            .getMessage(1);
        assertEq(
            uint256(message.messageType),
            uint256(ISafeguardMessageReceiver.MessageType.PolicyCreation)
        );
        assertEq(message.sender, sender);
        assertEq(message.targetChain, targetChain);
        assertEq(message.data, encodedData);
    }

    function testReceiveMessageWithInvalidData() public {
        sender = address(0x123);
        targetChain = 2; // Example target chain ID
        bytes memory encodedData = "";

        vm.expectEmit(true, true, true, true);
        emit MessageReceived(
            1,
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        ISafeguardMessageReceiver.Message memory message = messageReceiver
            .getMessage(1);
        assertEq(
            uint256(message.messageType),
            uint256(ISafeguardMessageReceiver.MessageType.PolicyCreation)
        );
        assertEq(message.sender, sender);
        assertEq(message.targetChain, targetChain);
        assertEq(message.data, encodedData);
    }

    function testReceiveMessageWithInvalidTargetChain() public {
        sender = address(0x123);
        targetChain = 0; // Invalid target chain ID
        bytes memory encodedData = abi.encode("test data");

        vm.expectEmit(true, true, true, true);
        emit MessageReceived(
            1,
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        ISafeguardMessageReceiver.Message memory message = messageReceiver
            .getMessage(1);
        assertEq(
            uint256(message.messageType),
            uint256(ISafeguardMessageReceiver.MessageType.PolicyCreation)
        );
        assertEq(message.sender, sender);
        assertEq(message.targetChain, targetChain);
        assertEq(message.data, encodedData);
    }

    function testReceiveMessageWithInvalidEncodedData() public {
        sender = address(0x123);
        targetChain = 2; // Example target chain ID
        bytes memory encodedData = abi.encode("invalid data");

        vm.expectEmit(true, true, true, true);
        emit MessageReceived(
            1,
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        messageReceiver.receiveMessage(
            ISafeguardMessageReceiver.MessageType.PolicyCreation,
            sender,
            targetChain,
            encodedData
        );

        ISafeguardMessageReceiver.Message memory message = messageReceiver
            .getMessage(1);
        assertEq(
            uint256(message.messageType),
            uint256(ISafeguardMessageReceiver.MessageType.PolicyCreation)
        );
        assertEq(message.sender, sender);
        assertEq(message.targetChain, targetChain);
        assertEq(message.data, encodedData);
    }
}
