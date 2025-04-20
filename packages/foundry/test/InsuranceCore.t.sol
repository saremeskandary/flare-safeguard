// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/InsuranceCore.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

contract InsuranceCoreTest is Test {
    InsuranceCore public insuranceCore;
    address public admin;
    address public evaluator;
    address public user;
    address public mockToken;

    event CoverageOptionAdded(
        uint256 indexed optionId,
        uint256 coverageLimit,
        uint256 premiumRate
    );
    event RWAEvaluated(address indexed token, uint256 value, uint256 riskScore);

    error AccessControlUnauthorizedAccount(address account, bytes32 role);

    function setUp() public {
        admin = address(this);
        evaluator = address(0x1);
        user = address(0x2);
        mockToken = address(0x3);

        insuranceCore = new InsuranceCore();

        // Grant evaluator role to evaluator address
        insuranceCore.grantRole(insuranceCore.EVALUATOR_ROLE(), evaluator);
    }

    function testAddCoverageOption() public {
        uint256 coverageLimit = 1000 ether;
        uint256 premiumRate = 100; // 1%
        uint256 minDuration = 30 days;
        uint256 maxDuration = 365 days;

        vm.expectEmit(true, true, true, true);
        emit CoverageOptionAdded(0, coverageLimit, premiumRate);

        insuranceCore.addCoverageOption(
            coverageLimit,
            premiumRate,
            minDuration,
            maxDuration
        );

        (
            uint256 limit,
            uint256 rate,
            uint256 minDur,
            uint256 maxDur,
            bool isActive
        ) = insuranceCore.getCoverageOption(0);

        assertEq(limit, coverageLimit);
        assertEq(rate, premiumRate);
        assertEq(minDur, minDuration);
        assertEq(maxDur, maxDuration);
        assertTrue(isActive);
    }

    function testEvaluateRWA() public {
        uint256 value = 1000 ether;
        uint256 riskScore = 50;

        vm.prank(evaluator);
        vm.expectEmit(true, true, true, true);
        emit RWAEvaluated(mockToken, value, riskScore);

        insuranceCore.evaluateRWA(mockToken, value, riskScore);

        (
            uint256 evalValue,
            uint256 score,
            uint256 lastUpdated,
            bool isValid
        ) = insuranceCore.getRWAEvaluation(mockToken);

        assertEq(evalValue, value);
        assertEq(score, riskScore);
        assertTrue(isValid);
        assertEq(lastUpdated, block.timestamp);
    }

    function testCalculatePremium() public {
        // Add coverage option
        insuranceCore.addCoverageOption(
            1000 ether,
            100, // 1%
            30 days,
            365 days
        );

        // Evaluate RWA token
        vm.prank(evaluator);
        insuranceCore.evaluateRWA(mockToken, 1000 ether, 50);

        // Calculate premium
        uint256 coverageAmount = 500 ether;
        uint256 duration = 180 days;
        uint256 premium = insuranceCore.calculatePremium(
            coverageAmount,
            duration,
            mockToken
        );

        // Expected premium: 500 * 0.01 * (1 + 0.5) = 7.5 ether
        assertEq(premium, 7.5 ether);
    }

    function test_RevertWhen_UnauthorizedAddCoverageOption() public {
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                user,
                insuranceCore.ADMIN_ROLE()
            )
        );
        insuranceCore.addCoverageOption(1000 ether, 100, 30 days, 365 days);
        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedEvaluateRWA() public {
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                user,
                insuranceCore.EVALUATOR_ROLE()
            )
        );
        insuranceCore.evaluateRWA(mockToken, 1000 ether, 50);
        vm.stopPrank();
    }

    function test_RevertWhen_CalculatePremiumInvalidToken() public {
        uint256 coverageAmount = 500 ether;
        uint256 duration = 180 days;
        vm.expectRevert("Token not evaluated");
        insuranceCore.calculatePremium(coverageAmount, duration, mockToken);
    }

    function test_RevertWhen_CalculatePremiumNoSuitableOption() public {
        // Evaluate RWA token
        vm.prank(evaluator);
        insuranceCore.evaluateRWA(mockToken, 1000 ether, 50);

        // Try to calculate premium with amount exceeding coverage limit
        uint256 coverageAmount = 2000 ether;
        uint256 duration = 180 days;
        vm.expectRevert("No suitable coverage option");
        insuranceCore.calculatePremium(coverageAmount, duration, mockToken);
    }
}
