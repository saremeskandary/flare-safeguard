// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BSD Token (Backed Stable Digital Token)
 * @dev Implementation of the BSD Token with backing mechanism and governance features
 *
 * BSD (Backed Stable Digital Token) is an ERC20 token that implements:
 * - ETH backing mechanism allowing users to add/remove ETH backing
 * - Governance features including pausability and owner-controlled minting
 * - Standard ERC20 functionality with additional security features
 *
 * The token is designed to provide a stable digital asset that can be backed by ETH,
 * offering users the ability to add and remove backing while maintaining standard
 * ERC20 token functionality. The backing mechanism provides value stability and
 * collateralization for the token.
 */
contract BSDToken is ERC20, Pausable, Ownable {
    // Custom errors
    error MustSendETH();
    error AmountMustBeGreaterThanZero();
    error InsufficientBacking();

    uint256 private _totalBacking;
    mapping(address => uint256) private _backingAmounts;

    event BackingAdded(address indexed account, uint256 amount);
    event BackingRemoved(address indexed account, uint256 amount);

    constructor() ERC20("BSD Token", "BSD") Ownable(msg.sender) {}

    /**
     * @dev Mints new BSD tokens
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    /**
     * @dev Adds ETH backing for BSD tokens
     */
    function addBacking() external payable {
        if (msg.value == 0) revert MustSendETH();
        _totalBacking += msg.value;
        _backingAmounts[msg.sender] += msg.value;
        emit BackingAdded(msg.sender, msg.value);
    }

    /**
     * @dev Removes ETH backing for BSD tokens
     * @param amount Amount of ETH to remove from backing
     */
    function removeBacking(uint256 amount) external whenNotPaused {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (_backingAmounts[msg.sender] < amount) revert InsufficientBacking();
        _totalBacking -= amount;
        _backingAmounts[msg.sender] -= amount;
        emit BackingRemoved(msg.sender, amount);
    }

    /**
     * @dev Returns the total amount of ETH backing
     * @return The total amount of ETH backing
     */
    function getTotalBacking() public view returns (uint256) {
        return _totalBacking;
    }

    /**
     * @dev Returns the backing amount for the caller
     * @return The amount of ETH backing for the caller
     */
    function getBackingAmount() external view returns (uint256) {
        return _backingAmounts[msg.sender];
    }

    /**
     * @dev Pauses all token transfers and minting
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers and minting
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Hook that is called before any transfer of tokens
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @param amount The amount of tokens being transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal whenNotPaused {
        // Add any custom transfer logic here if needed
    }
}
