// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

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
    function run() external {
        // Get the address that will be executing the deployment
        address deployer = msg.sender;
        console.log("Deploying contracts with deployer:", deployer);

        vm.startBroadcast();

        // Deploy InsuranceCore
        console.log("Deploying InsuranceCore...");
        DeployInsuranceCore deployerContract = new DeployInsuranceCore();
        address insuranceCoreAddress = deployerContract.run();
        console.log("InsuranceCore deployed at:", insuranceCoreAddress);

        // Double check roles in InsuranceCore
        InsuranceCore insuranceCore = InsuranceCore(insuranceCoreAddress);
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

        // Deploy RWA contracts
        console.log("Deploying RWA contracts...");
        DeployRWA rwaDeployer = new DeployRWA();
        address rwaFactoryAddress = rwaDeployer.run(deployer);
        console.log("TokenRWAFactory deployed at:", rwaFactoryAddress);

        // Double check roles in TokenRWAFactory
        TokenRWAFactory factory = TokenRWAFactory(rwaFactoryAddress);
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

        // Deploy implementation contract if not already deployed
        if (address(factory.implementation()) == address(0)) {
            console.log("Deploying TokenRWA implementation...");
            factory.deployImplementation();
            console.log("TokenRWA implementation deployed");
        }

        console.log(
            "All deployments and role assignments completed successfully!"
        );

        vm.stopBroadcast();
    }
}
