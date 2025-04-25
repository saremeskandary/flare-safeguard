// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./DataVerification.sol";

/**
 * @title TokenRWA
 * @dev Contract for managing Real World Asset (RWA) tokens using OpenZeppelin's ERC20 standard
 */
contract TokenRWA is ERC20, ReentrancyGuard, Initializable {
    // Custom errors
    error InvalidVerificationContract();
    error InvalidMintParameters();
    error InvalidAddresses();
    error InvalidParameters();
    error InvalidAsset();
    error NoObligation();
    error Unauthorized();

    DataVerification public verificationContract;
    mapping(address => bool) public verifiedAssets;
    mapping(address => bytes32) public assetObligations;

    // Add state variables for name and symbol
    string private _tokenName;
    string private _tokenSymbol;

    // Owner address
    address public owner;

    event AssetStatusChanged(
        address indexed asset,
        bytes32 indexed obligationId,
        bool verified
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

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

        owner = msg.sender;

        // Set token name and symbol
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;
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
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
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
    ) external onlyOwner {
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
    function unverifyAsset(address asset) external onlyOwner {
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
