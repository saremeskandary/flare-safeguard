// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title ClaimErrors
 * @notice Library containing shared error definitions for claim processing
 */
library ClaimErrors {
    // Policy related errors
    error InvalidBSDTokenAddress();
    error InvalidTokenAddress();
    error InvalidCoverageAmount();
    error InvalidPremium();
    error InvalidDuration();
    error PremiumTransferFailed();
    error NoActivePolicy();
    error PolicyExpired();
    error PolicyNotActive();
    error AmountExceedsCoverage();

    // Claim related errors
    error InvalidClaimStatus();
    error ClaimNotApproved();
    error ClaimAlreadyPaid();
    error TransferFailed();
}
