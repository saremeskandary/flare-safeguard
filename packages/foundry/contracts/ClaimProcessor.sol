// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/ClaimErrors.sol";

/**
 * @title Claim Processor
 * @dev Implementation of the insurance claim processing system for BSD token
 *
 * The Claim Processor is a specialized contract that:
 * - Manages insurance claims for BSD (Backed Stable Digital Token) holders
 * - Processes claims against insured tokens (which can be any ERC20 token)
 * - Implements a multi-step verification process:
 *   * Initial claim submission
 *   * Evidence verification
 *   * Expert review
 *   * Final settlement
 * - Handles claim payouts in USDT (Tether) for stability
 * - Includes role-based access control for different stakeholders
 *
 * This system is designed to provide insurance coverage for BSD token holders
 * while maintaining transparency and security in the claim processing workflow.
 * Claims are settled in USDT to ensure stable value for payouts, while BSD
 * remains the primary token for the platform's operations.
 */
contract ClaimProcessor is AccessControl, ReentrancyGuard {
    using ClaimErrors for *;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    enum ClaimStatus {
        Pending,
        UnderReview,
        Approved,
        Rejected,
        Paid
    }

    struct Claim {
        address insured;
        address tokenAddress;
        uint256 amount;
        uint256 timestamp;
        string description;
        ClaimStatus status;
        address verifier;
        string rejectionReason;
    }

    struct InsurancePolicy {
        address insured;
        address tokenAddress;
        uint256 coverageAmount;
        uint256 premium;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }

    mapping(uint256 => Claim) public claims;
    mapping(address => InsurancePolicy) public policies;
    mapping(address => uint256[]) public userClaims;

    uint256 public claimCount;
    IERC20 public bsdToken;

    event ClaimSubmitted(
        uint256 indexed claimId,
        address indexed insured,
        uint256 amount
    );
    event ClaimStatusUpdated(uint256 indexed claimId, ClaimStatus status);
    event ClaimPaid(
        uint256 indexed claimId,
        address indexed insured,
        uint256 amount
    );
    event PolicyCreated(
        address indexed insured,
        address indexed token,
        uint256 coverageAmount
    );

    constructor(address _bsdToken) {
        if (_bsdToken == address(0))
            revert ClaimErrors.InvalidBSDTokenAddress();
        bsdToken = IERC20(_bsdToken);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Create a new insurance policy
     * @param tokenAddress Address of the insured token
     * @param coverageAmount Amount of coverage
     * @param premium Premium amount
     * @param duration Duration in days
     */
    function createPolicy(
        address tokenAddress,
        uint256 coverageAmount,
        uint256 premium,
        uint256 duration
    ) external nonReentrant {
        if (tokenAddress == address(0))
            revert ClaimErrors.InvalidTokenAddress();
        if (coverageAmount == 0) revert ClaimErrors.InvalidCoverageAmount();
        if (premium == 0) revert ClaimErrors.InvalidPremium();
        if (duration == 0) revert ClaimErrors.InvalidDuration();

        // Transfer premium
        if (!bsdToken.transferFrom(msg.sender, address(this), premium))
            revert ClaimErrors.PremiumTransferFailed();

        policies[msg.sender] = InsurancePolicy({
            insured: msg.sender,
            tokenAddress: tokenAddress,
            coverageAmount: coverageAmount,
            premium: premium,
            startTime: block.timestamp,
            endTime: block.timestamp + (duration * 1 days),
            isActive: true
        });

        emit PolicyCreated(msg.sender, tokenAddress, coverageAmount);
    }

    /**
     * @dev Submit a new claim
     * @param amount Claim amount
     * @param description Description of the claim
     */
    function submitClaim(
        uint256 amount,
        string memory description
    ) external nonReentrant {
        InsurancePolicy memory policy = policies[msg.sender];
        if (!policy.isActive) revert ClaimErrors.PolicyNotActive();
        if (block.timestamp > policy.endTime)
            revert ClaimErrors.PolicyExpired();
        if (amount > policy.coverageAmount)
            revert ClaimErrors.AmountExceedsCoverage();

        uint256 claimId = claimCount++;
        claims[claimId] = Claim({
            insured: msg.sender,
            tokenAddress: policy.tokenAddress,
            amount: amount,
            timestamp: block.timestamp,
            description: description,
            status: ClaimStatus.Pending,
            verifier: address(0),
            rejectionReason: ""
        });

        userClaims[msg.sender].push(claimId);
        emit ClaimSubmitted(claimId, msg.sender, amount);
    }

    /**
     * @dev Review a claim
     * @param claimId ID of the claim
     * @param approved Whether the claim is approved
     * @param reason Reason for rejection if not approved
     */
    function reviewClaim(
        uint256 claimId,
        bool approved,
        string memory reason
    ) external onlyRole(VERIFIER_ROLE) nonReentrant {
        Claim storage claim = claims[claimId];
        if (
            claim.status != ClaimStatus.Pending &&
            claim.status != ClaimStatus.UnderReview
        ) revert ClaimErrors.InvalidClaimStatus();

        claim.verifier = msg.sender;
        claim.status = approved ? ClaimStatus.Approved : ClaimStatus.Rejected;
        if (!approved) {
            claim.rejectionReason = reason;
        }

        emit ClaimStatusUpdated(claimId, claim.status);
    }

    /**
     * @dev Process claim payout
     * @param claimId ID of the claim
     */
    function processPayout(uint256 claimId) internal {
        Claim storage claim = claims[claimId];
        if (claim.status != ClaimStatus.Approved)
            revert ClaimErrors.ClaimNotApproved();
        if (claim.status == ClaimStatus.Paid)
            revert ClaimErrors.ClaimAlreadyPaid();

        InsurancePolicy memory policy = policies[claim.insured];
        if (!policy.isActive) revert ClaimErrors.PolicyNotActive();
        if (block.timestamp > policy.endTime)
            revert ClaimErrors.PolicyExpired();

        // Transfer the claim amount to the insured
        if (!bsdToken.transfer(claim.insured, claim.amount))
            revert ClaimErrors.TransferFailed();

        claim.status = ClaimStatus.Paid;
        emit ClaimPaid(claimId, claim.insured, claim.amount);
    }

    /**
     * @dev Public function to process claim payout
     * @param claimId ID of the claim
     */
    function processClaimPayout(
        uint256 claimId
    ) external onlyRole(ADMIN_ROLE) nonReentrant {
        processPayout(claimId);
    }

    /**
     * @dev Get claim details
     * @param claimId ID of the claim
     */
    function getClaim(
        uint256 claimId
    )
        external
        view
        returns (
            address insured,
            address tokenAddress,
            uint256 amount,
            uint256 timestamp,
            string memory description,
            ClaimStatus status,
            address verifier,
            string memory rejectionReason
        )
    {
        Claim memory claim = claims[claimId];
        return (
            claim.insured,
            claim.tokenAddress,
            claim.amount,
            claim.timestamp,
            claim.description,
            claim.status,
            claim.verifier,
            claim.rejectionReason
        );
    }

    /**
     * @dev Get user's claims
     * @param user Address of the user
     * @return Array of claim IDs
     */
    function getUserClaims(
        address user
    ) external view returns (uint256[] memory) {
        return userClaims[user];
    }

    /**
     * @dev Get policy details
     * @param insured Address of the insured
     */
    function getPolicy(
        address insured
    )
        external
        view
        returns (
            address tokenAddress,
            uint256 coverageAmount,
            uint256 premium,
            uint256 startTime,
            uint256 endTime,
            bool isActive
        )
    {
        InsurancePolicy memory policy = policies[insured];
        return (
            policy.tokenAddress,
            policy.coverageAmount,
            policy.premium,
            policy.startTime,
            policy.endTime,
            policy.isActive
        );
    }
}
