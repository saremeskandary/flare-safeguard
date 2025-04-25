// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../contracts/TokenRWAFactory.sol";
import "../contracts/TokenRWA.sol";
import "../contracts/DataVerification.sol";

/**
 * @title DeployRWA
 * @dev Script to deploy the RWA contracts for Flare
 */
contract DeployRWA is Script {
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

        // Deploy DataVerification contract
        console2.log("Deploying DataVerification contract...");
        DataVerification dataVerification = new DataVerification();
        console2.log(
            "DataVerification deployed at: %s",
            address(dataVerification)
        );

        // Deploy TokenRWAFactory
        console2.log("Deploying TokenRWAFactory...");
        TokenRWAFactory factory = new TokenRWAFactory(
            address(dataVerification)
        );
        console2.log("TokenRWAFactory deployed at: %s", address(factory));

        // Deploy implementation contract
        console2.log("Deploying TokenRWA implementation...");
        factory.deployImplementation();
        console2.log(
            "TokenRWA implementation deployed at: %s",
            address(factory.implementation())
        );

        // Log deployment summary
        console2.log("\n=== RWA Deployment Summary ===");
        console2.log("DataVerification: %s", address(dataVerification));
        console2.log("TokenRWAFactory: %s", address(factory));
        console2.log(
            "TokenRWA Implementation: %s",
            address(factory.implementation())
        );
        console2.log("Deployer: %s", deployer);

        if (startBroadcast) {
            vm.stopBroadcast();
        }
        return address(factory);
    }
}
