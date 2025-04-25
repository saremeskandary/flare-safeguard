// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../TokenRWAFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DeploymentHelper
 * @dev Library for common deployment operations
 */
library DeploymentHelper {
    event RoleSetup(address indexed contractAddress, address indexed account);
    error DeploymentVerificationFailed();

    function setupRoles(TokenRWAFactory factory, address deployer) internal {
        factory.grantRole(factory.ADMIN_ROLE(), deployer);
        emit RoleSetup(address(factory), deployer);
    }

    function verifyDeployment(
        TokenRWAFactory factory,
        address deployer
    ) internal view returns (bool) {
        return factory.hasRole(factory.ADMIN_ROLE(), deployer);
    }
}
