// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../contracts/DeploymentManager.sol";
import "../contracts/libraries/RWADeploymentLib.sol";

/**
 * @title DeployRWA
 * @dev Script to deploy the RWA contracts for Flare
 */
contract DeployRWA is Script {
    using RWADeploymentLib for *;

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

        // Deploy the deployment manager
        DeploymentManager manager = new DeploymentManager();
        console2.log("DeploymentManager deployed at: %s", address(manager));

        // Deploy RWA contracts using the library
        DeploymentManager.DeploymentInfo memory info = RWADeploymentLib
            .deployRWA(manager, deployer);

        // Log deployment summary
        console2.log("\n=== RWA Deployment Summary ===");
        console2.log("DataVerification: %s", info.dataVerification);
        console2.log("RoleManager: %s", info.roleManager);
        console2.log("TokenRWAFactory: %s", info.factory);
        console2.log("TokenRWA Implementation: %s", info.implementation);
        console2.log("Deployer: %s", info.deployer);

        if (startBroadcast) {
            vm.stopBroadcast();
        }
        return info.factory;
    }
}
