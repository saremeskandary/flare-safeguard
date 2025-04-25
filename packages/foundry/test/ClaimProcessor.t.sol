// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ClaimProcessor.sol";
import "./mocks/MockBSDToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClaimProcessorTest is Test {
    ClaimProcessor public claimProcessor;
    MockBSDToken public mockToken;
    address public owner;
    address public user;

    event PolicyCreated(
        address indexed insured,
        address indexed token,
        uint256 coverageAmount
    );
    event ClaimSubmitted(
        uint256 indexed claimId,
        address indexed insured,
        uint256 amount
    );
    event ClaimStatusUpdated(
        uint256 indexed claimId,
        ClaimProcessor.ClaimStatus status
    );
    event ClaimPaid(
        uint256 indexed claimId,
        address indexed insured,
        uint256 amount
    );

    error PremiumTransferFailed();
    error NoActivePolicy();
    error InvalidClaimStatus();
    error ClaimNotApproved();
    error InsufficientBalance();

    function setUp() public {
        owner = address(this);
        user = address(0x2);
        mockToken = new MockBSDToken();
        claimProcessor = new ClaimProcessor(address(mockToken));

        // Mint tokens to user
        mockToken.mint(user, 1000 ether);
    }

    function testCreatePolicy() public {
        vm.startPrank(user);
        mockToken.approve(address(claimProcessor), 100 ether);

        vm.expectEmit(true, true, true, true);
        emit PolicyCreated(user, address(mockToken), 1000 ether);

        claimProcessor.createPolicy(
            address(mockToken),
            1000 ether,
            100 ether,
            180 days
        );

        (
            address insured,
            address token,
            uint256 coverageAmount,
            uint256 premium,
            uint256 startTime,
            uint256 endTime,
            bool isActive
        ) = claimProcessor.policies(user);

        assertEq(insured, user);
        assertEq(token, address(mockToken));
        assertEq(coverageAmount, 1000 ether);
        assertEq(premium, 100 ether);
        assertTrue(startTime > 0);
        assertTrue(endTime > startTime);
        assertTrue(isActive);
        vm.stopPrank();
    }

    function test_RevertWhen_CreatePolicyWithoutAllowance() public {
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientAllowance(address,uint256,uint256)",
                address(claimProcessor),
                0,
                100 ether
            )
        );
        claimProcessor.createPolicy(
            address(mockToken),
            1000 ether,
            100 ether,
            180 days
        );
    }

    function testSubmitClaim() public {
        vm.startPrank(user);
        mockToken.approve(address(claimProcessor), 100 ether);
        claimProcessor.createPolicy(
            address(mockToken),
            1000 ether,
            100 ether,
            180 days
        );

        vm.expectEmit(true, true, true, true);
        emit ClaimSubmitted(0, user, 500 ether);

        claimProcessor.submitClaim(500 ether, "Test claim");

        (
            address insured,
            address tokenAddress,
            uint256 amount,
            ,
            string memory description,
            ClaimProcessor.ClaimStatus status,
            address verifier_,
            string memory rejectionReason
        ) = claimProcessor.claims(0);

        assertEq(insured, user);
        assertEq(tokenAddress, address(mockToken));
        assertEq(amount, 500 ether);
        assertEq(description, "Test claim");
        assertEq(uint8(status), uint8(ClaimProcessor.ClaimStatus.Pending));
        assertEq(verifier_, address(0));
        assertEq(rejectionReason, "");
        vm.stopPrank();
    }

    function test_RevertWhen_SubmitClaimWithoutPolicy() public {
        vm.prank(user);
        vm.expectRevert("No active policy");
        claimProcessor.submitClaim(500 ether, "Test claim");
    }

    function testReviewClaim() public {
        vm.startPrank(user);
        mockToken.approve(address(claimProcessor), 100 ether);
        claimProcessor.createPolicy(
            address(mockToken),
            1000 ether,
            100 ether,
            180 days
        );
        claimProcessor.submitClaim(500 ether, "Test claim");
        vm.stopPrank();

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit ClaimStatusUpdated(0, ClaimProcessor.ClaimStatus.Approved);
        claimProcessor.reviewClaim(0, true, "");

        (
            ,
            ,
            ,
            ,
            ,
            ClaimProcessor.ClaimStatus status,
            address verifier_,
            string memory rejectionReason
        ) = claimProcessor.claims(0);

        assertEq(uint8(status), uint8(ClaimProcessor.ClaimStatus.Approved));
        assertEq(verifier_, owner);
        assertEq(rejectionReason, "");
    }

    function test_RevertWhen_ReviewNonExistentClaim() public {
        // Create a claim first to ensure claimCount is initialized
        vm.startPrank(user);
        mockToken.approve(address(claimProcessor), 100 ether);
        claimProcessor.createPolicy(
            address(mockToken),
            1000 ether,
            100 ether,
            180 days
        );
        claimProcessor.submitClaim(500 ether, "Test claim");
        vm.stopPrank();

        // Review the claim
        vm.prank(owner);
        claimProcessor.reviewClaim(0, true, "");

        // Now try to review the same claim again, which should fail
        vm.expectRevert("Invalid claim status");
        claimProcessor.reviewClaim(0, true, "");
    }

    function testProcessPayout() public {
        // Create policy and submit claim
        vm.startPrank(user);
        mockToken.approve(address(claimProcessor), 1000 ether);
        claimProcessor.createPolicy(
            address(mockToken),
            1000 ether,
            100 ether,
            180 days
        );
        claimProcessor.submitClaim(500 ether, "Test claim");
        vm.stopPrank();

        // Review and approve claim
        vm.startPrank(owner);
        claimProcessor.reviewClaim(0, true, "");
        vm.stopPrank();

        // Mint tokens to contract for payout
        mockToken.mint(address(claimProcessor), 500 ether);

        // Process payout and verify event
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit ClaimPaid(0, user, 500 ether);
        claimProcessor.processClaimPayout(0);
        vm.stopPrank();

        // Verify claim state after payout
        (
            address insured,
            address tokenAddress,
            uint256 amount,
            ,
            string memory description,
            ClaimProcessor.ClaimStatus status,
            address verifier_,
            string memory rejectionReason
        ) = claimProcessor.claims(0);

        assertEq(insured, user);
        assertEq(tokenAddress, address(mockToken));
        assertEq(amount, 500 ether);
        assertEq(description, "Test claim");
        assertEq(uint8(status), uint8(ClaimProcessor.ClaimStatus.Paid));
        assertEq(verifier_, owner);
        assertEq(rejectionReason, "");
    }

    function test_RevertWhen_ProcessPayoutForUnapprovedClaim() public {
        // Create policy and submit claim
        vm.startPrank(user);
        mockToken.approve(address(claimProcessor), 1000 ether);
        claimProcessor.createPolicy(
            address(mockToken),
            1000 ether,
            100 ether,
            180 days
        );
        claimProcessor.submitClaim(500 ether, "Test claim");
        vm.stopPrank();

        // Try to process payout without approval
        vm.startPrank(owner);
        vm.expectRevert("Claim not approved");
        claimProcessor.processClaimPayout(0);
        vm.stopPrank();
    }
}
