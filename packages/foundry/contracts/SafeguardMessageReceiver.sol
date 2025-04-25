// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ISafeguardMessageReceiver.sol";
import "./CrossChainClaimProcessor.sol";

/**
 * @title Safeguard Message Receiver
 * @dev Handles cross-chain messages for the BSD Insurance Protocol
 *
 * This contract:
 * - Receives and processes cross-chain messages for insurance operations
 * - Routes messages to appropriate handlers based on message type
 * - Maintains a record of all received messages
 * - Integrates with CrossChainClaimProcessor for claim-related messages
 *
 * The Safeguard Message Receiver is a critical component for cross-chain insurance as it:
 * - Enables communication between different chains in the insurance protocol
 * - Facilitates cross-chain policy creation and claim processing
 * - Provides a standardized interface for handling cross-chain messages
 * - Supports the BSD Insurance Protocol's cross-chain capabilities
 */
contract SafeguardMessageReceiver is ISafeguardMessageReceiver, AccessControl {
    // Custom errors
    error InvalidClaimProcessorAddress();
    error InvalidSenderAddress();
    error InvalidChainId();
    error MessageDoesNotExist();
    error UnknownMessageType();

    bytes32 public constant MESSAGE_HANDLER_ROLE =
        keccak256("MESSAGE_HANDLER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    // Mapping from message ID to Message
    mapping(uint256 => Message) private _messages;

    // Array to store all message IDs
    uint256[] private _messageIds;

    // Mapping from message type to array of message IDs
    mapping(MessageType => uint256[]) private _messagesByType;

    // Mapping from sender to array of message IDs
    mapping(address => uint256[]) private _messagesBySender;

    // Mapping from chain ID to array of message IDs
    mapping(uint256 => uint256[]) private _messagesByChain;

    // Counter for generating unique message IDs
    uint256 private _messageCount;

    // Reference to the CrossChainClaimProcessor
    CrossChainClaimProcessor public claimProcessor;

    /**
     * @dev Constructor initializes the contract with required dependencies
     * @param _claimProcessor Address of the CrossChainClaimProcessor contract
     */
    constructor(address _claimProcessor) {
        if (_claimProcessor == address(0))
            revert InvalidClaimProcessorAddress();
        claimProcessor = CrossChainClaimProcessor(_claimProcessor);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MESSAGE_HANDLER_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
    }

    /**
     * @dev Receive a cross-chain message
     * @param messageType The type of message
     * @param sender The address that sent the message
     * @param targetChain The ID of the chain where the message originated
     * @param data The encoded message data
     * @return messageId The unique identifier for the message
     */
    function receiveMessage(
        MessageType messageType,
        address sender,
        uint256 targetChain,
        bytes calldata data
    )
        external
        override
        onlyRole(MESSAGE_HANDLER_ROLE)
        returns (uint256 messageId)
    {
        if (sender == address(0)) revert InvalidSenderAddress();
        if (targetChain == 0) revert InvalidChainId();

        messageId = _messageCount++;

        Message memory newMessage = Message({
            messageType: messageType,
            sender: sender,
            targetChain: targetChain,
            data: data,
            timestamp: block.timestamp
        });

        _messages[messageId] = newMessage;
        _messageIds.push(messageId);
        _messagesByType[messageType].push(messageId);
        _messagesBySender[sender].push(messageId);
        _messagesByChain[targetChain].push(messageId);

        emit MessageReceived(messageId, messageType, sender, targetChain);

        return messageId;
    }

    /**
     * @dev Process a received message
     * @param messageId The ID of the message to process
     * @return success Whether the message was processed successfully
     */
    function processMessage(
        uint256 messageId
    ) external override onlyRole(MESSAGE_HANDLER_ROLE) returns (bool success) {
        if (_messages[messageId].sender == address(0))
            revert MessageDoesNotExist();

        Message memory message = _messages[messageId];

        if (message.messageType == MessageType.PolicyCreation) {
            success = _handlePolicyCreation(message);
        } else if (message.messageType == MessageType.ClaimSubmission) {
            success = _handleClaimSubmission(message);
        } else if (message.messageType == MessageType.ClaimVerification) {
            success = _handleClaimVerification(message);
        } else if (message.messageType == MessageType.ClaimPayment) {
            success = _handleClaimPayment(message);
        } else {
            revert UnknownMessageType();
        }

        emit MessageProcessed(messageId, success);

        return success;
    }

    /**
     * @dev Get details of a specific message
     * @param messageId The ID of the message to retrieve
     * @return message The message details
     */
    function getMessage(
        uint256 messageId
    ) external view override returns (Message memory message) {
        if (_messages[messageId].sender == address(0))
            revert MessageDoesNotExist();
        return _messages[messageId];
    }

    /**
     * @dev Get all messages of a specific type
     * @param messageType The type of messages to retrieve
     * @return messages Array of messages of the specified type
     */
    function getMessagesByType(
        MessageType messageType
    ) external view override returns (Message[] memory messages) {
        uint256[] memory messageIds = _messagesByType[messageType];
        messages = new Message[](messageIds.length);

        for (uint256 i = 0; i < messageIds.length; i++) {
            messages[i] = _messages[messageIds[i]];
        }

        return messages;
    }

    /**
     * @dev Get all messages from a specific sender
     * @param sender The address to filter by
     * @return messages Array of messages from the specified sender
     */
    function getMessagesBySender(
        address sender
    ) external view override returns (Message[] memory messages) {
        uint256[] memory messageIds = _messagesBySender[sender];
        messages = new Message[](messageIds.length);

        for (uint256 i = 0; i < messageIds.length; i++) {
            messages[i] = _messages[messageIds[i]];
        }

        return messages;
    }

    /**
     * @dev Get all messages from a specific chain
     * @param chainId The chain ID to filter by
     * @return messages Array of messages from the specified chain
     */
    function getMessagesByChain(
        uint256 chainId
    ) external view override returns (Message[] memory messages) {
        uint256[] memory messageIds = _messagesByChain[chainId];
        messages = new Message[](messageIds.length);

        for (uint256 i = 0; i < messageIds.length; i++) {
            messages[i] = _messages[messageIds[i]];
        }

        return messages;
    }

    /**
     * @dev Internal function to handle policy creation messages
     * @return success Whether the policy was created successfully
     */
    function _handlePolicyCreation(
        Message memory
    ) internal pure returns (bool success) {
        // Note: This would need to be implemented based on the specific requirements
        // For now, we'll just return true as a placeholder
        return true;
    }

    /**
     * @dev Internal function to handle claim submission messages
     * @param message The message containing claim submission data
     * @return success Whether the claim was submitted successfully
     */
    function _handleClaimSubmission(
        Message memory message
    ) internal returns (bool success) {
        // Decode claim submission data
        (
            uint256 amount,
            bytes32 transactionHash,
            uint256 chainId,
            uint16 requiredConfirmations
        ) = abi.decode(message.data, (uint256, bytes32, uint256, uint16));

        // Submit claim on this chain
        try
            claimProcessor.submitCrossChainClaim(
                amount,
                transactionHash,
                chainId,
                requiredConfirmations
            )
        returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @dev Internal function to handle claim verification messages
     * @return success Whether the claim was verified successfully
     */
    function _handleClaimVerification(
        Message memory
    ) internal pure returns (bool success) {
        // Note: This would need to be implemented based on the specific requirements
        // For now, we'll just return true as a placeholder
        return true;
    }

    /**
     * @dev Internal function to handle claim payment messages
     * @param message The message containing claim payment data
     * @return success Whether the claim was paid successfully
     */
    function _handleClaimPayment(
        Message memory message
    ) internal returns (bool success) {
        // Decode claim payment data
        uint256 claimId = abi.decode(message.data, (uint256));

        // Process claim payment on this chain
        try claimProcessor.processCrossChainClaim(claimId) {
            return true;
        } catch {
            return false;
        }
    }
}
