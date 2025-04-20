// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./flare/interfaces/IStateConnector.sol";

/// @title SafeguardMessageReceiver
/// @notice Receive cross-chain messages using Flare's State Connector Protocol
abstract contract SafeguardMessageReceiver {
    IStateConnector public stateConnector;
    address public stateConnectorAddress;

    event MessageReceived(
        bytes32 indexed messageId,
        address sender,
        address token,
        uint256 tokenAmount,
        bytes data
    );

    event MessageVerificationFailed(
        bytes32 indexed messageId,
        address sender,
        address token,
        uint256 tokenAmount,
        bytes data
    );

    constructor(address _stateConnectorAddress) {
        require(
            _stateConnectorAddress != address(0),
            "SafeguardMessageReceiver: _stateConnectorAddress cannot be zero"
        );
        stateConnectorAddress = _stateConnectorAddress;
        stateConnector = IStateConnector(stateConnectorAddress);
    }

    /// @dev Receive and process a cross-chain message
    /// @param _messageId The ID of the message to receive
    /// @param _proof The proof for verifying the message
    function receiveMessage(
        bytes32 _messageId,
        IStateConnector.StateConnectorProof calldata _proof
    ) external {
        // Verify the message using the State Connector
        bool isValid = stateConnector.verifyMessage(_messageId, _proof);

        // Get the message details
        IStateConnector.CrossChainMessage memory message = stateConnector
            .getMessage(_messageId);

        if (!isValid) {
            emit MessageVerificationFailed(
                _messageId,
                message.sender,
                message.receiver,
                message.amount,
                message.data
            );
            revert("Message verification failed");
        }

        // Process the message
        (bool success, ) = address(this).call(message.data);

        if (success) {
            emit MessageReceived(
                _messageId,
                message.sender,
                message.receiver,
                message.amount,
                message.data
            );
        } else {
            emit MessageVerificationFailed(
                _messageId,
                message.sender,
                message.receiver,
                message.amount,
                message.data
            );
            revert("Message processing failed");
        }
    }
}
