// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./DataVerification.sol";

/**
 * @title TokenRWA
 * @notice Real World Asset token with verification and transfer restrictions
 */
contract TokenRWA is ERC20, Ownable, Pausable {
    // Custom errors
    error InvalidDataVerificationAddress();
    error HolderAlreadyVerified();
    error InvalidVerification();
    error InvalidHolderAddress();
    error TransfersDisabled();
    error SenderNotVerified();
    error TransferLimitExceeded();
    error RecipientNotVerified();
    error InvalidRecipientAddress();

    // State variables
    DataVerification public dataVerification;
    mapping(address => bool) public verifiedHolders;
    mapping(address => uint256) public transferLimits;
    uint256 public constant MINIMUM_VERIFICATION_AMOUNT = 1000 ether;
    bool public transfersEnabled;

    // Events
    event HolderVerified(address indexed holder, uint256 amount);
    event TransferLimitSet(address indexed holder, uint256 limit);
    event TransfersEnabled();
    event TransfersDisabled();

    constructor(
        string memory name,
        string memory symbol,
        address _dataVerification
    ) ERC20(name, symbol) Ownable(msg.sender) {
        if (_dataVerification == address(0))
            revert InvalidDataVerificationAddress();
        dataVerification = DataVerification(payable(_dataVerification));
        transfersEnabled = false;
    }

    /**
     * @notice Verify a holder using FDC
     * @param requestId The FDC request ID for holder verification
     * @param proof The verification proof
     */
    function verifyHolder(
        bytes32 requestId,
        bytes calldata proof
    ) external whenNotPaused {
        if (verifiedHolders[msg.sender]) revert HolderAlreadyVerified();

        bool isValid = dataVerification.verifyAttestation(requestId, proof);
        if (!isValid) revert InvalidVerification();

        verifiedHolders[msg.sender] = true;
        emit HolderVerified(msg.sender, balanceOf(msg.sender));
    }

    /**
     * @notice Set transfer limit for a holder
     * @param holder The holder address
     * @param limit The transfer limit amount
     */
    function setTransferLimit(
        address holder,
        uint256 limit
    ) external onlyOwner {
        if (holder == address(0)) revert InvalidHolderAddress();
        transferLimits[holder] = limit;
        emit TransferLimitSet(holder, limit);
    }

    /**
     * @notice Enable transfers globally
     */
    function enableTransfers() external onlyOwner {
        transfersEnabled = true;
        emit TransfersEnabled();
    }

    /**
     * @notice Disable transfers globally
     */
    function disableTransfers() external onlyOwner {
        transfersEnabled = false;
        emit TransfersDisabled();
    }

    /**
     * @notice Mint tokens to an address
     * @param to The recipient address
     * @param amount The amount to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert InvalidRecipientAddress();
        _mint(to, amount);
    }

    /**
     * @notice Override _update to implement transfer restrictions
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        if (!transfersEnabled) revert TransfersDisabled();

        if (from != address(0)) {
            // Skip checks for minting
            if (!verifiedHolders[from]) revert SenderNotVerified();
            if (transferLimits[from] != 0 && amount > transferLimits[from])
                revert TransferLimitExceeded();
        }

        if (to != address(0)) {
            // Skip checks for burning
            if (!verifiedHolders[to]) revert RecipientNotVerified();
        }

        super._update(from, to, amount);
    }

    /**
     * @notice Pause all transfers
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause all transfers
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
