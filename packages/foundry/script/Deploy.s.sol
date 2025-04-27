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

    function deployInsuranceCore(address deployer) internal returns (address) {
        console.log("\n=== Deploying InsuranceCore ===");
        DeployInsuranceCore deployerContract = new DeployInsuranceCore();
        address insuranceCoreAddress = deployerContract.runWithBroadcast(false);
        console.log("InsuranceCore deployed at:", insuranceCoreAddress);

        InsuranceCore insuranceCore = InsuranceCore(insuranceCoreAddress);

        // Grant roles
        if (
            !insuranceCore.hasRole(insuranceCore.DEFAULT_ADMIN_ROLE(), deployer)
        ) {
            insuranceCore.grantRole(
                insuranceCore.DEFAULT_ADMIN_ROLE(),
                deployer
            );
        }
        if (!insuranceCore.hasRole(insuranceCore.ADMIN_ROLE(), deployer)) {
            insuranceCore.grantRole(insuranceCore.ADMIN_ROLE(), deployer);
        }
        if (!insuranceCore.hasRole(insuranceCore.EVALUATOR_ROLE(), deployer)) {
            insuranceCore.grantRole(insuranceCore.EVALUATOR_ROLE(), deployer);
        }

        // Verify roles
        require(
            insuranceCore.hasRole(insuranceCore.DEFAULT_ADMIN_ROLE(), deployer),
            "DEFAULT_ADMIN_ROLE missing"
        );
        require(
            insuranceCore.hasRole(insuranceCore.ADMIN_ROLE(), deployer),
            "ADMIN_ROLE missing"
        );
        require(
            insuranceCore.hasRole(insuranceCore.EVALUATOR_ROLE(), deployer),
            "EVALUATOR_ROLE missing"
        );

        console.log("InsuranceCore Admin Addresses:");
        console.log("DEFAULT_ADMIN_ROLE:", deployer);
        console.log("ADMIN_ROLE:", deployer);
        console.log("EVALUATOR_ROLE:", deployer);

        return insuranceCoreAddress;
    }

    function deployDataVerification() internal returns (address) {
        console.log("\n=== Deploying DataVerification ===");
        DataVerification verification = new DataVerification();
        address verificationAddress = address(verification);
        console.log("DataVerification deployed at:", verificationAddress);
        return verificationAddress;
    }

    function deployTokenRWAFactory(
        address verificationAddress,
        address deployer
    ) internal returns (address) {
        console.log("\n=== Deploying TokenRWAFactory ===");
        TokenRWAFactory factory = new TokenRWAFactory(verificationAddress);
        address rwaFactoryAddress = address(factory);
        console.log("TokenRWAFactory deployed at:", rwaFactoryAddress);

        // Grant roles with explicit verification
        if (!factory.hasRole(factory.DEFAULT_ADMIN_ROLE(), deployer)) {
            factory.grantRole(factory.DEFAULT_ADMIN_ROLE(), deployer);
            require(
                factory.hasRole(factory.DEFAULT_ADMIN_ROLE(), deployer),
                "Failed to grant DEFAULT_ADMIN_ROLE"
            );
        }

        if (!factory.hasRole(factory.ADMIN_ROLE(), deployer)) {
            factory.grantRole(factory.ADMIN_ROLE(), deployer);
            require(
                factory.hasRole(factory.ADMIN_ROLE(), deployer),
                "Failed to grant ADMIN_ROLE"
            );
        }

        // Double-check roles after granting
        require(
            factory.hasRole(factory.DEFAULT_ADMIN_ROLE(), deployer),
            "DEFAULT_ADMIN_ROLE verification failed"
        );
        require(
            factory.hasRole(factory.ADMIN_ROLE(), deployer),
            "ADMIN_ROLE verification failed"
        );

        console.log("TokenRWAFactory Admin Addresses:");
        console.log("DEFAULT_ADMIN_ROLE:", deployer);
        console.log("ADMIN_ROLE:", deployer);

        return rwaFactoryAddress;
    }

    function deployTokenRWAImplementation(
        address rwaFactoryAddress,
        address deployer
    ) internal {
        console.log("\n=== Deploying TokenRWA Implementation ===");
        TokenRWAFactory factory = TokenRWAFactory(rwaFactoryAddress);

        vm.stopBroadcast();
        vm.startBroadcast(deployer);

        factory.deployImplementation();
        console.log("TokenRWA implementation deployed");
        require(
            address(factory.implementation()) != address(0),
            "Implementation deployment failed"
        );
        console.log(
            "TokenRWA Implementation:",
            address(factory.implementation())
        );
    }

    function run() public {
        // Get the deployer address from the default signer
        address deployer = msg.sender;

        console.log("=== Starting Deployment Process ===");
        console.log("Deployer address:", deployer);

        vm.startBroadcast();

        // Deploy contracts in sequence
        address insuranceCoreAddress = deployInsuranceCore(deployer);
        address verificationAddress = deployDataVerification();
        address rwaFactoryAddress = deployTokenRWAFactory(
            verificationAddress,
            deployer
        );
        deployTokenRWAImplementation(rwaFactoryAddress, deployer);

        console.log("\n=== Deployment Summary ===");
        console.log("InsuranceCore:", insuranceCoreAddress);
        console.log("DataVerification:", verificationAddress);
        console.log("TokenRWAFactory:", rwaFactoryAddress);
        console.log("Deployer:", deployer);
        console.log("All contracts deployed successfully!");
        console.log("========================");

        vm.stopBroadcast();
    }
}
