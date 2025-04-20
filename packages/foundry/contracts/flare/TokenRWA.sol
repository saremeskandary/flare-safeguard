// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "dependencies/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "dependencies/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "./DataVerification.sol";

/**
 * @title TokenRWA
 * @notice Real World Asset token with verification and transfer restrictions
 */
contract TokenRWA is ERC20, Ownable, Pausable {
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
        require(
            _dataVerification != address(0),
            "Invalid data verification address"
        );
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
        require(!verifiedHolders[msg.sender], "Holder already verified");

        bool isValid = dataVerification.verifyAttestation(requestId, proof);
        require(isValid, "Invalid verification");

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
        require(holder != address(0), "Invalid holder address");
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
        require(to != address(0), "Invalid recipient address");
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
        require(transfersEnabled, "Transfers are disabled");

        if (from != address(0)) {
            // Skip checks for minting
            require(verifiedHolders[from], "Sender not verified");
            require(
                amount <= transferLimits[from] || transferLimits[from] == 0,
                "Transfer limit exceeded"
            );
        }

        if (to != address(0)) {
            // Skip checks for burning
            require(verifiedHolders[to], "Recipient not verified");
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
