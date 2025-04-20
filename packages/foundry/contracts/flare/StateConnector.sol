// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IStateConnector.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StateConnector is IStateConnector, Ownable, ReentrancyGuard {
    mapping(bytes32 => CrossChainMessage) private messages;
    mapping(bytes32 => bool) private verifiedMessages;

    uint256 public constant VERIFICATION_DELAY = 100; // Number of blocks required for verification
    uint256 public constant MINIMUM_FEE = 0.01 ether; // Minimum fee for sending messages

    error InvalidProof();
    error MessageNotFound();
    error InsufficientFee();
    error MessageAlreadyVerified();

    constructor() Ownable(msg.sender) {}

    function sendMessage(
        address _receiver,
        uint256 _amount,
        bytes calldata _data
    ) external payable override nonReentrant returns (bytes32 messageId) {
        if (msg.value < MINIMUM_FEE) revert InsufficientFee();

        messageId = keccak256(
            abi.encodePacked(
                msg.sender,
                _receiver,
                _amount,
                _data,
                block.timestamp
            )
        );

        messages[messageId] = CrossChainMessage({
            sender: msg.sender,
            receiver: _receiver,
            amount: _amount,
            data: _data,
            timestamp: block.timestamp
        });

        emit MessageSent(messageId, msg.sender, _receiver, _amount, _data);

        // Transfer any excess fee back to the sender
        if (msg.value > MINIMUM_FEE) {
            payable(msg.sender).transfer(msg.value - MINIMUM_FEE);
        }
    }

    function verifyMessage(
        bytes32 _messageId,
        StateConnectorProof calldata _proof
    ) external view override returns (bool) {
        CrossChainMessage memory message = messages[_messageId];
        if (message.timestamp == 0) revert MessageNotFound();

        // Verify the proof using the State Connector's verification mechanism
        // This is a simplified version - in production, you would use the actual State Connector verification
        bytes32 computedRoot = keccak256(
            abi.encodePacked(
                message.sender,
                message.receiver,
                message.amount,
                message.data,
                message.timestamp
            )
        );

        // Verify merkle proof
        bytes32 currentHash = computedRoot;
        for (uint256 i = 0; i < _proof.merkleProof.length; i++) {
            currentHash = keccak256(
                abi.encodePacked(
                    currentHash < _proof.merkleProof[i]
                        ? currentHash
                        : _proof.merkleProof[i],
                    currentHash < _proof.merkleProof[i]
                        ? _proof.merkleProof[i]
                        : currentHash
                )
            );
        }

        if (currentHash != _proof.merkleRoot) revert InvalidProof();

        // Verify block number and hash
        if (block.number - _proof.blockNumber < VERIFICATION_DELAY)
            revert InvalidProof();
        if (_proof.blockHash != blockhash(_proof.blockNumber))
            revert InvalidProof();

        return true;
    }

    function getMessage(
        bytes32 _messageId
    ) external view override returns (CrossChainMessage memory) {
        CrossChainMessage memory message = messages[_messageId];
        if (message.timestamp == 0) revert MessageNotFound();
        return message;
    }

    // Function to withdraw accumulated fees
    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
