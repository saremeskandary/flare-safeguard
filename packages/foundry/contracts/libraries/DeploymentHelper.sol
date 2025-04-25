// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../RoleManager.sol";
import "../TokenRWAFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DeploymentHelper
 * @dev Library for common deployment operations
 */
library DeploymentHelper {
    event RoleSetup(address indexed contractAddress, address indexed account);

    function setupRoles(
        RoleManager roleManager,
        TokenRWAFactory factory,
        address deployer
    ) external {
        roleManager.grantRole(roleManager.ADMIN_ROLE(), deployer);
        roleManager.registerContract(address(factory), "TokenRWA Factory");
        emit RoleSetup(address(roleManager), deployer);
    }

    function verifyDeployment(
        TokenRWAFactory factory,
        address deployer
    ) external view returns (bool) {
        return factory.hasRole(factory.ADMIN_ROLE(), deployer);
    }
}
