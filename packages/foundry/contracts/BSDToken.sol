// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "dependencies/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "dependencies/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title BSD Token
 * @dev Implementation of the BSD Token with backing mechanism and governance features
 */
contract BSDToken is ERC20, Pausable, Ownable {
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
        require(msg.value > 0, "Must send ETH");
        _totalBacking += msg.value;
        _backingAmounts[msg.sender] += msg.value;
        emit BackingAdded(msg.sender, msg.value);
    }

    /**
     * @dev Removes ETH backing for BSD tokens
     * @param amount Amount of ETH to remove from backing
     */
    function removeBacking(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(_backingAmounts[msg.sender] >= amount, "Insufficient backing");
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
