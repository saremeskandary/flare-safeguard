// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./DeployHelpers.s.sol";
import "../contracts/ClaimProcessor.sol";
import "../contracts/InsuranceCore.sol";
import "../test/mocks/MockBSDToken.sol";

/**
 * @notice Seed script for populating contracts with mock data
 * @dev This script deploys contracts and populates them with mock data for testing
 * Example:
 * yarn deploy --file SeedContracts.s.sol  # local anvil chain
 */
contract SeedContracts is ScaffoldETHDeploy {
    // User address for testing
    address constant USER_ADDRESS = 0x248dcc886995dd097Dc47b8561584D6479cF7772;

    // Token addresses for testing
    address constant TOKEN_1 = 0x1234567890123456789012345678901234567890;
    address constant TOKEN_2 = 0x0987654321098765432109876543210987654321;

    function run() external ScaffoldEthDeployerRunner {
        // Deploy mock token for testing
        MockBSDToken mockToken = new MockBSDToken();
        console.log("MockBSDToken deployed at:", address(mockToken));

        // Mint tokens to deployer and user
        mockToken.mint(deployer, 1000000 ether);
        mockToken.mint(USER_ADDRESS, 1000000 ether);
        console.log("Minted tokens to deployer and user");

        // Deploy InsuranceCore
        InsuranceCore insuranceCore = new InsuranceCore();
        console.log("InsuranceCore deployed at:", address(insuranceCore));

        // Add coverage options
        insuranceCore.addCoverageOption(
            100000 ether, // coverageLimit
            100, // premiumRate (1%)
            30 days, // minDuration
            365 days // maxDuration
        );

        insuranceCore.addCoverageOption(
            500000 ether, // coverageLimit
            150, // premiumRate (1.5%)
            90 days, // minDuration
            730 days // maxDuration
        );

        console.log("Added coverage options to InsuranceCore");

        // Evaluate RWA tokens
        insuranceCore.evaluateRWA(
            TOKEN_1,
            100000 ether, // value
            50 // riskScore (medium risk)
        );

        insuranceCore.evaluateRWA(
            TOKEN_2,
            500000 ether, // value
            30 // riskScore (low risk)
        );

        console.log("Evaluated RWA tokens");

        // Deploy ClaimProcessor
        ClaimProcessor claimProcessor = new ClaimProcessor(address(mockToken));
        console.log("ClaimProcessor deployed at:", address(claimProcessor));

        // Grant roles to deployer
        claimProcessor.grantRole(claimProcessor.ADMIN_ROLE(), deployer);
        claimProcessor.grantRole(claimProcessor.VERIFIER_ROLE(), deployer);
        console.log("Granted roles to deployer");

        // Approve tokens for the user
        mockToken.approve(address(claimProcessor), 1000000 ether);

        // Create policies for the user
        // Policy 1: 75% coverage of TOKEN_1 for 1 year
        uint256 coverageAmount1 = 75000 ether;
        uint256 premium1 = insuranceCore.calculatePremium(
            coverageAmount1,
            365 days,
            TOKEN_1
        );

        // Transfer premium from user to claim processor
        vm.prank(USER_ADDRESS);
        mockToken.transfer(address(claimProcessor), premium1);

        // Create policy
        vm.prank(USER_ADDRESS);
        claimProcessor.createPolicy(
            TOKEN_1,
            coverageAmount1,
            premium1,
            365 days
        );

        console.log("Created policy 1 for user");

        // Policy 2: 90% coverage of TOKEN_2 for 2 years
        uint256 coverageAmount2 = 450000 ether;
        uint256 premium2 = insuranceCore.calculatePremium(
            coverageAmount2,
            730 days,
            TOKEN_2
        );

        // Transfer premium from user to claim processor
        vm.prank(USER_ADDRESS);
        mockToken.transfer(address(claimProcessor), premium2);

        // Create policy
        vm.prank(USER_ADDRESS);
        claimProcessor.createPolicy(
            TOKEN_2,
            coverageAmount2,
            premium2,
            730 days
        );

        console.log("Created policy 2 for user");

        // Submit a claim for policy 1
        vm.prank(USER_ADDRESS);
        claimProcessor.submitClaim(
            50000 ether, // amount
            "Damage to property" // description
        );

        console.log("Submitted claim for policy 1");

        // Review and approve the claim
        claimProcessor.reviewClaim(
            0, // claimId
            true, // approved
            "" // reason (empty for approved claims)
        );

        console.log("Approved claim for policy 1");

        // Process payout for the claim
        vm.prank(deployer);
        claimProcessor.processClaimPayout(0);

        console.log("Processed payout for claim 0");

        // Submit another claim for policy 1
        vm.prank(USER_ADDRESS);
        claimProcessor.submitClaim(
            25000 ether, // amount
            "Additional damage" // description
        );

        console.log("Submitted claim for policy 1");

        // Review and approve the claim
        claimProcessor.reviewClaim(
            1, // claimId
            true, // approved
            "" // reason (empty for approved claims)
        );

        console.log("Approved claim for policy 1");

        // Process payout for the claim
        vm.prank(deployer);
        claimProcessor.processClaimPayout(1);

        console.log("Processed payout for claim 1");

        console.log("Seed completed successfully!");
    }
}
