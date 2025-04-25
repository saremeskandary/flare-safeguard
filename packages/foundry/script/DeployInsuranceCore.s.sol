// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../contracts/InsuranceCore.sol";

/**
 * @notice Deployment script for the InsuranceCore contract
 */
contract DeployInsuranceCore is Script {
    function run() external returns (address) {
        return runWithBroadcast(true);
    }

    function runWithBroadcast(bool startBroadcast) public returns (address) {
        if (startBroadcast) {
            vm.startBroadcast();
        }

        console.log("Deploying InsuranceCore contract...");
        InsuranceCore insuranceCore = new InsuranceCore();
        console.log("InsuranceCore deployed at:", address(insuranceCore));

        // Add initial coverage options
        console.log("Adding initial coverage options...");

        // Coverage Option 1: Basic Coverage
        try
            insuranceCore.addCoverageOption(
                100_000 ether, // coverageLimit: 100,000 FLR
                100, // premiumRate: 1% (100 basis points)
                30 days, // minDuration
                365 days // maxDuration
            )
        {
            console.log("Basic coverage option added successfully");
        } catch Error(string memory reason) {
            console.log("Failed to add basic coverage option:", reason);
        }

        // Coverage Option 2: Premium Coverage
        try
            insuranceCore.addCoverageOption(
                500_000 ether, // coverageLimit: 500,000 FLR
                150, // premiumRate: 1.5% (150 basis points)
                90 days, // minDuration
                730 days // maxDuration
            )
        {
            console.log("Premium coverage option added successfully");
        } catch Error(string memory reason) {
            console.log("Failed to add premium coverage option:", reason);
        }

        if (startBroadcast) {
            vm.stopBroadcast();
        }
        return address(insuranceCore);
    }
}
