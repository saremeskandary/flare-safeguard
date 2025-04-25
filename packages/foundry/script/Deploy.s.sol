// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "./DeployInsuranceCore.s.sol";
import "./DeployHelpers.s.sol";
import {DeployClaimProcessor} from "./DeployClaimProcessor.s.sol";
import "../contracts/TokenRWAFactory.sol";
import "../contracts/InsuranceCore.sol";
import "../contracts/DataVerification.sol";

/**
 * @notice Main deployment script for all contracts
 * @dev Run this when you want to deploy multiple contracts at once
 * Ensures deployer has admin roles in all contracts
 *
 * Example: yarn deploy # runs this script(without`--file` flag)
 */
contract Deploy is Script {
    function setUp() public {}

    function run() public {
        // Get the address that will be executing the deployment
        address deployer = msg.sender;
        console.log("=== Starting Deployment Process ===");
        console.log("Deployer address:", deployer);

        vm.startBroadcast();

        // Deploy InsuranceCore
        console.log("\n=== Deploying InsuranceCore ===");
        DeployInsuranceCore deployerContract = new DeployInsuranceCore();
        address insuranceCoreAddress = deployerContract.runWithBroadcast(false);
        console.log("InsuranceCore deployed at:", insuranceCoreAddress);

        // Double check roles in InsuranceCore
        InsuranceCore insuranceCore = InsuranceCore(insuranceCoreAddress);
        console.log("\n=== Verifying InsuranceCore Roles ===");
        if (
            !insuranceCore.hasRole(insuranceCore.DEFAULT_ADMIN_ROLE(), deployer)
        ) {
            console.log(
                "Granting DEFAULT_ADMIN_ROLE in InsuranceCore to deployer..."
            );
            insuranceCore.grantRole(
                insuranceCore.DEFAULT_ADMIN_ROLE(),
                deployer
            );
        }
        if (!insuranceCore.hasRole(insuranceCore.ADMIN_ROLE(), deployer)) {
            console.log("Granting ADMIN_ROLE in InsuranceCore to deployer...");
            insuranceCore.grantRole(insuranceCore.ADMIN_ROLE(), deployer);
        }
        if (!insuranceCore.hasRole(insuranceCore.EVALUATOR_ROLE(), deployer)) {
            console.log(
                "Granting EVALUATOR_ROLE in InsuranceCore to deployer..."
            );
            insuranceCore.grantRole(insuranceCore.EVALUATOR_ROLE(), deployer);
        }

        // Verify InsuranceCore roles after granting
        require(
            insuranceCore.hasRole(insuranceCore.DEFAULT_ADMIN_ROLE(), deployer),
            "Deployer must have DEFAULT_ADMIN_ROLE in InsuranceCore"
        );
        require(
            insuranceCore.hasRole(insuranceCore.ADMIN_ROLE(), deployer),
            "Deployer must have ADMIN_ROLE in InsuranceCore"
        );
        require(
            insuranceCore.hasRole(insuranceCore.EVALUATOR_ROLE(), deployer),
            "Deployer must have EVALUATOR_ROLE in InsuranceCore"
        );
        console.log("[OK] InsuranceCore roles verified");

        // Deploy DataVerification
        console.log("\n=== Deploying DataVerification ===");
        DataVerification verification = new DataVerification();
        address verificationAddress = address(verification);
        console.log("DataVerification deployed at:", verificationAddress);

        // Deploy TokenRWAFactory
        console.log("\n=== Deploying TokenRWAFactory ===");
        TokenRWAFactory factory = new TokenRWAFactory(verificationAddress);
        address rwaFactoryAddress = address(factory);
        console.log("TokenRWAFactory deployed at:", rwaFactoryAddress);

        // Grant roles to deployer
        console.log("\n=== Setting up TokenRWAFactory Roles ===");
        factory.grantRole(factory.DEFAULT_ADMIN_ROLE(), deployer);
        factory.grantRole(factory.ADMIN_ROLE(), deployer);

        // Verify TokenRWAFactory roles
        require(
            factory.hasRole(factory.DEFAULT_ADMIN_ROLE(), deployer),
            "Deployer must have DEFAULT_ADMIN_ROLE in TokenRWAFactory"
        );
        require(
            factory.hasRole(factory.ADMIN_ROLE(), deployer),
            "Deployer must have ADMIN_ROLE in TokenRWAFactory"
        );
        console.log("[OK] TokenRWAFactory roles verified");

        // Deploy implementation contract
        console.log("\n=== Deploying TokenRWA Implementation ===");
        // Switch to deployer context for implementation deployment
        vm.stopBroadcast();
        vm.startBroadcast(deployer);

        factory.deployImplementation();
        console.log("TokenRWA implementation deployed");
        require(
            address(factory.implementation()) != address(0),
            "TokenRWA implementation deployment failed"
        );
        console.log("[OK] TokenRWA implementation verified");

        console.log("\n=== Deployment Summary ===");
        console.log("InsuranceCore:", insuranceCoreAddress);
        console.log("DataVerification:", verificationAddress);
        console.log("TokenRWAFactory:", rwaFactoryAddress);
        console.log(
            "TokenRWA Implementation:",
            address(factory.implementation())
        );
        console.log("Deployer:", deployer);
        console.log("All roles verified and contracts deployed successfully!");
        console.log("========================");

        vm.stopBroadcast();
    }
}
