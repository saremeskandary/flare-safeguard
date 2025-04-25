// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ClaimProcessor.sol";
import "./interfaces/IFdcTransferEventListener.sol";
import {IEVMTransaction} from "flare-periphery/src/coston2/IEVMTransaction.sol";

/**
 * @title Cross Chain Claim Processor
 * @dev Extends the ClaimProcessor to handle cross-chain insurance claims using Flare's Data Connector
 *
 * This contract provides functionality to:
 * - Process insurance claims that involve cross-chain token transfers
 * - Verify token transfers using Flare's Data Connector
 * - Validate claims based on verified cross-chain events
 * - Handle payouts for valid cross-chain claims
 */
contract CrossChainClaimProcessor is ClaimProcessor {
    // Custom errors
    error InvalidFdcListenerAddress();
    error NoActivePolicy();
    error PolicyExpired();
    error AmountExceedsCoverage();
    error ClaimDoesNotExist();
    error InvalidClaimStatus();
    error TransactionHashMismatch();
    error InsufficientConfirmations();
    error InvalidTransactionProof();
    error NoMatchingTransfer();

    // FDC Transfer Event Listener contract
    IFdcTransferEventListener public fdcTransferEventListener;

    // Events
    event CrossChainClaimSubmitted(
        uint256 indexed claimId,
        address indexed insured,
        uint256 amount,
        bytes32 transactionHash,
        uint256 chainId
    );

    event CrossChainClaimVerified(
        uint256 indexed claimId,
        bytes32 transactionHash,
        uint256 chainId
    );

    // Mapping to store cross-chain claim metadata
    mapping(uint256 => bytes) public crossChainClaimMetadata;

    /**
     * @dev Constructor initializes the contract with required dependencies
     * @param _bsdToken Address of the BSD token contract
     * @param _fdcTransferEventListener Address of the FDC Transfer Event Listener contract
     */
    constructor(
        address _bsdToken,
        address _fdcTransferEventListener
    ) ClaimProcessor(_bsdToken) {
        if (_fdcTransferEventListener == address(0))
            revert InvalidFdcListenerAddress();
        fdcTransferEventListener = IFdcTransferEventListener(
            _fdcTransferEventListener
        );
    }

    /**
     * @dev Internal function to create a new claim
     * @param _amount The amount being claimed
     * @return The ID of the created claim
     */
    function _createCrossChainClaim(
        uint256 _amount
    ) internal returns (uint256) {
        InsurancePolicy memory policy = policies[msg.sender];
        if (!policy.isActive) revert NoActivePolicy();
        if (block.timestamp > policy.endTime) revert PolicyExpired();
        if (_amount > policy.coverageAmount) revert AmountExceedsCoverage();

        uint256 claimId = claimCount++;
        claims[claimId] = Claim({
            insured: msg.sender,
            tokenAddress: policy.tokenAddress,
            amount: _amount,
            timestamp: block.timestamp,
            description: "Cross-chain claim",
            status: ClaimStatus.Pending,
            verifier: address(0),
            rejectionReason: ""
        });

        userClaims[msg.sender].push(claimId);
        return claimId;
    }

    /**
     * @dev Submit a cross-chain insurance claim
     * @param _amount The amount being claimed
     * @param _transactionHash The hash of the transaction containing the token transfer
     * @param _chainId The ID of the chain where the transfer occurred
     * @param _requiredConfirmations The number of confirmations required for the transaction
     * @return The ID of the created claim
     */
    function submitCrossChainClaim(
        uint256 _amount,
        bytes32 _transactionHash,
        uint256 _chainId,
        uint16 _requiredConfirmations
    ) external returns (uint256) {
        // Create the claim using the internal function
        uint256 claimId = _createCrossChainClaim(_amount);

        // Store cross-chain specific information
        crossChainClaimMetadata[claimId] = abi.encode(
            _transactionHash,
            _chainId,
            _requiredConfirmations
        );

        emit CrossChainClaimSubmitted(
            claimId,
            msg.sender,
            _amount,
            _transactionHash,
            _chainId
        );

        return claimId;
    }

    /**
     * @dev Verify a cross-chain claim using Flare's Data Connector
     * @param _claimId The ID of the claim to verify
     * @param _proof The transaction proof from Flare's Data Connector
     */
    function verifyCrossChainClaim(
        uint256 _claimId,
        IEVMTransaction.Proof calldata _proof
    ) external onlyRole(VERIFIER_ROLE) {
        if (!_claimExists(_claimId)) revert ClaimDoesNotExist();
        if (claims[_claimId].status != ClaimStatus.Pending)
            revert InvalidClaimStatus();

        // Decode the stored metadata
        (
            bytes32 transactionHash,
            uint256 chainId,
            uint16 requiredConfirmations
        ) = abi.decode(
                crossChainClaimMetadata[_claimId],
                (bytes32, uint256, uint16)
            );

        // Verify that the proof matches the stored transaction hash
        if (_proof.data.requestBody.transactionHash != transactionHash)
            revert TransactionHashMismatch();

        // Verify required confirmations
        if (
            _proof.data.requestBody.requiredConfirmations <
            requiredConfirmations
        ) revert InsufficientConfirmations();

        // Verify the transaction proof using FDC
        if (!fdcTransferEventListener.isEVMTransactionProofValid(_proof))
            revert InvalidTransactionProof();

        // Process the transfer events
        fdcTransferEventListener.collectTransferEvents(_proof);

        // Get the transfers for verification
        IFdcTransferEventListener.TokenTransfer[]
            memory transfers = fdcTransferEventListener
                .getTokenTransfersByAddress(claims[_claimId].insured);

        // Verify that at least one transfer matches the claim amount
        bool transferFound = false;
        for (uint256 i = 0; i < transfers.length; i++) {
            if (
                transfers[i].chainId == chainId &&
                transfers[i].value == claims[_claimId].amount
            ) {
                transferFound = true;
                break;
            }
        }

        if (!transferFound) revert NoMatchingTransfer();

        // Mark the claim as verified
        claims[_claimId].status = ClaimStatus.Approved;

        emit CrossChainClaimVerified(_claimId, transactionHash, chainId);
    }

    /**
     * @dev Process a verified cross-chain claim
     * @param _claimId The ID of the claim to process
     */
    function processCrossChainClaim(
        uint256 _claimId
    ) external onlyRole(ADMIN_ROLE) nonReentrant {
        if (!_claimExists(_claimId)) revert ClaimDoesNotExist();
        if (claims[_claimId].status != ClaimStatus.Approved)
            revert InvalidClaimStatus();

        // Process the claim using the base contract's protected function
        processPayout(_claimId);
    }

    /**
     * @dev Check if a claim exists
     * @param _claimId The ID of the claim to check
     * @return True if the claim exists, false otherwise
     */
    function _claimExists(uint256 _claimId) internal view returns (bool) {
        return claims[_claimId].insured != address(0);
    }
}
