// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../DeploymentManager.sol";
import "./DeploymentHelper.sol";

/**
 * @title RWADeploymentLib
 * @dev Library for RWA deployment logic
 */
library RWADeploymentLib {
    using DeploymentHelper for *;

    error DeploymentVerificationFailed();

    function deployRWA(
        DeploymentManager manager,
        address deployer
    ) internal returns (DeploymentManager.DeploymentInfo memory info) {
        // Step 1: Deploy core contracts
        info = manager.deployCoreContracts();

        // If deployer is provided, use it instead of msg.sender
        if (deployer != address(0)) {
            info.deployer = deployer;
        }

        // Step 2: Deploy factory
        info = manager.deployFactory(info);

        // Step 3: Setup roles and implementation
        info = manager.setupRolesAndImplementation(info);

        // Verify deployment
        if (
            !DeploymentHelper.verifyDeployment(
                TokenRWAFactory(info.factory),
                info.deployer
            )
        ) {
            revert DeploymentVerificationFailed();
        }

        return info;
    }
}
