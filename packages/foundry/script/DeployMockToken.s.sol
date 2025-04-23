// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./DeployHelpers.s.sol";
import "../test/mocks/MockBSDToken.sol";

/**
 * @notice Deployment script for the MockBSDToken contract
 */
contract DeployMockToken is ScaffoldETHDeploy {
    function run() external ScaffoldEthDeployerRunner {
        console.log(
            "Starting MockBSDToken deployment with deployer:",
            deployer
        );

        // Deploy mock token for testing
        MockBSDToken mockToken = new MockBSDToken();
        console.log("MockBSDToken deployed at:", address(mockToken));
        deployments.push(Deployment("MockBSDToken", address(mockToken)));

        console.log("MockBSDToken deployment completed successfully!");
    }
}
