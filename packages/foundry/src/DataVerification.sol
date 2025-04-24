// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DataVerification
 * @dev Contract for verifying real-world asset data with Flare State Connector integration
 */
contract DataVerification is AccessControl, ReentrancyGuard {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct VerificationData {
        address verifier;
        uint256 timestamp;
        bool isValid;
        string dataHash;
        string metadata;
    }

    struct VerificationTemplate {
        string[] requiredFields;
        string[] optionalFields;
        address[] authorizedVerifiers;
    }

    struct Obligation {
        address obligatedParty;
        uint256 deadline;
        string description;
        bool fulfilled;
    }

    mapping(address => VerificationData) internal verifications;
    mapping(address => bool) internal isVerified;
    mapping(string => VerificationTemplate) internal verificationTemplates;
    mapping(bytes32 => Obligation) internal obligations;

    // State Connector integration
    address public stateConnectorAddress;
    bool public stateConnectorEnabled;

    event VerificationAdded(
        address indexed asset,
        address indexed verifier,
        bool isValid,
        string dataHash
    );
    event VerificationUpdated(
        address indexed asset,
        address indexed verifier,
        bool isValid,
        string dataHash
    );
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event TemplateCreated(string indexed assetType);
    event ObligationCreated(
        bytes32 indexed obligationId,
        address obligatedParty,
        uint256 deadline
    );
    event ObligationFulfilled(bytes32 indexed obligationId);
    event StateConnectorSet(address indexed stateConnectorAddress);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
    }

    /**
     * @dev Add a new verifier
     * @param verifier Address of the verifier to add
     */
    function addVerifier(address verifier) external onlyRole(ADMIN_ROLE) {
        grantRole(VERIFIER_ROLE, verifier);
        emit VerifierAdded(verifier);
    }

    /**
     * @dev Remove a verifier
     * @param verifier Address of the verifier to remove
     */
    function removeVerifier(address verifier) external onlyRole(ADMIN_ROLE) {
        revokeRole(VERIFIER_ROLE, verifier);
        emit VerifierRemoved(verifier);
    }

    /**
     * @dev Add or update verification data for an asset
     * @param asset Address of the asset to verify
     * @param isValid Whether the asset data is valid
     * @param dataHash Hash of the asset data
     * @param metadata Additional metadata about the verification
     */
    function verifyAsset(
        address asset,
        bool isValid,
        string calldata dataHash,
        string calldata metadata
    ) external onlyRole(VERIFIER_ROLE) nonReentrant {
        require(asset != address(0), "Invalid asset address");

        VerificationData storage data = verifications[asset];
        bool isUpdate = data.verifier != address(0);

        data.verifier = msg.sender;
        data.timestamp = block.timestamp;
        data.isValid = isValid;
        data.dataHash = dataHash;
        data.metadata = metadata;

        isVerified[asset] = isValid;

        if (isUpdate) {
            emit VerificationUpdated(asset, msg.sender, isValid, dataHash);
        } else {
            emit VerificationAdded(asset, msg.sender, isValid, dataHash);
        }
    }

    /**
     * @dev Create a verification template for a specific asset type
     * @param assetType Type of asset (e.g., "REAL_ESTATE", "COMMODITY")
     * @param requiredFields Array of required fields for verification
     * @param optionalFields Array of optional fields for verification
     */
    function createVerificationTemplate(
        string memory assetType,
        string[] memory requiredFields,
        string[] memory optionalFields
    ) external onlyRole(ADMIN_ROLE) {
        require(bytes(assetType).length > 0, "Invalid asset type");

        verificationTemplates[assetType] = VerificationTemplate({
            requiredFields: requiredFields,
            optionalFields: optionalFields,
            authorizedVerifiers: new address[](0)
        });

        emit TemplateCreated(assetType);
    }

    /**
     * @dev Add an authorized verifier to a template
     * @param assetType Type of asset
     * @param verifier Address of the verifier to add
     */
    function addTemplateVerifier(
        string memory assetType,
        address verifier
    ) external onlyRole(ADMIN_ROLE) {
        require(bytes(assetType).length > 0, "Invalid asset type");
        require(verifier != address(0), "Invalid verifier address");

        VerificationTemplate storage template = verificationTemplates[
            assetType
        ];
        require(template.requiredFields.length > 0, "Template not found");

        // Check if verifier already exists
        for (uint i = 0; i < template.authorizedVerifiers.length; i++) {
            require(
                template.authorizedVerifiers[i] != verifier,
                "Verifier already authorized"
            );
        }

        template.authorizedVerifiers.push(verifier);
    }

    /**
     * @dev Create a new obligation
     * @param obligatedParty Address of the party with the obligation
     * @param deadline Timestamp when the obligation must be fulfilled
     * @param description Description of the obligation
     * @return obligationId Unique identifier for the obligation
     */
    function createObligation(
        address obligatedParty,
        uint256 deadline,
        string memory description
    ) external onlyRole(ADMIN_ROLE) returns (bytes32) {
        require(obligatedParty != address(0), "Invalid obligated party");
        require(deadline > block.timestamp, "Deadline must be in the future");
        require(bytes(description).length > 0, "Description cannot be empty");

        bytes32 obligationId = keccak256(
            abi.encodePacked(
                obligatedParty,
                deadline,
                description,
                block.timestamp
            )
        );

        obligations[obligationId] = Obligation({
            obligatedParty: obligatedParty,
            deadline: deadline,
            description: description,
            fulfilled: false
        });

        emit ObligationCreated(obligationId, obligatedParty, deadline);
        return obligationId;
    }

    /**
     * @dev Mark an obligation as fulfilled
     * @param obligationId ID of the obligation to fulfill
     */
    function fulfillObligation(bytes32 obligationId) external {
        Obligation storage obligation = obligations[obligationId];
        require(
            obligation.obligatedParty != address(0),
            "Obligation not found"
        );
        require(!obligation.fulfilled, "Obligation already fulfilled");
        require(
            msg.sender == obligation.obligatedParty ||
                hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to fulfill obligation"
        );

        obligation.fulfilled = true;
        emit ObligationFulfilled(obligationId);
    }

    /**
     * @dev Set the State Connector address
     * @param _stateConnectorAddress Address of the State Connector contract
     */
    function setStateConnector(
        address _stateConnectorAddress
    ) external onlyRole(ADMIN_ROLE) {
        require(
            _stateConnectorAddress != address(0),
            "Invalid State Connector address"
        );
        stateConnectorAddress = _stateConnectorAddress;
        stateConnectorEnabled = true;
        emit StateConnectorSet(_stateConnectorAddress);
    }

    /**
     * @dev Verify data using Flare's State Connector
     * @param requestId Request ID from State Connector
     * @param proof Proof data from State Connector
     * @return success Whether verification was successful
     */
    function verifyWithStateConnector(
        bytes32 requestId,
        bytes memory proof
    ) external view onlyRole(VERIFIER_ROLE) returns (bool) {
        require(stateConnectorEnabled, "State Connector not enabled");
        require(stateConnectorAddress != address(0), "State Connector not set");

        // This is a simplified example - actual implementation would depend on
        // Flare's State Connector interface
        // In a real implementation, you would call the State Connector contract
        // and verify the proof using the requestId and proof parameters

        // For demonstration purposes, we'll use the parameters in a simple check
        require(requestId != bytes32(0), "Invalid request ID");
        require(proof.length > 0, "Invalid proof");

        // For now, we'll just return true as a placeholder
        return true;
    }

    /**
     * @dev Get verification data for an asset
     * @param asset Address of the asset
     * @return VerificationData struct containing verification information
     */
    function getVerificationData(
        address asset
    ) external view returns (VerificationData memory) {
        return verifications[asset];
    }

    /**
     * @dev Check if an asset is verified
     * @param asset Address of the asset
     * @return bool Whether the asset is verified
     */
    function isAssetVerified(address asset) external view returns (bool) {
        return isVerified[asset];
    }

    /**
     * @dev Get a verification template
     * @param assetType Type of asset
     * @return template VerificationTemplate struct
     */
    function getVerificationTemplate(
        string memory assetType
    ) external view returns (VerificationTemplate memory) {
        return verificationTemplates[assetType];
    }

    /**
     * @dev Get an obligation
     * @param obligationId ID of the obligation
     * @return obligation Obligation struct
     */
    function getObligation(
        bytes32 obligationId
    ) external view returns (Obligation memory) {
        return obligations[obligationId];
    }
}
