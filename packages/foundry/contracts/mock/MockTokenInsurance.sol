// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../flare/TokenInsurance.sol";

contract MockTokenInsurance is TokenInsurance {
    bool private dueDateArrivedMock;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 prime_,
        address dataFetcherAddress_,
        address stateConnectorAddress_
    )
        TokenInsurance(
            name_,
            symbol_,
            prime_,
            dataFetcherAddress_,
            stateConnectorAddress_
        )
    {}

    function sendMessage(
        address,
        uint256,
        bytes memory
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(""));
    }

    function sendGetLiquidationRequest(
        address,
        string memory
    ) public payable override {}
}
