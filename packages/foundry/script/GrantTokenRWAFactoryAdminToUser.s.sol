// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/TokenRWAFactory.sol";

/**
 * @title GrantTokenRWAFactoryAdminToUser
 * @dev Script to grant the ADMIN_ROLE to a specific user address in the TokenRWAFactory contract
 */
contract GrantTokenRWAFactoryAdminToUser is Script {
    function run() external {
        // Get the deployer's private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get the user address from environment variable
        address userAddress = vm.envAddress("USER_ADDRESS");
        
        // Get the TokenRWAFactory address from environment variable
        address tokenRWAFactoryAddress = vm.envAddress("TOKEN_RWA_FACTORY_ADDRESS");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Create a reference to the TokenRWAFactory contract
        TokenRWAFactory tokenRWAFactory = TokenRWAFactory(tokenRWAFactoryAddress);
        
        // Check if user already has ADMIN_ROLE
        bool hasAdminRole = tokenRWAFactory.hasRole(tokenRWAFactory.ADMIN_ROLE(), userAddress);
        
        if (!hasAdminRole) {
            // Grant ADMIN_ROLE to the user
            tokenRWAFactory.grantRole(tokenRWAFactory.ADMIN_ROLE(), userAddress);
            console.log("ADMIN_ROLE granted to:", userAddress);
        } else {
            console.log("User already has ADMIN_ROLE");
        }
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
