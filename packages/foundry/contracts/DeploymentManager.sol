// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./DataVerification.sol";
import "./TokenRWA.sol";
import "./TokenRWAFactory.sol";
import "./RoleManager.sol";
import "./libraries/DeploymentHelper.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DeploymentManager
 * @dev Contract to manage deployment steps and reduce main deployment contract size
 */
contract DeploymentManager {
    using DeploymentHelper for *;

    struct DeploymentInfo {
        address dataVerification;
        address roleManager;
        address factory;
        address implementation;
        address deployer;
    }

    event DeploymentStepCompleted(address indexed contractAddress, string step);

    function deployCoreContracts()
        external
        returns (DeploymentInfo memory info)
    {
        info.deployer = msg.sender;

        DataVerification verification = new DataVerification();
        info.dataVerification = address(verification);
        emit DeploymentStepCompleted(address(verification), "DataVerification");

        RoleManager roleManager = new RoleManager();
        info.roleManager = address(roleManager);
        emit DeploymentStepCompleted(address(roleManager), "RoleManager");

        return info;
    }

    function deployFactory(
        DeploymentInfo memory info
    ) external returns (DeploymentInfo memory) {
        TokenRWAFactory factory = new TokenRWAFactory(
            info.dataVerification,
            info.roleManager
        );
        info.factory = address(factory);
        emit DeploymentStepCompleted(address(factory), "TokenRWAFactory");

        factory.grantRole(factory.ADMIN_ROLE(), address(this));
        factory.grantRole(factory.DEFAULT_ADMIN_ROLE(), info.deployer);
        factory.grantRole(factory.ADMIN_ROLE(), info.deployer);

        return info;
    }

    function setupRolesAndImplementation(
        DeploymentInfo memory info
    ) external returns (DeploymentInfo memory) {
        TokenRWAFactory factory = TokenRWAFactory(info.factory);
        RoleManager roleManager = RoleManager(info.roleManager);

        DeploymentHelper.setupRoles(roleManager, factory, info.deployer);
        factory.deployImplementation();
        info.implementation = address(factory.implementation());
        emit DeploymentStepCompleted(info.implementation, "Implementation");

        return info;
    }
}
