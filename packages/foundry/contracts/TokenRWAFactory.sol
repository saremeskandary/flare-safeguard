// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./TokenRWA.sol";

/**
 * @title TokenRWAFactory
 * @dev Factory contract for creating new RWA tokens using minimal proxy pattern
 */
contract TokenRWAFactory {
    TokenRWA public implementation;
    address public verificationContract;
    address public owner;

    event TokenEvent(
        address indexed token,
        string name,
        string symbol,
        address indexed owner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // Custom errors
    error InvalidAddresses();
    error ImplementationExists();
    error InvalidParameters();
    error Unauthorized();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _verificationContract) {
        if (_verificationContract == address(0)) revert InvalidAddresses();

        verificationContract = _verificationContract;
        owner = msg.sender;
    }

    /**
     * @dev Transfer ownership to a new address
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddresses();
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Deploy the implementation contract
     */
    function deployImplementation() external onlyOwner {
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
    ) external onlyOwner returns (address token) {
        if (
            address(implementation) == address(0) ||
            bytes(name).length == 0 ||
            bytes(symbol).length == 0
        ) revert InvalidParameters();

        token = Clones.clone(address(implementation));
        TokenRWA(token).initialize(name, symbol, verificationContract);

        // Transfer ownership of the token to the factory owner
        TokenRWA(token).transferOwnership(msg.sender);

        emit TokenEvent(token, name, symbol, msg.sender);
        return token;
    }

    /**
     * @dev Update the verification contract address
     * @param _verificationContract New verification contract address
     */
    function updateVerificationContract(
        address _verificationContract
    ) external onlyOwner {
        if (_verificationContract == address(0)) revert InvalidAddresses();
        verificationContract = _verificationContract;
    }
}
