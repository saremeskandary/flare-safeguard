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

        // Deploy RWA contracts
        console.log("\n=== Deploying RWA Contracts ===");
        DeployRWA rwaDeployer = new DeployRWA();
        address rwaFactoryAddress = rwaDeployer.runWithBroadcast(
            false,
            deployer
        );
        console.log("TokenRWAFactory deployed at:", rwaFactoryAddress);

        // Deploy implementation contract if not already deployed
        TokenRWAFactory factory = TokenRWAFactory(rwaFactoryAddress);
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
        console.log("All contracts deployed successfully!");
        console.log("========================");

        vm.stopBroadcast();
    }
}
