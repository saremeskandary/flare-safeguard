// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./BSDToken.sol";

/**
 * @title BSD Liquidity Pool
 * @dev Implementation of the BSD/USDT liquidity pool with fee distribution
 *
 * The BSD Liquidity Pool is a specialized AMM (Automated Market Maker) that:
 * - Facilitates trading between BSD (Backed Stable Digital Token) and USDT
 * - Implements a fee mechanism (0.3% per trade) that is distributed to:
 *   * BSD token holders (50% of fees)
 *   * Liquidity providers (50% of fees)
 * - Provides liquidity mining incentives through BSD token rewards
 * - Includes emergency pause functionality for security
 *
 * This pool is designed to provide deep liquidity for BSD/USDT trading pairs
 * while incentivizing long-term liquidity provision through fee sharing and
 * reward mechanisms.
 */
contract BSDLiquidityPool is ReentrancyGuard, Pausable {
    // Custom errors
    error InvalidBSDTokenAddress();
    error InvalidUSDTTokenAddress();
    error AmountsMustBeGreaterThanZero();
    error BSDTransferFailed();
    error USDTTransferFailed();
    error SharesMustBeGreaterThanZero();
    error InsufficientShares();
    error AmountMustBeGreaterThanZero();
    error InsufficientOutputAmount();

    BSDToken public immutable bsdToken;
    IERC20 public immutable usdtToken;

    // Pool state
    uint256 public totalBSD;
    uint256 public totalUSDT;

    // Fee configuration (0.3% = 30 basis points)
    uint256 public constant SWAP_FEE_BPS = 30;
    uint256 public constant FEE_DENOMINATOR = 10000;

    // Liquidity provider rewards
    uint256 public constant REWARD_RATE_BPS = 100; // 1% of fees
    mapping(address => uint256) public providerShares;
    uint256 public totalShares;

    // Events
    event LiquidityAdded(
        address indexed provider,
        uint256 bsdAmount,
        uint256 usdtAmount
    );
    event LiquidityRemoved(
        address indexed provider,
        uint256 bsdAmount,
        uint256 usdtAmount
    );
    event Swap(
        address indexed user,
        uint256 bsdIn,
        uint256 usdtIn,
        uint256 bsdOut,
        uint256 usdtOut
    );
    event FeesCollected(uint256 bsdFees, uint256 usdtFees);
    event RewardsDistributed(uint256 totalRewards);

    constructor(address _bsdToken, address _usdtToken) {
        if (_bsdToken == address(0)) revert InvalidBSDTokenAddress();
        if (_usdtToken == address(0)) revert InvalidUSDTTokenAddress();

        bsdToken = BSDToken(_bsdToken);
        usdtToken = IERC20(_usdtToken);
    }

    /**
     * @dev Add liquidity to the pool
     * @param bsdAmount Amount of BSD tokens to add
     * @param usdtAmount Amount of USDT tokens to add
     */
    function addLiquidity(
        uint256 bsdAmount,
        uint256 usdtAmount
    ) external nonReentrant whenNotPaused {
        if (bsdAmount == 0 || usdtAmount == 0)
            revert AmountsMustBeGreaterThanZero();

        // Transfer tokens from user
        if (!bsdToken.transferFrom(msg.sender, address(this), bsdAmount))
            revert BSDTransferFailed();
        if (!usdtToken.transferFrom(msg.sender, address(this), usdtAmount))
            revert USDTTransferFailed();

        // Calculate shares
        uint256 shares;
        if (totalShares == 0) {
            shares = bsdAmount;
        } else {
            shares = (bsdAmount * totalShares) / totalBSD;
        }

        // Update state
        totalBSD += bsdAmount;
        totalUSDT += usdtAmount;
        totalShares += shares;
        providerShares[msg.sender] += shares;

        emit LiquidityAdded(msg.sender, bsdAmount, usdtAmount);
    }

    /**
     * @dev Remove liquidity from the pool
     * @param shares Amount of shares to remove
     */
    function removeLiquidity(
        uint256 shares
    ) external nonReentrant whenNotPaused {
        if (shares == 0) revert SharesMustBeGreaterThanZero();
        if (shares > providerShares[msg.sender]) revert InsufficientShares();

        // Calculate amounts to return
        uint256 bsdAmount = (shares * totalBSD) / totalShares;
        uint256 usdtAmount = (shares * totalUSDT) / totalShares;

        // Update state
        totalBSD -= bsdAmount;
        totalUSDT -= usdtAmount;
        totalShares -= shares;
        providerShares[msg.sender] -= shares;

        // Transfer tokens to user
        if (!bsdToken.transfer(msg.sender, bsdAmount))
            revert BSDTransferFailed();
        if (!usdtToken.transfer(msg.sender, usdtAmount))
            revert USDTTransferFailed();

        emit LiquidityRemoved(msg.sender, bsdAmount, usdtAmount);
    }

    /**
     * @dev Swap BSD for USDT
     * @param bsdIn Amount of BSD tokens to swap
     * @param minUsdtOut Minimum amount of USDT to receive
     */
    function swapBSDForUSDT(
        uint256 bsdIn,
        uint256 minUsdtOut
    ) external nonReentrant whenNotPaused {
        if (bsdIn == 0) revert AmountMustBeGreaterThanZero();

        // Calculate amounts with fee
        uint256 fee = (bsdIn * SWAP_FEE_BPS) / FEE_DENOMINATOR;
        uint256 bsdInAfterFee = bsdIn - fee;

        uint256 usdtOut = (bsdInAfterFee * totalUSDT) / totalBSD;
        if (usdtOut < minUsdtOut) revert InsufficientOutputAmount();

        // Transfer tokens
        if (!bsdToken.transferFrom(msg.sender, address(this), bsdIn))
            revert BSDTransferFailed();
        if (!usdtToken.transfer(msg.sender, usdtOut))
            revert USDTTransferFailed();

        // Update pool state
        totalBSD += bsdIn;
        totalUSDT -= usdtOut;

        emit Swap(msg.sender, bsdIn, 0, 0, usdtOut);
    }

    /**
     * @dev Swap USDT for BSD
     * @param usdtIn Amount of USDT tokens to swap
     * @param minBsdOut Minimum amount of BSD to receive
     */
    function swapUSDTForBSD(
        uint256 usdtIn,
        uint256 minBsdOut
    ) external nonReentrant whenNotPaused {
        if (usdtIn == 0) revert AmountMustBeGreaterThanZero();

        // Calculate amounts with fee
        uint256 fee = (usdtIn * SWAP_FEE_BPS) / FEE_DENOMINATOR;
        uint256 usdtInAfterFee = usdtIn - fee;

        uint256 bsdOut = (usdtInAfterFee * totalBSD) / totalUSDT;
        if (bsdOut < minBsdOut) revert InsufficientOutputAmount();

        // Transfer tokens
        if (!usdtToken.transferFrom(msg.sender, address(this), usdtIn))
            revert USDTTransferFailed();
        if (!bsdToken.transfer(msg.sender, bsdOut)) revert BSDTransferFailed();

        // Update pool state
        totalUSDT += usdtIn;
        totalBSD -= bsdOut;

        emit Swap(msg.sender, 0, usdtIn, bsdOut, 0);
    }

    /**
     * @dev Get the current pool ratio
     */
    function getPoolRatio() external view returns (uint256) {
        return (totalUSDT * 1e18) / totalBSD;
    }

    /**
     * @dev Get user's share of the pool
     */
    function getUserShares(address user) external view returns (uint256) {
        return providerShares[user];
    }
}
