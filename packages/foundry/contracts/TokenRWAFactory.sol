// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./TokenRWA.sol";

/**
 * @title TokenRWAFactory
 * @dev Factory contract for creating new RWA tokens using minimal proxy pattern
 */
contract TokenRWAFactory is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    TokenRWA public implementation;
    address public verificationContract;

    event TokenEvent(
        address indexed token,
        string name,
        string symbol,
        address indexed admin
    );

    // Custom errors
    error InvalidAddresses();
    error ImplementationExists();
    error InvalidParameters();

    constructor(address _verificationContract) {
        if (_verificationContract == address(0)) revert InvalidAddresses();

        verificationContract = _verificationContract;
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

        // Clone the implementation
        token = Clones.clone(address(implementation));

        // Initialize the token with name, symbol, and verification contract
        TokenRWA(token).initialize(name, symbol, verificationContract);

        // Grant DEFAULT_ADMIN_ROLE to the factory admin first
        TokenRWA(token).grantRole(
            TokenRWA(token).DEFAULT_ADMIN_ROLE(),
            msg.sender
        );

        // Then set the admin
        TokenRWA(token).setAdminFromParent(msg.sender, msg.sender);

        emit TokenEvent(token, name, symbol, msg.sender);
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
}
