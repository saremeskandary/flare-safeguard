// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title ISafeguardMessageReceiver
 * @dev Interface for the Safeguard Message Receiver component
 *
 * This interface defines the standard methods for interacting with the Safeguard Message Receiver,
 * which handles cross-chain messages for the BSD Insurance Protocol.
 */
interface ISafeguardMessageReceiver {
    /**
     * @dev Enum defining the types of messages that can be received
     */
    enum MessageType {
        PolicyCreation,
        ClaimSubmission,
        ClaimVerification,
        ClaimPayment
    }

    /**
     * @dev Structure to store information about a received message
     * @param messageType The type of message
     * @param sender The address that sent the message
     * @param targetChain The ID of the chain where the message originated
     * @param data The encoded message data
     * @param timestamp The time when the message was received
     */
    struct Message {
        MessageType messageType;
        address sender;
        uint256 targetChain;
        bytes data;
        uint256 timestamp;
    }

    /**
     * @dev Event emitted when a new message is received
     * @param messageId The unique identifier for the message
     * @param messageType The type of message
     * @param sender The address that sent the message
     * @param targetChain The ID of the chain where the message originated
     */
    event MessageReceived(
        uint256 indexed messageId,
        MessageType messageType,
        address indexed sender,
        uint256 targetChain
    );

    /**
     * @dev Event emitted when a message is processed
     * @param messageId The unique identifier for the message
     * @param success Whether the message was processed successfully
     */
    event MessageProcessed(uint256 indexed messageId, bool success);

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
    ) external returns (uint256 messageId);

    /**
     * @dev Process a received message
     * @param messageId The ID of the message to process
     * @return success Whether the message was processed successfully
     */
    function processMessage(uint256 messageId) external returns (bool success);

    /**
     * @dev Get details of a specific message
     * @param messageId The ID of the message to retrieve
     * @return message The message details
     */
    function getMessage(
        uint256 messageId
    ) external view returns (Message memory message);

    /**
     * @dev Get all messages of a specific type
     * @param messageType The type of messages to retrieve
     * @return messages Array of messages of the specified type
     */
    function getMessagesByType(
        MessageType messageType
    ) external view returns (Message[] memory messages);

    /**
     * @dev Get all messages from a specific sender
     * @param sender The address to filter by
     * @return messages Array of messages from the specified sender
     */
    function getMessagesBySender(
        address sender
    ) external view returns (Message[] memory messages);

    /**
     * @dev Get all messages from a specific chain
     * @param chainId The chain ID to filter by
     * @return messages Array of messages from the specified chain
     */
    function getMessagesByChain(
        uint256 chainId
    ) external view returns (Message[] memory messages);
}
