// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BSDToken.sol";

contract LiquidityPool is Ownable {
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

    constructor(address _bsdToken, address _usdtToken) Ownable(msg.sender) {
        bsdToken = BSDToken(_bsdToken);
        usdtToken = IERC20(_usdtToken);
    }

    function addLiquidity(uint256 bsdAmount, uint256 usdtAmount) external {
        require(
            bsdAmount > 0 && usdtAmount > 0,
            "Amount must be greater than 0"
        );

        bsdToken.safeTransferFrom(msg.sender, address(this), bsdAmount);
        usdtToken.safeTransferFrom(msg.sender, address(this), usdtAmount);

        balanceOf[msg.sender] += bsdAmount;
        totalLiquidity += bsdAmount;

        emit LiquidityAdded(msg.sender, bsdAmount, usdtAmount);
    }

    function removeLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        totalLiquidity -= amount;

        bsdToken.safeTransfer(msg.sender, amount);
        emit LiquidityRemoved(msg.sender, amount);
    }

    function swapBSDForUSDT(uint256 bsdAmount) external {
        require(bsdAmount > 0, "Amount must be greater than 0");

        uint256 fee = (bsdAmount * FEE_BPS) / 10000;
        uint256 amountAfterFee = bsdAmount - fee;

        bsdToken.safeTransferFrom(msg.sender, address(this), bsdAmount);
        accumulatedFees += fee;

        emit SwapExecuted(msg.sender, bsdAmount, amountAfterFee);
    }

    function getAccumulatedFees() external view returns (uint256) {
        return accumulatedFees;
    }
}
