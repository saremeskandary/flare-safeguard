// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/LiquidityPool.sol";
import "../contracts/BSDToken.sol";
import "../contracts/mock/MockUSDT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityPoolTest is Test {
    LiquidityPool public pool;
    BSDToken public bsdToken;
    MockUSDT public usdt;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy tokens
        bsdToken = new BSDToken();
        usdt = new MockUSDT();

        // Deploy liquidity pool
        pool = new LiquidityPool(address(bsdToken), address(usdt));

        // Fund test accounts
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);

        // Mint some BSD tokens for testing
        bsdToken.mint(user1, 1000 ether);
        bsdToken.mint(user2, 1000 ether);

        // Mint some USDT tokens for testing
        usdt.mint(user1, 1000 * 10 ** 6); // USDT has 6 decimals
        usdt.mint(user2, 1000 * 10 ** 6);
    }

    function testPoolInitialization() public view {
        assertEq(address(pool.bsdToken()), address(bsdToken));
        assertEq(address(pool.usdtToken()), address(usdt));
        assertEq(pool.totalLiquidity(), 0);
    }

    function testAddLiquidity() public {
        uint256 bsdAmount = 100 ether;
        uint256 usdtAmount = 100 * 10 ** 6; // USDT has 6 decimals

        // Approve pool to spend tokens
        vm.prank(user1);
        bsdToken.approve(address(pool), bsdAmount);
        vm.prank(user1);
        usdt.approve(address(pool), usdtAmount);

        // Add liquidity
        vm.prank(user1);
        pool.addLiquidity(bsdAmount, usdtAmount);

        assertEq(pool.balanceOf(user1), bsdAmount);
        assertEq(pool.totalLiquidity(), bsdAmount);
    }

    function testRemoveLiquidity() public {
        uint256 bsdAmount = 100 ether;
        uint256 usdtAmount = 100 * 10 ** 6; // USDT has 6 decimals

        // First add liquidity
        vm.prank(user1);
        bsdToken.approve(address(pool), bsdAmount);
        vm.prank(user1);
        usdt.approve(address(pool), usdtAmount);
        vm.prank(user1);
        pool.addLiquidity(bsdAmount, usdtAmount);

        // Then remove liquidity
        vm.prank(user1);
        pool.removeLiquidity(bsdAmount / 2);

        assertEq(pool.balanceOf(user1), bsdAmount / 2);
        assertEq(pool.totalLiquidity(), bsdAmount / 2);
    }

    function testSwapTokens() public {
        uint256 initialBsdAmount = 1000 ether;
        uint256 initialUsdtAmount = 1000 * 10 ** 6; // USDT has 6 decimals

        // Add initial liquidity
        vm.prank(user1);
        bsdToken.approve(address(pool), initialBsdAmount);
        vm.prank(user1);
        usdt.approve(address(pool), initialUsdtAmount);
        vm.prank(user1);
        pool.addLiquidity(initialBsdAmount, initialUsdtAmount);

        // Perform swap
        uint256 swapAmount = 100 ether;
        vm.prank(user2);
        bsdToken.approve(address(pool), swapAmount);
        vm.prank(user2);
        pool.swapBSDForUSDT(swapAmount);

        // Verify balances
        assertEq(
            bsdToken.balanceOf(address(pool)),
            initialBsdAmount + swapAmount
        );
    }

    function testFeeDistribution() public {
        uint256 bsdAmount = 1000 ether;
        uint256 usdtAmount = 1000 * 10 ** 6; // USDT has 6 decimals

        // Add liquidity
        vm.prank(user1);
        bsdToken.approve(address(pool), bsdAmount);
        vm.prank(user1);
        usdt.approve(address(pool), usdtAmount);
        vm.prank(user1);
        pool.addLiquidity(bsdAmount, usdtAmount);

        // Perform some swaps to generate fees
        uint256 swapAmount = 100 ether;
        vm.prank(user2);
        bsdToken.approve(address(pool), swapAmount);
        vm.prank(user2);
        pool.swapBSDForUSDT(swapAmount);

        // Check fee distribution
        uint256 fees = pool.getAccumulatedFees();
        assertTrue(fees > 0);
    }

    function testFailures() public {
        uint256 amount = 100 ether;
        uint256 usdtAmount = 100 * 10 ** 6; // USDT has 6 decimals

        // Test insufficient balance
        vm.expectRevert("Insufficient balance");
        vm.prank(user1);
        pool.removeLiquidity(amount);

        // Test insufficient allowance
        vm.expectRevert("Insufficient allowance");
        vm.prank(user1);
        pool.addLiquidity(amount, usdtAmount);

        // Test zero amount
        vm.expectRevert("Amount must be greater than 0");
        vm.prank(user1);
        pool.addLiquidity(0, 0);
    }
}
