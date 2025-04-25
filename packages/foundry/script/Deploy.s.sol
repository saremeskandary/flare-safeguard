// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "./DeployInsuranceCore.s.sol";
import "./DeployHelpers.s.sol";
import {DeployClaimProcessor} from "./DeployClaimProcessor.s.sol";
import "./DeployRWA.s.sol";
import "../contracts/TokenRWAFactory.sol";
import "../contracts/InsuranceCore.sol";

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

        // Deploy RWA contracts
        console.log("\n=== Deploying RWA Contracts ===");
        DeployRWA rwaDeployer = new DeployRWA();
        address rwaFactoryAddress = rwaDeployer.runWithBroadcast(
            false,
            deployer
        );
        console.log("TokenRWAFactory deployed at:", rwaFactoryAddress);

        // Double check roles in TokenRWAFactory
        TokenRWAFactory factory = TokenRWAFactory(rwaFactoryAddress);
        console.log("\n=== Verifying TokenRWAFactory Roles ===");
        if (!factory.hasRole(factory.DEFAULT_ADMIN_ROLE(), deployer)) {
            console.log(
                "Granting DEFAULT_ADMIN_ROLE in TokenRWAFactory to deployer..."
            );
            factory.grantRole(factory.DEFAULT_ADMIN_ROLE(), deployer);
        }
        if (!factory.hasRole(factory.ADMIN_ROLE(), deployer)) {
            console.log(
                "Granting ADMIN_ROLE in TokenRWAFactory to deployer..."
            );
            factory.grantRole(factory.ADMIN_ROLE(), deployer);
        }

        // Verify TokenRWAFactory roles after granting
        require(
            factory.hasRole(factory.DEFAULT_ADMIN_ROLE(), deployer),
            "Deployer must have DEFAULT_ADMIN_ROLE in TokenRWAFactory"
        );
        require(
            factory.hasRole(factory.ADMIN_ROLE(), deployer),
            "Deployer must have ADMIN_ROLE in TokenRWAFactory"
        );
        console.log("[OK] TokenRWAFactory roles verified");

        // Deploy implementation contract if not already deployed
        if (address(factory.implementation()) == address(0)) {
            console.log("\n=== Deploying TokenRWA Implementation ===");
            factory.deployImplementation();
            console.log("TokenRWA implementation deployed");
            require(
                address(factory.implementation()) != address(0),
                "TokenRWA implementation deployment failed"
            );
            console.log("[OK] TokenRWA implementation verified");
        }

        console.log("\n=== Deployment Summary ===");
        console.log("InsuranceCore:", insuranceCoreAddress);
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
