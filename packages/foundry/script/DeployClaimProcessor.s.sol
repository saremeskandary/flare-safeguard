// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/ClaimProcessor.sol";
import "../test/mocks/MockBSDToken.sol";

/**
 * @notice Deploy script for ClaimProcessor and MockBSDToken contracts
 * @dev Inherits ScaffoldETHDeploy which:
 *      - Includes forge-std/Script.sol for deployment
 *      - Includes ScaffoldEthDeployerRunner modifier
 *      - Provides `deployer` variable
 * Example:
 * yarn deploy --file DeployClaimProcessor.s.sol  # local anvil chain
 * yarn deploy --file DeployClaimProcessor.s.sol --network optimism # live network (requires keystore)
 */
contract DeployClaimProcessor is ScaffoldETHDeploy {
    /**
     * @dev Deployer setup based on `ETH_KEYSTORE_ACCOUNT` in `.env`:
     *      - "scaffold-eth-default": Uses Anvil's account #9 (0xa0Ee7A142d267C1f36714E4a8F75612F20a79720), no password prompt
     *      - "scaffold-eth-custom": requires password used while creating keystore
     *
     * Note: Must use ScaffoldEthDeployerRunner modifier to:
     *      - Setup correct `deployer` account and fund it
     *      - Export contract addresses & ABIs to `nextjs` packages
     */
    function run() external ScaffoldEthDeployerRunner {
        // Deploy mock token for testing
        MockBSDToken mockToken = new MockBSDToken();
        console.log("MockBSDToken deployed at:", address(mockToken));

        // Deploy ClaimProcessor
        ClaimProcessor claimProcessor = new ClaimProcessor(address(mockToken));
        console.log("ClaimProcessor deployed at:", address(claimProcessor));

        // Grant roles to deployer
        claimProcessor.grantRole(claimProcessor.ADMIN_ROLE(), deployer);
        claimProcessor.grantRole(claimProcessor.VERIFIER_ROLE(), deployer);
    }
}
