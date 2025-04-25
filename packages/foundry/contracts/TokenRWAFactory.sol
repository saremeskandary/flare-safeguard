// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./TokenRWA.sol";
import "./RoleManager.sol";

/**
 * @title TokenRWAFactory
 * @dev Factory contract for creating new RWA tokens using minimal proxy pattern
 */
contract TokenRWAFactory is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    TokenRWA public implementation;
    address public verificationContract;
    RoleManager public roleManager;

    event TokenEvent(
        address indexed token,
        string name,
        string symbol,
        address indexed admin
    );
    event ManagerUpdated(
        address indexed oldManager,
        address indexed newManager
    );

    // Custom errors
    error InvalidAddresses();
    error ImplementationExists();
    error InvalidParameters();

    constructor(address _verificationContract, address _roleManager) {
        if (_verificationContract == address(0) || _roleManager == address(0))
            revert InvalidAddresses();

        verificationContract = _verificationContract;
        roleManager = RoleManager(_roleManager);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Deploy the implementation contract
     */
    function deployImplementation() external onlyRole(ADMIN_ROLE) {
        if (address(implementation) != address(0))
            revert ImplementationExists();

        implementation = new TokenRWA();
    }

    /**
     * @dev Create a new RWA token
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @return token Address of the newly created token
     */
    function createToken(
        string memory name,
        string memory symbol
    ) external onlyRole(ADMIN_ROLE) returns (address token) {
        if (
            address(implementation) == address(0) ||
            bytes(name).length == 0 ||
            bytes(symbol).length == 0
        ) revert InvalidParameters();

        token = Clones.clone(address(implementation));
        TokenRWA(token).initialize(name, symbol, verificationContract);
        roleManager.registerContract(
            token,
            string(abi.encodePacked(name, " Token"))
        );

        address factoryAdmin = msg.sender;
        TokenRWA(token).setAdminFromParent(factoryAdmin, factoryAdmin);
        emit TokenEvent(token, name, symbol, factoryAdmin);
        return token;
    }

    /**
     * @dev Update the verification contract address
     * @param _verificationContract New verification contract address
     */
    function updateVerificationContract(
        address _verificationContract
    ) external onlyRole(ADMIN_ROLE) {
        if (_verificationContract == address(0)) revert InvalidAddresses();

        verificationContract = _verificationContract;
    }

    /**
     * @dev Update the role manager address
     * @param _roleManager New role manager address
     */
    function updateRoleManager(
        address _roleManager
    ) external onlyRole(ADMIN_ROLE) {
        if (_roleManager == address(0)) revert InvalidAddresses();

        address oldManager = address(roleManager);
        roleManager = RoleManager(_roleManager);
        emit ManagerUpdated(oldManager, _roleManager);
    }

    /**
     * @dev Synchronize admin roles across all tokens
     * @param tokens Array of token addresses to synchronize
     */
    function synchronizeAdminRoles(
        address[] calldata tokens
    ) external onlyRole(ADMIN_ROLE) {
        address factoryAdmin = msg.sender;
        for (uint256 i = 0; i < tokens.length; i++) {
            TokenRWA(tokens[i]).setAdminFromParent(factoryAdmin, factoryAdmin);
            emit TokenEvent(tokens[i], "", "", factoryAdmin);
        }
    }
}
