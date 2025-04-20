// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title InsuranceCore
 * @dev Core insurance features including RWA token evaluation, coverage options, and premium calculation
 */
contract InsuranceCore is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EVALUATOR_ROLE = keccak256("EVALUATOR_ROLE");

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

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Add a new coverage option
     * @param coverageLimit Maximum coverage amount
     * @param premiumRate Premium rate in basis points
     * @param minDuration Minimum coverage duration in days
     * @param maxDuration Maximum coverage duration in days
     */
    function addCoverageOption(
        uint256 coverageLimit,
        uint256 premiumRate,
        uint256 minDuration,
        uint256 maxDuration
    ) external onlyRole(ADMIN_ROLE) {
        require(coverageLimit > 0, "Invalid coverage limit");
        require(premiumRate > 0, "Invalid premium rate");
        require(
            minDuration > 0 && maxDuration >= minDuration,
            "Invalid duration"
        );

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
     */
    function evaluateRWA(
        address tokenAddress,
        uint256 value,
        uint256 riskScore
    ) external onlyRole(EVALUATOR_ROLE) {
        require(tokenAddress != address(0), "Invalid token address");
        require(value > 0, "Invalid value");
        require(riskScore >= 1 && riskScore <= 100, "Invalid risk score");

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
     */
    function calculatePremium(
        uint256 coverageAmount,
        uint256 duration,
        address tokenAddress
    ) external view returns (uint256 premium) {
        require(coverageAmount > 0, "Invalid coverage amount");
        require(duration > 0, "Invalid duration");

        RWAEvaluation memory evaluation = rwaEvaluations[tokenAddress];
        require(evaluation.isValid, "Token not evaluated");

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
        require(
            selectedOptionId != type(uint256).max,
            "No suitable coverage option"
        );

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
