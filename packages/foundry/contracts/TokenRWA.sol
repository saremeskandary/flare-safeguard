// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    DataVerification public verificationContract;
    mapping(address => bool) public verifiedAssets;
    mapping(address => bytes32) public assetObligations;

    // Add state variables for name and symbol
    string private _tokenName;
    string private _tokenSymbol;

    event AssetVerified(address indexed asset, bytes32 obligationId);
    event AssetUnverified(address indexed asset);
    event ObligationCreated(
        bytes32 indexed obligationId,
        address obligatedParty,
        uint256 deadline
    );
    event ObligationFulfilled(bytes32 indexed obligationId);

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
        string memory tokenName, // solhint-disable-next-line no-unused-vars
        string memory tokenSymbol, // solhint-disable-next-line no-unused-vars
        address _verificationContract
    ) public initializer {
        require(
            _verificationContract != address(0),
            "Invalid verification contract"
        );
        verificationContract = DataVerification(_verificationContract);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // Set token name and symbol
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;
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
    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) nonReentrant {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");

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
        require(asset != address(0), "Invalid asset address");
        require(obligatedParty != address(0), "Invalid obligated party");
        require(deadline > block.timestamp, "Deadline must be in the future");
        require(bytes(description).length > 0, "Description cannot be empty");

        // Create obligation in verification contract
        bytes32 obligationId = verificationContract.createObligation(
            obligatedParty,
            deadline,
            description
        );

        verifiedAssets[asset] = true;
        assetObligations[asset] = obligationId;

        emit AssetVerified(asset, obligationId);
        emit ObligationCreated(obligationId, obligatedParty, deadline);
    }

    /**
     * @dev Unverify an asset
     * @param asset Address of the asset to unverify
     */
    function unverifyAsset(address asset) external onlyRole(ADMIN_ROLE) {
        require(asset != address(0), "Invalid asset address");
        require(verifiedAssets[asset], "Asset not verified");

        verifiedAssets[asset] = false;
        delete assetObligations[asset];

        emit AssetUnverified(asset);
    }

    /**
     * @dev Fulfill an obligation for an asset
     * @param asset Address of the asset
     */
    function fulfillObligation(address asset) external {
        require(asset != address(0), "Invalid asset address");
        require(verifiedAssets[asset], "Asset not verified");

        bytes32 obligationId = assetObligations[asset];
        require(obligationId != bytes32(0), "No obligation found");

        verificationContract.fulfillObligation(obligationId);
        emit ObligationFulfilled(obligationId);
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
