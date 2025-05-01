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
        uint256 reviewDeadline;
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
    mapping(address => uint256) public lastClaimTime;

    uint256 public claimCount;
    IERC20 public bsdToken;
    uint256 public constant CLAIM_COOLDOWN = 7 days; // One claim per week per user
    uint256 public constant MINIMUM_COVERAGE_TIME = 30 days; // Must have policy for at least 30 days
    uint256 public constant MINIMUM_PREMIUM = 1 ether; // Minimum premium requirement

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

    constructor(address _bsdToken, address admin) {
        if (_bsdToken == address(0))
            revert ClaimErrors.InvalidBSDTokenAddress();
        bsdToken = IERC20(_bsdToken);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    /**
     * @dev Create a new insurance policy for a user
     * @notice This function allows users to create an insurance policy by paying a premium in BSD tokens
     * @notice The policy provides coverage for a specific token with defined coverage amount and duration
     * @param tokenAddress The address of the token to be insured
     * @param coverageAmount The maximum amount that can be claimed under this policy
     * @param premium The amount of BSD tokens required as premium payment
     * @param duration The duration of the policy in days
     * @custom:requirements The token address must be valid, coverage amount and premium must be non-zero
     * @custom:effects Transfers premium from user to contract and creates a new policy
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
     * @dev Submit a new insurance claim with rate limiting and spam prevention
     * @notice This function allows policyholders to submit a claim for their insured tokens
     * @notice Claims are subject to cooldown periods and minimum policy requirements
     * @param amount The amount being claimed
     * @param description A detailed description of the claim and reason for filing
     * @custom:requirements
     *  - Policy must be active and not expired
     *  - Claim amount must not exceed coverage
     *  - Policy must be active for minimum coverage time (30 days)
     *  - Premium must meet minimum requirement (1 ETH)
     *  - Must respect cooldown period between claims (7 days)
     * @custom:effects
     *  - Creates a new claim record
     *  - Updates last claim timestamp
     *  - Emits ClaimSubmitted event
     */
    function submitClaim(
        uint256 amount,
        string memory description
    ) external nonReentrant {
        InsurancePolicy memory policy = policies[msg.sender];

        // Check if user has an active policy with minimum requirements
        if (!policy.isActive) revert ClaimErrors.PolicyNotActive();
        if (block.timestamp > policy.endTime)
            revert ClaimErrors.PolicyExpired();
        if (amount > policy.coverageAmount)
            revert ClaimErrors.AmountExceedsCoverage();

        // checks for spam prevention
        if (block.timestamp < policy.startTime + MINIMUM_COVERAGE_TIME)
            revert ClaimErrors.PolicyTooNew();
        if (policy.premium < MINIMUM_PREMIUM)
            revert ClaimErrors.InsufficientPremium();
        if (block.timestamp < lastClaimTime[msg.sender] + CLAIM_COOLDOWN)
            revert ClaimErrors.ClaimCooldownActive();

        // Update last claim time
        lastClaimTime[msg.sender] = block.timestamp;

        // Create the claim
        uint256 claimId = claimCount++;
        claims[claimId] = Claim({
            insured: msg.sender,
            tokenAddress: policy.tokenAddress,
            amount: amount,
            timestamp: block.timestamp,
            description: description,
            status: ClaimStatus.Pending,
            verifier: address(0),
            rejectionReason: "",
            reviewDeadline: block.timestamp + 30 days
        });

        userClaims[msg.sender].push(claimId);
        emit ClaimSubmitted(claimId, msg.sender, amount);
    }

    /**
     * @dev Review and decide on a submitted claim
     * @notice This function allows verifiers to approve or reject claims
     * @notice Only accounts with VERIFIER_ROLE can call this function
     * @param claimId The ID of the claim to be reviewed
     * @param approved Boolean indicating whether the claim is approved
     * @param reason The reason for rejection if the claim is not approved
     * @custom:requirements The claim must be in Pending or UnderReview status
     * @custom:effects Updates claim status and emits ClaimStatusUpdated event
     *
     *  FIXME what if the verifier never calls this function?
     *  If verifier doesn't review within 30 days:
     *  Anyone can call enforceReviewDeadline(claimId)
     *  Claim auto-rejects with specified reason
     *  Claimer gets final resolution (though rejected)
     *  Funds remain in contract (claimer doesn't receive payment)
     *  To Actually Get Paid The claimer would need to:
     *  - Resubmit a new claim (if policy still active)
     *  - Hope for verifier participation in new claim
     *  - Consider providing stronger evidence/documentation
     *  should we modify the auto-rejection consequence? We could instead:
     *  1) Automatically escalate to admin review
     *  2) Enable community voting mechanism
     *  3) Implement secondary verification layer
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
     * @dev Internal function to process claim payout
     * @notice This function handles the actual transfer of funds for approved claims
     * @param claimId The ID of the claim to be paid out
     * @custom:requirements The claim must be approved and not already paid, policy must be active
     * @custom:effects Transfers funds to the insured and updates claim status to Paid
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
     * @notice This function allows administrators to trigger the payout of approved claims
     * @notice Only accounts with ADMIN_ROLE can call this function
     * @param claimId The ID of the claim to be paid out
     * @custom:requirements The caller must have ADMIN_ROLE
     * @custom:effects Calls internal processPayout function
     */
    function processClaimPayout(
        uint256 claimId
    ) external onlyRole(ADMIN_ROLE) nonReentrant {
        processPayout(claimId);
    }

    /**
     * @dev Get detailed information about a specific claim
     * @notice This function returns all details of a claim including status and verification information
     * @param claimId The ID of the claim to query
     * @return insured The address of the policyholder
     * @return tokenAddress The address of the insured token
     * @return amount The claimed amount
     * @return timestamp When the claim was submitted
     * @return description The claim description
     * @return status The current status of the claim
     * @return verifier The address of the verifier who reviewed the claim
     * @return rejectionReason The reason for rejection if the claim was rejected
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
     * @dev Get all claims associated with a specific user
     * @notice This function returns an array of claim IDs for a given user
     * @param user The address of the user to query
     * @return Array of claim IDs associated with the user
     */
    function getUserClaims(
        address user
    ) external view returns (uint256[] memory) {
        return userClaims[user];
    }

    /**
     * @dev Get detailed information about a user's insurance policy
     * @notice This function returns all details of a user's active insurance policy
     * @param insured The address of the policyholder
     * @return tokenAddress The address of the insured token
     * @return coverageAmount The maximum coverage amount
     * @return premium The premium amount paid
     * @return startTime When the policy started
     * @return endTime When the policy expires
     * @return isActive Whether the policy is currently active
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

    /**
     * @dev Automatically reject claims that pass review deadline
     * @notice Can be called by anyone to enforce timely processing
     */
    function enforceReviewDeadline(uint256 claimId) external {
        Claim storage claim = claims[claimId];

        if (
            block.timestamp > claim.reviewDeadline &&
            (claim.status == ClaimStatus.Pending ||
                claim.status == ClaimStatus.UnderReview)
        ) {
            claim.status = ClaimStatus.Rejected;
            claim.rejectionReason = "Not reviewed within deadline";
            emit ClaimStatusUpdated(claimId, ClaimStatus.Rejected);
        }
    }
}
