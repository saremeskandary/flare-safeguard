// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title IRoleManageable
 * @dev Interface for contracts that can have their admin role set
 */
interface IRoleManageable {
    function setAdminFromParent(address newAdmin, address parentAdmin) external;
}

/**
 * @title RoleManager
 * @dev Central contract for managing roles across the entire system
 *
 * This contract serves as a central point for role management across all contracts
 * in the system. It allows for synchronized role management and provides a way
 * to update roles across multiple contracts at once.
 */
contract RoleManager is AccessControl {
    // Custom errors
    error InvalidContractAddress();
    error EmptyName();
    error ContractAlreadyRegistered();
    error InvalidAdminAddress();
    error ContractNotRegistered();

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EVALUATOR_ROLE = keccak256("EVALUATOR_ROLE");

    // Mapping of contract addresses to their names for easier management
    mapping(address => string) public managedContracts;
    address[] public contractAddresses;

    event ContractRegistered(address indexed contractAddress, string name);
    event AdminRoleUpdated(
        address indexed contractAddress,
        address indexed newAdmin
    );
    event BatchAdminRoleUpdated(
        address[] contractAddresses,
        address indexed newAdmin
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Register a contract for role management
     * @param contractAddress Address of the contract to register
     * @param name Name of the contract for easier identification
     */
    function registerContract(
        address contractAddress,
        string memory name
    ) external onlyRole(ADMIN_ROLE) {
        if (contractAddress == address(0)) revert InvalidContractAddress();
        if (bytes(name).length == 0) revert EmptyName();

        // Check if contract is already registered
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            if (contractAddresses[i] == contractAddress)
                revert ContractAlreadyRegistered();
        }

        managedContracts[contractAddress] = name;
        contractAddresses.push(contractAddress);

        emit ContractRegistered(contractAddress, name);
    }

    /**
     * @dev Update admin role for a specific contract
     * @param contractAddress Address of the contract to update
     * @param newAdmin Address of the new admin
     */
    function updateContractAdmin(
        address contractAddress,
        address newAdmin
    ) external onlyRole(ADMIN_ROLE) {
        if (contractAddress == address(0)) revert InvalidContractAddress();
        if (newAdmin == address(0)) revert InvalidAdminAddress();
        if (bytes(managedContracts[contractAddress]).length == 0)
            revert ContractNotRegistered();

        // Call the setAdminFromParent function on the target contract
        IRoleManageable(contractAddress).setAdminFromParent(
            newAdmin,
            msg.sender
        );

        emit AdminRoleUpdated(contractAddress, newAdmin);
    }

    /**
     * @dev Update admin role for all registered contracts
     * @param newAdmin Address of the new admin
     */
    function updateAllContractAdmins(
        address newAdmin
    ) external onlyRole(ADMIN_ROLE) {
        if (newAdmin == address(0)) revert InvalidAdminAddress();

        for (uint256 i = 0; i < contractAddresses.length; i++) {
            IRoleManageable(contractAddresses[i]).setAdminFromParent(
                newAdmin,
                msg.sender
            );
        }

        emit BatchAdminRoleUpdated(contractAddresses, newAdmin);
    }

    /**
     * @dev Get all registered contracts
     * @return Array of contract addresses
     */
    function getRegisteredContracts() external view returns (address[] memory) {
        return contractAddresses;
    }

    /**
     * @dev Get the name of a registered contract
     * @param contractAddress Address of the contract
     * @return Name of the contract
     */
    function getContractName(
        address contractAddress
    ) external view returns (string memory) {
        return managedContracts[contractAddress];
    }
}
