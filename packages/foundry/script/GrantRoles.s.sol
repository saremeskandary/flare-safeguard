// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/TokenRWAFactory.sol";

contract GrantRoles is Script {
    function run(address factoryAddress) external {
        address deployer = vm.envAddress("DEPLOYER");
        
        console.log("Granting roles to deployer:", deployer);
        console.log("TokenRWAFactory address:", factoryAddress);
        
        TokenRWAFactory factory = TokenRWAFactory(factoryAddress);
        
        // Grant DEFAULT_ADMIN_ROLE
        factory.grantRole(factory.DEFAULT_ADMIN_ROLE(), deployer);
        require(factory.hasRole(factory.DEFAULT_ADMIN_ROLE(), deployer), "Failed to grant DEFAULT_ADMIN_ROLE");
        console.log("DEFAULT_ADMIN_ROLE granted successfully");
        
        // Grant ADMIN_ROLE
        factory.grantRole(factory.ADMIN_ROLE(), deployer);
        require(factory.hasRole(factory.ADMIN_ROLE(), deployer), "Failed to grant ADMIN_ROLE");
        console.log("ADMIN_ROLE granted successfully");
    }
}
