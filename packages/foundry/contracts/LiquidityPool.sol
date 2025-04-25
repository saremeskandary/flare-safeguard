// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BSDToken.sol";

/**
 * @title Liquidity Pool
 * @dev A simplified liquidity pool for BSD/USDT trading with basic fee collection
 *
 * This contract provides a basic liquidity pool implementation that:
 * - Allows users to add and remove liquidity in BSD/USDT pairs
 * - Facilitates swaps between BSD and USDT with a 0.3% fee
 * - Tracks accumulated fees for potential distribution
 * - Uses SafeERC20 for secure token transfers
 *
 * This is a simplified version compared to BSDLiquidityPool, focusing on core
 * functionality without advanced features like fee distribution or liquidity mining.
 */
contract LiquidityPool is Ownable {
    // Custom errors
    error AmountMustBeGreaterThanZero();
    error InsufficientBalance();

    using SafeERC20 for IERC20;
    using SafeERC20 for BSDToken;

    BSDToken public immutable bsdToken;
    IERC20 public immutable usdtToken;
    uint256 public totalLiquidity;
    uint256 private accumulatedFees;
    uint256 private constant FEE_BPS = 30; // 0.3%

    mapping(address => uint256) public balanceOf;

    event LiquidityAdded(
        address indexed provider,
        uint256 bsdAmount,
        uint256 usdtAmount
    );
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event SwapExecuted(
        address indexed user,
        uint256 bsdAmount,
        uint256 usdtAmount
    );

    /**
     * @dev Constructor initializes the liquidity pool with BSD and USDT token addresses
     * @param _bsdToken Address of the BSD token contract
     * @param _usdtToken Address of the USDT token contract
     */
    constructor(address _bsdToken, address _usdtToken) Ownable(msg.sender) {
        bsdToken = BSDToken(_bsdToken);
        usdtToken = IERC20(_usdtToken);
    }

    /**
     * @dev Allows users to add liquidity to the pool
     * @param bsdAmount Amount of BSD tokens to add
     * @param usdtAmount Amount of USDT tokens to add
     */
    function addLiquidity(uint256 bsdAmount, uint256 usdtAmount) external {
        if (bsdAmount == 0 || usdtAmount == 0)
            revert AmountMustBeGreaterThanZero();

        bsdToken.safeTransferFrom(msg.sender, address(this), bsdAmount);
        usdtToken.safeTransferFrom(msg.sender, address(this), usdtAmount);

        balanceOf[msg.sender] += bsdAmount;
        totalLiquidity += bsdAmount;

        emit LiquidityAdded(msg.sender, bsdAmount, usdtAmount);
    }

    /**
     * @dev Allows users to remove liquidity from the pool
     * @param amount Amount of BSD tokens to remove
     */
    function removeLiquidity(uint256 amount) external {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance();

        balanceOf[msg.sender] -= amount;
        totalLiquidity -= amount;

        bsdToken.safeTransfer(msg.sender, amount);
        emit LiquidityRemoved(msg.sender, amount);
    }

    /**
     * @dev Allows users to swap BSD for USDT
     * @param bsdAmount Amount of BSD tokens to swap
     */
    function swapBSDForUSDT(uint256 bsdAmount) external {
        if (bsdAmount == 0) revert AmountMustBeGreaterThanZero();

        uint256 fee = (bsdAmount * FEE_BPS) / 10000;
        uint256 amountAfterFee = bsdAmount - fee;

        bsdToken.safeTransferFrom(msg.sender, address(this), bsdAmount);
        accumulatedFees += fee;

        emit SwapExecuted(msg.sender, bsdAmount, amountAfterFee);
    }

    /**
     * @dev Returns the total accumulated fees
     * @return The total amount of fees collected
     */
    function getAccumulatedFees() external view returns (uint256) {
        return accumulatedFees;
    }
}
