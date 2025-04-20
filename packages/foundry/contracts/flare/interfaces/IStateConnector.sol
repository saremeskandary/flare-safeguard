// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IStateConnector {
    struct StateConnectorProof {
        bytes32 merkleRoot;
        bytes32[] merkleProof;
        uint256 blockNumber;
        bytes32 blockHash;
    }

    struct CrossChainMessage {
        address sender;
        address receiver;
        uint256 amount;
        bytes data;
        uint256 timestamp;
    }

    event MessageSent(
        bytes32 indexed messageId,
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        bytes data
    );

    event MessageReceived(
        bytes32 indexed messageId,
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        bytes data
    );

    function sendMessage(
        address _receiver,
        uint256 _amount,
        bytes calldata _data
    ) external payable returns (bytes32 messageId);

    function verifyMessage(
        bytes32 _messageId,
        StateConnectorProof calldata _proof
    ) external view returns (bool);

    function getMessage(
        bytes32 _messageId
    ) external view returns (CrossChainMessage memory);
}
