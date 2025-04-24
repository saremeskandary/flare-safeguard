// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/DataVerification.sol";
import "../src/TokenRWA.sol";
import "../src/TokenRWAFactory.sol";

/**
 * @title DeployRWA
 * @dev Script to deploy the RWA contracts for Flare
 */
contract DeployRWA is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy DataVerification contract
        DataVerification verification = new DataVerification();
        console.log("DataVerification deployed at:", address(verification));

        // Deploy TokenRWAFactory with verification contract address
        TokenRWAFactory factory = new TokenRWAFactory(address(verification));
        console.log("TokenRWAFactory deployed at:", address(factory));

        // Deploy implementation contract
        factory.deployImplementation();
        console.log("TokenRWA implementation deployed");

        vm.stopBroadcast();
    }
}
