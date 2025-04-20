// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "./FlareDataRequest.sol";
import "./StateConnector.sol";

contract TokenInsurance is ERC20, ERC20Burnable, FlareDataRequest {
    using SafeERC20 for IERC20;

    uint256 public prime;
    bool public dueDateArrived;
    StateConnector public stateConnector;

    event InsurancePaid(address indexed user, uint256 amount);
    event LiquidationRequested(address indexed token, string symbol);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 prime_,
        address dataFetcherAddress_,
        address stateConnectorAddress_
    ) ERC20(name_, symbol_) FlareDataRequest(dataFetcherAddress_) {
        prime = prime_;
        stateConnector = StateConnector(stateConnectorAddress_);
    }

    function sendGetLiquidationRequest(
        address tokenRWA,
        string memory symbol
    ) public payable virtual override {
        super.sendGetLiquidationRequest(tokenRWA, symbol);
        emit LiquidationRequested(tokenRWA, symbol);
    }

    function callVaultHandleRWAPayment() public override {
        // Implementation for handling RWA payment
        dueDateArrived = true;
    }

    function payInsurance() external {
        require(!dueDateArrived, "Insurance period has ended");
        _mint(msg.sender, prime);
        emit InsurancePaid(msg.sender, prime);
    }
}
