// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "flare-periphery/src/coston2/ContractRegistry.sol";
import "flare-periphery/src/coston2/IFdcHub.sol";
import "flare-periphery/src/coston2/IFdcVerification.sol";
import "flare-periphery/src/coston2/IFdcRequestFeeConfigurations.sol";
import "flare-periphery/src/coston2/IEVMTransaction.sol";

interface IFlareDataFetcher {
    function fetch(bytes32 requestId) external view returns (bytes memory);
}

interface IFlareDataVerifier {
    function verify(
        bytes32 requestId,
        bytes calldata proof
    ) external view returns (bool);
}

/**
 * @title DataVerification
 * @notice Contract for verifying data using Flare Data Connector (FDC)
 */
contract DataVerification is Ownable {
    // Custom errors
    error InvalidFdcHubAddress();
    error InvalidVerificationAddress();
    error InsufficientFee();
    error FdcHubNotSet();
    error VerificationAddressNotSet();
    error DataVerifierNotSet();
    error NoFeesToWithdraw();
    error FeeWithdrawalFailed();
    error InvalidRequestId();
    error EmptyProof();

    IFlareDataFetcher public dataFetcher;
    IFlareDataVerifier public dataVerifier;
    address public fdcHub;
    address public verificationAddress;
    uint256 public fee;
    uint256 public accumulatedFees;

    event FdcHubSet(address indexed hub);
    event VerificationAddressSet(address indexed verifier);
    event FeeSet(uint256 fee);
    event AttestationRequested(bytes32 indexed requestId);
    event AttestationVerified(bytes32 indexed requestId, bool verified);
    event FeesWithdrawn(address indexed to, uint256 amount);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Set the FDC Hub contract address
     * @param _hub The address of the FDC Hub contract
     */
    function setFdcHub(address _hub) external onlyOwner {
        if (_hub == address(0)) revert InvalidFdcHubAddress();
        fdcHub = _hub;
        emit FdcHubSet(_hub);
    }

    /**
     * @notice Set the FDC Verification contract address
     * @param _verifier The address of the FDC Verification contract
     */
    function setVerificationAddress(address _verifier) external onlyOwner {
        if (_verifier == address(0)) revert InvalidVerificationAddress();
        verificationAddress = _verifier;
        dataVerifier = IFlareDataVerifier(_verifier);
        emit VerificationAddressSet(_verifier);
    }

    /**
     * @notice Set the fee for a request
     * @param _fee The fee amount
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit FeeSet(_fee);
    }

    /**
     * @notice Submit an attestation request to the FDC Hub
     * @param request The request data
     */
    function submitAttestationRequest(bytes calldata request) external payable {
        if (msg.value < fee) revert InsufficientFee();
        if (fdcHub == address(0)) revert FdcHubNotSet();

        accumulatedFees += msg.value;

        bytes32 requestId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, request)
        );

        IFdcHub(fdcHub).requestAttestation{value: msg.value}(request);
        emit AttestationRequested(requestId);
    }

    /**
     * @notice Verify an attestation using the FDC Verification contract
     * @param requestId The ID of the request to verify
     * @param proof The proof data
     * @return verified Whether the verification was successful
     */
    function verifyAttestation(
        bytes32 requestId,
        bytes calldata proof
    ) external returns (bool) {
        if (verificationAddress == address(0))
            revert VerificationAddressNotSet();
        if (dataVerifier == IFlareDataVerifier(address(0)))
            revert DataVerifierNotSet();
        if (requestId == bytes32(0)) revert InvalidRequestId();
        if (proof.length == 0) revert EmptyProof();

        IEVMTransaction.Proof memory decodedProof = abi.decode(
            proof,
            (IEVMTransaction.Proof)
        );
        bool verified = dataVerifier.verify(
            requestId,
            abi.encode(decodedProof)
        );
        emit AttestationVerified(requestId, verified);
        return verified;
    }

    /**
     * @notice Withdraw accumulated fees
     */
    function withdrawFees() external onlyOwner {
        if (accumulatedFees == 0) revert NoFeesToWithdraw();
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        (bool success, ) = owner().call{value: amount}("");
        if (!success) revert FeeWithdrawalFailed();
        emit FeesWithdrawn(owner(), amount);
    }

    receive() external payable {
        accumulatedFees += msg.value;
    }
}
