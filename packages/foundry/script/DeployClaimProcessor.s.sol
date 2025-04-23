// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./DeployHelpers.s.sol";
import "../contracts/ClaimProcessor.sol";
import "../contracts/InsuranceCore.sol";
import "../test/mocks/MockBSDToken.sol";

/**
 * @notice Deployment script for the ClaimProcessor contract
 */
contract DeployClaimProcessor is ScaffoldETHDeploy {
    function run() external {
        console.log(
            "Starting ClaimProcessor deployment with deployer:",
            deployer
        );

        // Check if InsuranceCore is already deployed
        address insuranceCoreAddress;
        bool foundInsuranceCore = false;

        for (uint i = 0; i < deployments.length; i++) {
            if (
                keccak256(bytes(deployments[i].name)) ==
                keccak256(bytes("InsuranceCore"))
            ) {
                insuranceCoreAddress = deployments[i].addr;
                foundInsuranceCore = true;
                break;
            }
        }

        require(foundInsuranceCore, "InsuranceCore not found in deployments");
        console.log("Using InsuranceCore at:", insuranceCoreAddress);
        InsuranceCore(insuranceCoreAddress);

        // Deploy ClaimProcessor
        ClaimProcessor claimProcessor = new ClaimProcessor(
            insuranceCoreAddress
        );
        console.log("ClaimProcessor deployed at:", address(claimProcessor));
        deployments.push(Deployment("ClaimProcessor", address(claimProcessor)));

        // Grant roles to deployer
        console.log(
            "Granting DEFAULT_ADMIN_ROLE to deployer on ClaimProcessor..."
        );
        claimProcessor.grantRole(claimProcessor.DEFAULT_ADMIN_ROLE(), deployer);

        console.log("Granting ADMIN_ROLE on ClaimProcessor...");
        claimProcessor.grantRole(claimProcessor.ADMIN_ROLE(), deployer);

        console.log("Granting VERIFIER_ROLE on ClaimProcessor...");
        claimProcessor.grantRole(claimProcessor.VERIFIER_ROLE(), deployer);

        console.log("ClaimProcessor deployment completed successfully!");
    }

    function runWithInsuranceCore(address insuranceCoreAddress) external {
        console.log(
            "Starting ClaimProcessor deployment with deployer:",
            deployer
        );

        require(
            insuranceCoreAddress != address(0),
            "Invalid InsuranceCore address"
        );
        console.log("Using InsuranceCore at:", insuranceCoreAddress);
        InsuranceCore(insuranceCoreAddress);

        // Deploy ClaimProcessor
        ClaimProcessor claimProcessor = new ClaimProcessor(
            insuranceCoreAddress
        );
        console.log("ClaimProcessor deployed at:", address(claimProcessor));
        deployments.push(Deployment("ClaimProcessor", address(claimProcessor)));

        // Grant roles to deployer
        console.log(
            "Granting DEFAULT_ADMIN_ROLE to deployer on ClaimProcessor..."
        );
        claimProcessor.grantRole(claimProcessor.DEFAULT_ADMIN_ROLE(), deployer);

        console.log("Granting ADMIN_ROLE on ClaimProcessor...");
        claimProcessor.grantRole(claimProcessor.ADMIN_ROLE(), deployer);

        console.log("Granting VERIFIER_ROLE on ClaimProcessor...");
        claimProcessor.grantRole(claimProcessor.VERIFIER_ROLE(), deployer);

        console.log("ClaimProcessor deployment completed successfully!");
    }
}
