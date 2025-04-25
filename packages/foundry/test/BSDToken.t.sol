// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/BSDToken.sol";

contract BSDTokenTest is Test {
    BSDToken public token;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy BSD token
        token = new BSDToken();

        // Fund test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testTokenInitialization() public view {
        assertEq(token.name(), "BSD Token");
        assertEq(token.symbol(), "BSD");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
    }

    function testTokenBacking() public {
        // Test token backing mechanism
        uint256 backingAmount = 1000 ether;
        token.addBacking{value: backingAmount}();

        assertEq(address(token).balance, backingAmount);
        assertEq(token.getBackingAmount(), backingAmount);
    }

    function testTokenDistribution() public {
        // Test token distribution
        uint256 amount = 100 ether;
        token.mint(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testPausability() public {
        // Test pausability features
        token.pause();
        assertTrue(token.paused());

        token.unpause();
        assertFalse(token.paused());
    }

    function testTokenTransfers() public {
        uint256 amount = 100 ether;
        token.mint(user1, amount);

        vm.prank(user1);
        token.transfer(user2, amount / 2);

        assertEq(token.balanceOf(user1), amount / 2);
        assertEq(token.balanceOf(user2), amount / 2);
    }

    function testFailures() public {
        // Test various failure cases
        vm.expectRevert("Token is paused");
        token.pause();
        token.mint(user1, 100 ether);

        vm.expectRevert("Not enough balance");
        vm.prank(user1);
        token.transfer(user2, 100 ether);
    }
}
