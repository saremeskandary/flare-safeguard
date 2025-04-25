// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IEVMTransaction} from "flare-periphery/src/coston2/IEVMTransaction.sol";

/**
 * @title IFdcTransferEventListener
 * @dev Interface for the FDC Transfer Event Listener component
 *
 * This interface defines the standard methods for interacting with the FDC Transfer Event Listener,
 * which monitors and processes token transfer events from external chains via Flare's Data Connector.
 */
interface IFdcTransferEventListener {
    /**
     * @dev Structure to store information about a token transfer event
     * @param from The address tokens were transferred from
     * @param to The address tokens were transferred to
     * @param value The amount of tokens transferred
     * @param tokenAddress The address of the token contract
     * @param chainId The ID of the chain where the transfer occurred
     */
    struct TokenTransfer {
        address from;
        address to;
        uint256 value;
        address tokenAddress;
        uint256 chainId;
    }

    /**
     * @dev Verifies that a transaction proof is valid using Flare's Data Connector
     * @param transaction The transaction proof to verify
     * @return True if the transaction proof is valid, false otherwise
     */
    function isEVMTransactionProofValid(
        IEVMTransaction.Proof calldata transaction
    ) external view returns (bool);

    /**
     * @dev Collects and processes transfer events from a verified transaction
     * @param _transaction The verified transaction containing transfer events
     */
    function collectTransferEvents(
        IEVMTransaction.Proof calldata _transaction
    ) external;

    /**
     * @dev Retrieves all collected token transfers
     * @return An array of all TokenTransfer structures
     */
    function getTokenTransfers() external view returns (TokenTransfer[] memory);

    /**
     * @dev Retrieves token transfers for a specific token address
     * @param tokenAddress The address of the token to filter by
     * @return An array of TokenTransfer structures for the specified token
     */
    function getTokenTransfersByToken(
        address tokenAddress
    ) external view returns (TokenTransfer[] memory);

    /**
     * @dev Retrieves token transfers for a specific chain ID
     * @param chainId The ID of the chain to filter by
     * @return An array of TokenTransfer structures for the specified chain
     */
    function getTokenTransfersByChain(
        uint256 chainId
    ) external view returns (TokenTransfer[] memory);

    /**
     * @dev Retrieves token transfers for a specific address (as sender or receiver)
     * @param address_ The address to filter by
     * @return An array of TokenTransfer structures involving the specified address
     */
    function getTokenTransfersByAddress(
        address address_
    ) external view returns (TokenTransfer[] memory);
}
