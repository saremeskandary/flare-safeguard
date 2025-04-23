// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";
import "./DeployInsuranceCore.s.sol";
import "./DeployHelpers.s.sol";
import { DeployClaimProcessor } from "./DeployClaimProcessor.s.sol";
/**
 * @notice Main deployment script for all contracts
 * @dev Run this when you want to deploy multiple contracts at once
 *
 * Example: yarn deploy # runs this script(without`--file` flag)
 */
contract Deploy is Script {
    function run() external {
        // Deploy InsuranceCore
        DeployInsuranceCore deployer = new DeployInsuranceCore();
        address insuranceCoreAddress = deployer.run();

        console.log(
            "Deployment completed. InsuranceCore address:",
            insuranceCoreAddress
        );
    }
}
