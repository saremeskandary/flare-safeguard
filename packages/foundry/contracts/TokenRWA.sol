// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./DataVerification.sol";

/**
 * @title TokenRWA
 * @dev Contract for managing Real World Asset (RWA) tokens using OpenZeppelin's ERC20 standard
 */
contract TokenRWA is ERC20, AccessControl, ReentrancyGuard, Initializable {
    // Custom errors
    error InvalidVerificationContract();
    error NotAuthorized();
    error InvalidAdminAddress();
    error InvalidMintParameters();
    error InvalidAddresses();
    error InvalidParameters();
    error InvalidAsset();
    error NoObligation();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    DataVerification public verificationContract;
    mapping(address => bool) public verifiedAssets;
    mapping(address => bytes32) public assetObligations;

    // Add state variables for name and symbol
    string private _tokenName;
    string private _tokenSymbol;

    event AssetStatusChanged(
        address indexed asset,
        bytes32 indexed obligationId,
        bool verified
    );
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() ERC20("", "") {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract
     * @param tokenName Name of the token
     * @param tokenSymbol Symbol of the token
     * @param _verificationContract Address of the verification contract
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        address _verificationContract
    ) public initializer {
        if (_verificationContract == address(0))
            revert InvalidVerificationContract();

        verificationContract = DataVerification(_verificationContract);

        // Set token name and symbol
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;

        // Note: We don't grant roles here anymore as they will be granted by the factory
    }

    /**
     * @dev Set admin role from a parent contract
     * @param newAdmin Address of the new admin
     * @param parentAdmin Address of the parent contract admin
     */
    function setAdminFromParent(
        address newAdmin,
        address parentAdmin
    ) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, parentAdmin)) revert NotAuthorized();
        if (newAdmin == address(0)) revert InvalidAdminAddress();

        // Store the current admin for the event
        address currentAdmin = msg.sender;

        // Revoke admin role from the current admin if it's not the new admin
        if (currentAdmin != newAdmin) {
            _revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
        }

        // Grant admin role to the new admin if they don't already have it
        if (!hasRole(DEFAULT_ADMIN_ROLE, newAdmin)) {
            _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        }

        // Also grant MINTER_ROLE to the new admin
        if (!hasRole(MINTER_ROLE, newAdmin)) {
            _grantRole(MINTER_ROLE, newAdmin);
        }

        emit AdminChanged(currentAdmin, newAdmin);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _tokenName;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return _tokenSymbol;
    }

    /**
     * @dev Mint tokens to an address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (to == address(0) || amount == 0) revert InvalidMintParameters();
        _mint(to, amount);
    }

    /**
     * @dev Verify an asset and create an obligation
     * @param asset Address of the asset to verify
     * @param obligatedParty Address of the party with the obligation
     * @param deadline Timestamp when the obligation must be fulfilled
     * @param description Description of the obligation
     */
    function verifyAsset(
        address asset,
        address obligatedParty,
        uint256 deadline,
        string memory description
    ) external onlyRole(ADMIN_ROLE) {
        if (asset == address(0) || obligatedParty == address(0))
            revert InvalidAddresses();
        if (deadline <= block.timestamp || bytes(description).length == 0)
            revert InvalidParameters();

        bytes32 obligationId = verificationContract.createObligation(
            obligatedParty,
            deadline,
            description
        );
        verifiedAssets[asset] = true;
        assetObligations[asset] = obligationId;
        emit AssetStatusChanged(asset, obligationId, true);
    }

    /**
     * @dev Unverify an asset
     * @param asset Address of the asset to unverify
     */
    function unverifyAsset(address asset) external onlyRole(ADMIN_ROLE) {
        if (asset == address(0) || !verifiedAssets[asset])
            revert InvalidAsset();
        verifiedAssets[asset] = false;
        bytes32 obligationId = assetObligations[asset];
        delete assetObligations[asset];
        emit AssetStatusChanged(asset, obligationId, false);
    }

    /**
     * @dev Fulfill an obligation for an asset
     * @param asset Address of the asset
     */
    function fulfillObligation(address asset) external {
        if (asset == address(0) || !verifiedAssets[asset])
            revert InvalidAsset();
        bytes32 obligationId = assetObligations[asset];
        if (obligationId == bytes32(0)) revert NoObligation();
        verificationContract.fulfillObligation(obligationId);
    }

    /**
     * @dev Check if an asset is verified
     * @param asset Address of the asset
     * @return bool Whether the asset is verified
     */
    function isAssetVerified(address asset) external view returns (bool) {
        return verifiedAssets[asset];
    }

    /**
     * @dev Get obligation ID for an asset
     * @param asset Address of the asset
     * @return obligationId ID of the obligation
     */
    function getAssetObligation(address asset) external view returns (bytes32) {
        return assetObligations[asset];
    }

    /**
     * @dev Get obligation details
     * @param obligationId ID of the obligation
     * @return obligatedParty Address of the obligated party
     * @return deadline Timestamp when the obligation must be fulfilled
     * @return description Description of the obligation
     * @return fulfilled Whether the obligation has been fulfilled
     */
    function getObligationDetails(
        bytes32 obligationId
    )
        external
        view
        returns (
            address obligatedParty,
            uint256 deadline,
            string memory description,
            bool fulfilled
        )
    {
        DataVerification.Obligation memory obligation = verificationContract
            .getObligation(obligationId);
        return (
            obligation.obligatedParty,
            obligation.deadline,
            obligation.description,
            obligation.fulfilled
        );
    }
}
