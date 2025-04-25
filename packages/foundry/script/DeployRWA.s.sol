// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";
import "../contracts/DataVerification.sol";
import "../contracts/TokenRWA.sol";
import "../contracts/TokenRWAFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DeployRWA
 * @dev Script to deploy the RWA contracts for Flare
 */
contract DeployRWA is Script {
    function run(address deployer) external returns (address) {
        console.log("Deploying DataVerification contract...");
        // Deploy DataVerification contract
        DataVerification verification = new DataVerification();
        console.log("DataVerification deployed at:", address(verification));

        console.log("Deploying TokenRWAFactory contract...");
        // Deploy TokenRWAFactory with verification contract address
        TokenRWAFactory factory = new TokenRWAFactory(address(verification));
        console.log("TokenRWAFactory deployed at:", address(factory));

        // Grant roles to this contract for deployment
        console.log("Granting roles to DeployRWA contract...");
        factory.grantRole(factory.DEFAULT_ADMIN_ROLE(), address(this));
        factory.grantRole(factory.ADMIN_ROLE(), address(this));
        console.log("Granted roles to DeployRWA contract at:", address(this));

        // Grant roles to deployer
        console.log("Granting roles to deployer...");
        factory.grantRole(factory.DEFAULT_ADMIN_ROLE(), deployer);
        factory.grantRole(factory.ADMIN_ROLE(), deployer);
        console.log("Granted roles to deployer at:", deployer);

        // Deploy implementation contract
        console.log("Deploying TokenRWA implementation...");
        factory.deployImplementation();
        console.log("TokenRWA implementation deployed");

        return address(factory);
    }
}
