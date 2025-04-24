// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

    event TokenCreated(address indexed token, string name, string symbol);

    constructor(address _verificationContract) {
        require(
            _verificationContract != address(0),
            "Invalid verification contract"
        );
        verificationContract = _verificationContract;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Deploy the implementation contract
     */
    function deployImplementation() external onlyRole(ADMIN_ROLE) {
        require(
            address(implementation) == address(0),
            "Implementation already deployed"
        );
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
        require(
            address(implementation) != address(0),
            "Implementation not deployed"
        );
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");

        // Clone the implementation contract
        token = Clones.clone(address(implementation));

        // Initialize the clone
        TokenRWA(token).initialize(name, symbol, verificationContract);

        emit TokenCreated(token, name, symbol);
        return token;
    }

    /**
     * @dev Update the verification contract address
     * @param _verificationContract New verification contract address
     */
    function updateVerificationContract(
        address _verificationContract
    ) external onlyRole(ADMIN_ROLE) {
        require(
            _verificationContract != address(0),
            "Invalid verification contract"
        );
        verificationContract = _verificationContract;
    }
}
