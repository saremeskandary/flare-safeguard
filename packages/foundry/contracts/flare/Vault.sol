// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "dependencies/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "dependencies/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "dependencies/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import "./DataVerification.sol";

/**
 * @title Vault
 * @notice Contract for managing insurance reserves and claim payouts
 */
contract Vault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    IERC20 public reserveToken;
    DataVerification public dataVerification;
    uint256 public totalReserves;
    uint256 public totalClaims;
    uint256 public constant MINIMUM_RESERVE = 1000 ether; // Minimum reserve amount
    uint256 public constant MAXIMUM_CLAIM_RATIO = 80; // Maximum percentage of reserves that can be claimed

    // Events
    event ReserveDeposited(address indexed depositor, uint256 amount);
    event ReserveWithdrawn(address indexed withdrawer, uint256 amount);
    event ClaimProcessed(address indexed claimant, uint256 amount);
    event ClaimRejected(address indexed claimant, string reason);

    constructor(
        address _reserveToken,
        address payable _dataVerification
    ) Ownable(msg.sender) {
        require(_reserveToken != address(0), "Invalid reserve token address");
        require(
            _dataVerification != address(0),
            "Invalid data verification address"
        );

        reserveToken = IERC20(_reserveToken);
        dataVerification = DataVerification(_dataVerification);
    }

    /**
     * @notice Deposit reserves into the vault
     * @param amount Amount of tokens to deposit
     */
    function depositReserves(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        reserveToken.safeTransferFrom(msg.sender, address(this), amount);
        totalReserves += amount;

        emit ReserveDeposited(msg.sender, amount);
    }

    /**
     * @notice Withdraw reserves from the vault (owner only)
     * @param amount Amount of tokens to withdraw
     */
    function withdrawReserves(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= totalReserves, "Insufficient reserves");
        require(
            totalReserves - amount >= MINIMUM_RESERVE,
            "Cannot withdraw below minimum reserve"
        );

        totalReserves -= amount;
        reserveToken.safeTransfer(owner(), amount);

        emit ReserveWithdrawn(owner(), amount);
    }

    /**
     * @notice Process a claim using FDC verification
     * @param requestId The FDC request ID for claim verification
     * @param proof The verification proof
     * @param amount The claim amount
     */
    function processClaim(
        bytes32 requestId,
        bytes calldata proof,
        uint256 amount
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(
            amount <= (totalReserves * MAXIMUM_CLAIM_RATIO) / 100,
            "Claim amount exceeds maximum ratio"
        );

        // Verify the claim using FDC
        bool isValid = dataVerification.verifyAttestation(requestId, proof);

        if (!isValid) {
            emit ClaimRejected(msg.sender, "Invalid claim verification");
            return;
        }

        // Process the claim
        totalClaims += amount;
        totalReserves -= amount;
        reserveToken.safeTransfer(msg.sender, amount);

        emit ClaimProcessed(msg.sender, amount);
    }

    /**
     * @notice Get the current reserve ratio
     * @return The ratio of claims to reserves as a percentage
     */
    function getReserveRatio() external view returns (uint256) {
        if (totalReserves == 0) return 0;
        return (totalClaims * 100) / totalReserves;
    }

    /**
     * @notice Get the available reserve amount
     * @return The amount of reserves available for claims
     */
    function getAvailableReserves() external view returns (uint256) {
        return totalReserves - totalClaims;
    }
}
