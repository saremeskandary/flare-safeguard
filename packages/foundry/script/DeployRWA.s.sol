// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../contracts/DeploymentManager.sol";
import "../contracts/libraries/DeploymentHelper.sol";

/**
 * @title DeployRWA
 * @dev Script to deploy the RWA contracts for Flare
 */
contract DeployRWA is Script {
    using DeploymentHelper for *;

    error DeploymentVerificationFailed();

    function setUp() public {}

    function run() public returns (address) {
        return runWithBroadcast(true, address(0));
    }

    function runWithBroadcast(bool startBroadcast) public returns (address) {
        return runWithBroadcast(startBroadcast, address(0));
    }

    function runWithBroadcast(
        bool startBroadcast,
        address deployer
    ) public returns (address) {
        if (startBroadcast) {
            vm.startBroadcast();
        }

        console2.log("=== Starting RWA Deployment ===");

        // Deploy the deployment manager
        DeploymentManager manager = new DeploymentManager();
        console2.log("DeploymentManager deployed at: %s", address(manager));

        // Step 1: Deploy core contracts
        console2.log("\n=== Deploying Core Contracts ===");
        DeploymentManager.DeploymentInfo memory info = manager
            .deployCoreContracts();

        // If deployer is provided, use it instead of msg.sender
        if (deployer != address(0)) {
            info.deployer = deployer;
        }

        console2.log("DataVerification deployed at: %s", info.dataVerification);
        console2.log("RoleManager deployed at: %s", info.roleManager);

        // Step 2: Deploy factory
        console2.log("\n=== Deploying TokenRWAFactory ===");
        info = manager.deployFactory(info);
        console2.log("TokenRWAFactory deployed at: %s", info.factory);

        // Step 3: Setup roles and implementation
        console2.log("\n=== Setting up Roles and Implementation ===");
        info = manager.setupRolesAndImplementation(info);
        console2.log(
            "TokenRWA Implementation deployed at: %s",
            info.implementation
        );

        // Verify deployment
        if (
            !DeploymentHelper.verifyDeployment(
                TokenRWAFactory(info.factory),
                info.deployer
            )
        ) {
            revert DeploymentVerificationFailed();
        }

        // Log deployment summary
        console2.log("\n=== RWA Deployment Summary ===");
        console2.log("DataVerification: %s", info.dataVerification);
        console2.log("RoleManager: %s", info.roleManager);
        console2.log("TokenRWAFactory: %s", info.factory);
        console2.log("TokenRWA Implementation: %s", info.implementation);
        console2.log("Deployer: %s", info.deployer);
        console2.log("========================");

        if (startBroadcast) {
            vm.stopBroadcast();
        }
        return info.factory;
    }
}
