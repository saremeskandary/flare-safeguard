// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";
import "../contracts/TokenRWAFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title GrantTokenRWAFactoryAdmin
 * @dev Script to grant the deployer the admin role in the TokenRWAFactory contract
 */
contract GrantTokenRWAFactoryAdmin is Script {
    // Constants for roles
    bytes32 public constant DEFAULT_ADMIN_ROLE =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function run() external {
        // Get the deployer address
        address deployer = msg.sender;

        // Get the TokenRWAFactory address from the deployment artifacts
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/Deploy.s.sol/");

        // Get the latest deployment directory
        VmSafe.DirEntry[] memory dirs = vm.readDir(path);
        require(dirs.length > 0, "No deployment directories found");

        // Get the latest directory name
        string memory latestDir = dirs[dirs.length - 1].path;
        string memory artifactPath = string.concat(
            path,
            latestDir,
            "/run-latest.json"
        );

        // Read the deployment artifact
        string memory artifact = vm.readFile(artifactPath);

        // Parse the artifact to get the TokenRWAFactory address
        // The address is in the "returns" field of the last transaction
        string memory searchStr = '"returns":["0x';
        uint256 startIndex = vm.indexOf(artifact, searchStr) +
            bytes(searchStr).length -
            2;
        uint256 endIndex = vm.indexOf(artifact, '"');
        bytes memory artifactBytes = bytes(artifact);
        bytes memory addressBytes = new bytes(endIndex - startIndex);
        for (uint i = 0; i < endIndex - startIndex; i++) {
            addressBytes[i] = artifactBytes[startIndex + i];
        }
        address tokenRWAFactoryAddress = vm.parseAddress(string(addressBytes));

        // Create a reference to the TokenRWAFactory contract
        TokenRWAFactory factory = TokenRWAFactory(tokenRWAFactoryAddress);

        // Check if the deployer already has the DEFAULT_ADMIN_ROLE
        bool hasDefaultAdminRole = factory.hasRole(
            DEFAULT_ADMIN_ROLE,
            deployer
        );

        // Check if the deployer already has the ADMIN_ROLE
        bool hasAdminRole = factory.hasRole(ADMIN_ROLE, deployer);

        console.log("Deployer address:", deployer);
        console.log("TokenRWAFactory address:", tokenRWAFactoryAddress);
        console.log("Has DEFAULT_ADMIN_ROLE:", hasDefaultAdminRole);
        console.log("Has ADMIN_ROLE:", hasAdminRole);

        // Start broadcasting transactions
        vm.startBroadcast();

        // Grant the DEFAULT_ADMIN_ROLE if the deployer doesn't have it
        if (!hasDefaultAdminRole) {
            console.log("Granting DEFAULT_ADMIN_ROLE to deployer...");
            factory.grantRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("DEFAULT_ADMIN_ROLE granted to deployer");
        }

        // Grant the ADMIN_ROLE if the deployer doesn't have it
        if (!hasAdminRole) {
            console.log("Granting ADMIN_ROLE to deployer...");
            factory.grantRole(ADMIN_ROLE, deployer);
            console.log("ADMIN_ROLE granted to deployer");
        }

        // Stop broadcasting transactions
        vm.stopBroadcast();

        console.log("Role assignment completed");
    }
}
