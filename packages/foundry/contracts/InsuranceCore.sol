// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Insurance Core
 * @dev Core insurance features including RWA token evaluation, coverage options, and premium calculation
 *
 * The Insurance Core is the central component of the BSD Insurance Protocol that:
 * - Evaluates RWA tokens through a comprehensive risk assessment process that includes:
 *   - Token liquidity analysis and trading volume metrics
 *   - Historical price volatility and market stability
 *   - Asset backing verification and documentation review
 *   - Smart contract security and compliance checks
 *   - Assigns risk scores (1-100) based on weighted evaluation criteria
 * - Manages insurance coverage options with different limits and rates
 * - Calculates premiums based on coverage amount, duration, and token risk
 * - Provides a foundation for the insurance marketplace
 *
 * This contract implements the business logic for:
 * - Risk assessment of tokenized real-world assets
 * - Premium calculation algorithms
 * - Coverage option management
 * - Token evaluation tracking
 *
 * The Insurance Core works in conjunction with the Claim Processor to provide
 * a complete insurance solution for RWA token holders.
 */
contract InsuranceCore is ReentrancyGuard {
    // Custom errors
    error InvalidCoverageLimit();
    error InvalidPremiumRate();
    error InvalidDuration();
    error InvalidTokenAddress();
    error InvalidValue();
    error InvalidRiskScore();
    error InvalidCoverageAmount();
    error TokenNotEvaluated();
    error NoSuitableCoverageOption();

    struct CoverageOption {
        uint256 coverageLimit;
        uint256 premiumRate; // in basis points (1% = 100)
        uint256 minDuration;
        uint256 maxDuration;
        bool isActive;
    }

    struct RWAEvaluation {
        address tokenAddress;
        uint256 value;
        uint256 riskScore; // 1-100, higher means more risk
        uint256 lastUpdated;
        bool isValid;
    }

    mapping(uint256 => CoverageOption) public coverageOptions;
    mapping(address => RWAEvaluation) public rwaEvaluations;
    uint256 public coverageOptionCount;

    event CoverageOptionAdded(
        uint256 indexed optionId,
        uint256 coverageLimit,
        uint256 premiumRate
    );
    event RWAEvaluated(address indexed token, uint256 value, uint256 riskScore);
    event PremiumCalculated(
        address indexed insured,
        uint256 amount,
        uint256 premium
    );

    /**
     * @dev Add a new coverage option
     * @param coverageLimit Maximum coverage amount
     * @param premiumRate Premium rate in basis points
     * @param minDuration Minimum coverage duration in days
     * @param maxDuration Maximum coverage duration in days
     *
     * This function allows administrators to create new insurance coverage options
     * with different limits, rates, and duration constraints. These options form
     * the basis of the insurance products offered by the protocol.
     */
    function addCoverageOption(
        uint256 coverageLimit,
        uint256 premiumRate,
        uint256 minDuration,
        uint256 maxDuration
    ) external {
        if (coverageLimit == 0) revert InvalidCoverageLimit();
        if (premiumRate == 0) revert InvalidPremiumRate();
        if (minDuration == 0 || maxDuration < minDuration)
            revert InvalidDuration();

        uint256 optionId = coverageOptionCount++;
        coverageOptions[optionId] = CoverageOption({
            coverageLimit: coverageLimit,
            premiumRate: premiumRate,
            minDuration: minDuration,
            maxDuration: maxDuration,
            isActive: true
        });

        emit CoverageOptionAdded(optionId, coverageLimit, premiumRate);
    }

    /**
     * @dev Evaluate an RWA token
     * @param tokenAddress Address of the RWA token
     * @param value Current value of the token
     * @param riskScore Risk score (1-100)
     *
     * This function allows evaluators to assess the risk profile of a tokenized
     * real-world asset. The risk score (1-100) is used to adjust premium rates,
     * with higher scores resulting in higher premiums. This evaluation is critical
     * for determining appropriate insurance pricing.
     */
    function evaluateRWA(
        address tokenAddress,
        uint256 value,
        uint256 riskScore
    ) external {
        if (tokenAddress == address(0)) revert InvalidTokenAddress();
        if (value == 0) revert InvalidValue();
        if (riskScore < 1 || riskScore > 100) revert InvalidRiskScore();

        rwaEvaluations[tokenAddress] = RWAEvaluation({
            tokenAddress: tokenAddress,
            value: value,
            riskScore: riskScore,
            lastUpdated: block.timestamp,
            isValid: true
        });

        emit RWAEvaluated(tokenAddress, value, riskScore);
    }

    /**
     * @dev Calculate insurance premium
     * @param coverageAmount Amount of coverage requested
     * @param duration Coverage duration in days
     * @param tokenAddress Address of the RWA token
     * @return premium Calculated premium amount
     *
     * This function calculates the insurance premium based on:
     * 1. The coverage amount requested
     * 2. The duration of coverage
     * 3. The risk score of the token
     * 4. The applicable coverage option
     *
     * The premium calculation incorporates both the base rate from the coverage
     * option and an adjustment based on the token's risk score.
     */
    function calculatePremium(
        uint256 coverageAmount,
        uint256 duration,
        address tokenAddress
    ) external view returns (uint256 premium) {
        if (coverageAmount == 0) revert InvalidCoverageAmount();
        if (duration == 0) revert InvalidDuration();

        RWAEvaluation memory evaluation = rwaEvaluations[tokenAddress];
        if (!evaluation.isValid) revert TokenNotEvaluated();

        // Find suitable coverage option
        uint256 selectedOptionId = type(uint256).max;
        for (uint256 i = 0; i < coverageOptionCount; i++) {
            CoverageOption memory option = coverageOptions[i];
            if (
                option.isActive &&
                coverageAmount <= option.coverageLimit &&
                duration >= option.minDuration &&
                duration <= option.maxDuration
            ) {
                selectedOptionId = i;
                break;
            }
        }
        if (selectedOptionId == type(uint256).max)
            revert NoSuitableCoverageOption();

        // Calculate base premium
        premium =
            (coverageAmount * coverageOptions[selectedOptionId].premiumRate) /
            10000;

        // Adjust premium based on risk score
        premium = premium + (premium * evaluation.riskScore) / 100;

        return premium;
    }

    /**
     * @dev Get coverage option details
     * @param optionId ID of the coverage option
     * @return coverageLimit Maximum coverage amount
     * @return premiumRate Premium rate in basis points
     * @return minDuration Minimum coverage duration in days
     * @return maxDuration Maximum coverage duration in days
     * @return isActive Whether the option is currently active
     */
    function getCoverageOption(
        uint256 optionId
    )
        external
        view
        returns (
            uint256 coverageLimit,
            uint256 premiumRate,
            uint256 minDuration,
            uint256 maxDuration,
            bool isActive
        )
    {
        CoverageOption memory option = coverageOptions[optionId];
        return (
            option.coverageLimit,
            option.premiumRate,
            option.minDuration,
            option.maxDuration,
            option.isActive
        );
    }

    /**
     * @dev Get RWA evaluation details
     * @param tokenAddress Address of the RWA token
     * @return value Current value of the token
     * @return riskScore Risk score (1-100)
     * @return lastUpdated Timestamp of the last evaluation
     * @return isValid Whether the evaluation is currently valid
     */
    function getRWAEvaluation(
        address tokenAddress
    )
        external
        view
        returns (
            uint256 value,
            uint256 riskScore,
            uint256 lastUpdated,
            bool isValid
        )
    {
        RWAEvaluation memory evaluation = rwaEvaluations[tokenAddress];
        return (
            evaluation.value,
            evaluation.riskScore,
            evaluation.lastUpdated,
            evaluation.isValid
        );
    }
}
