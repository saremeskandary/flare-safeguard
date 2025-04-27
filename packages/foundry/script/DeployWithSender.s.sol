// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "./Deploy.s.sol";

contract DeployWithSender is Script {
    function setUp() public {}

    function run() public {
        // Start broadcasting with the explicit sender
        vm.startBroadcast(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);

        // Deploy the contracts
        Deploy deployer = new Deploy();
        deployer.run();

        vm.stopBroadcast();
    }
}
