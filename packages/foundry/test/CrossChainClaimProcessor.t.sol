// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/CrossChainClaimProcessor.sol";
import "../contracts/FdcTransferEventListener.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock BSD Token for testing
contract MockBSDToken is ERC20 {
    constructor() ERC20("Mock BSD Token", "mBSD") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

contract CrossChainClaimProcessorTest is Test {
    CrossChainClaimProcessor public processor;
    FdcTransferEventListener public listener;
    MockBSDToken public bsdToken;

    address public admin = address(1);
    address public verifier = address(2);
    address public insured = address(3);
    address public usdc = address(4);

    uint256 public constant COVERAGE_AMOUNT = 1000 * 10 ** 18;
    uint256 public constant PREMIUM = 100 * 10 ** 18;
    uint256 public constant DURATION = 30; // days

    event CrossChainClaimSubmitted(
        uint256 indexed claimId,
        address indexed insured,
        uint256 amount,
        bytes32 transactionHash,
        uint256 chainId
    );

    event CrossChainClaimVerified(
        uint256 indexed claimId,
        bytes32 transactionHash,
        uint256 chainId
    );

    function setUp() public {
        // Deploy contracts
        bsdToken = new MockBSDToken();
        listener = new FdcTransferEventListener();
        processor = new CrossChainClaimProcessor(
            address(bsdToken),
            address(listener)
        );

        // Setup roles
        processor.grantRole(processor.ADMIN_ROLE(), admin);
        processor.grantRole(processor.VERIFIER_ROLE(), verifier);

        // Fund accounts
        bsdToken.transfer(insured, COVERAGE_AMOUNT);
        vm.deal(insured, 100 ether);

        // Setup approvals
        vm.prank(insured);
        bsdToken.approve(address(processor), type(uint256).max);
    }

    function testCreatePolicy() public {
        vm.prank(insured);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        (
            address tokenAddress,
            uint256 coverageAmount,
            uint256 premium,
            uint256 startTime,
            uint256 endTime,
            bool isActive
        ) = processor.getPolicy(insured);

        assertEq(tokenAddress, usdc);
        assertEq(coverageAmount, COVERAGE_AMOUNT);
        assertEq(premium, PREMIUM);
        assertTrue(isActive);
        assertEq(endTime - startTime, DURATION * 1 days);
    }

    function testSubmitCrossChainClaim() public {
        // Create policy first
        vm.prank(insured);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(insured);
        vm.expectEmit(true, true, false, true);
        emit CrossChainClaimSubmitted(
            0, // First claim ID
            insured,
            claimAmount,
            transactionHash,
            chainId
        );
        uint256 claimId = processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );

        // Verify claim was created
        (
            address claimInsured,
            address claimToken,
            uint256 claimAmount_,
            uint256 timestamp,
            string memory description,
            ClaimProcessor.ClaimStatus status,
            address verifier_,
            string memory rejectionReason
        ) = processor.getClaim(claimId);

        assertEq(claimInsured, insured);
        assertEq(claimToken, usdc);
        assertEq(claimAmount_, claimAmount);
        assertEq(description, "Cross-chain claim");
        assertEq(uint256(status), uint256(ClaimProcessor.ClaimStatus.Pending));
        assertEq(verifier_, address(0));
        assertEq(rejectionReason, "");
    }

    function testVerifyCrossChainClaim() public {
        // Create policy first
        vm.prank(insured);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(insured);
        uint256 claimId = processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );

        // Create mock proof
        IEVMTransaction.RequestBody memory requestBody = IEVMTransaction
            .RequestBody({
                transactionHash: transactionHash,
                requiredConfirmations: requiredConfirmations,
                provideInput: false,
                listEvents: true,
                logIndices: new uint32[](0)
            });

        IEVMTransaction.ResponseBody memory responseBody;
        IEVMTransaction.Response memory response = IEVMTransaction.Response({
            attestationType: bytes32(0),
            sourceId: bytes32(0),
            votingRound: 0,
            lowestUsedTimestamp: 0,
            requestBody: requestBody,
            responseBody: responseBody
        });

        bytes32[] memory merkleProof = new bytes32[](0);
        IEVMTransaction.Proof memory proof = IEVMTransaction.Proof({
            merkleProof: merkleProof,
            data: response
        });

        // Add USDC token to supported tokens
        listener.addSupportedToken(usdc, chainId);

        // Verify claim
        vm.prank(verifier);
        vm.expectEmit(true, false, false, true);
        emit CrossChainClaimVerified(claimId, transactionHash, chainId);
        processor.verifyCrossChainClaim(claimId, proof);

        // Verify claim status was updated
        (, , , , , ClaimProcessor.ClaimStatus status, , ) = processor.getClaim(
            claimId
        );
        assertEq(uint256(status), uint256(ClaimProcessor.ClaimStatus.Approved));
    }

    function testProcessCrossChainClaim() public {
        // Create policy first
        vm.prank(insured);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(insured);
        uint256 claimId = processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );

        // Create mock proof
        IEVMTransaction.RequestBody memory requestBody = IEVMTransaction
            .RequestBody({
                transactionHash: transactionHash,
                requiredConfirmations: requiredConfirmations,
                provideInput: false,
                listEvents: true,
                logIndices: new uint32[](0)
            });

        IEVMTransaction.ResponseBody memory responseBody;
        IEVMTransaction.Response memory response = IEVMTransaction.Response({
            attestationType: bytes32(0),
            sourceId: bytes32(0),
            votingRound: 0,
            lowestUsedTimestamp: 0,
            requestBody: requestBody,
            responseBody: responseBody
        });

        bytes32[] memory merkleProof = new bytes32[](0);
        IEVMTransaction.Proof memory proof = IEVMTransaction.Proof({
            merkleProof: merkleProof,
            data: response
        });

        // Add USDC token to supported tokens
        listener.addSupportedToken(usdc, chainId);

        // Verify claim
        vm.prank(verifier);
        processor.verifyCrossChainClaim(claimId, proof);

        // Process claim
        vm.prank(admin);
        processor.processCrossChainClaim(claimId);

        // Verify claim status was updated
        (, , , , , ClaimProcessor.ClaimStatus status, , ) = processor.getClaim(
            claimId
        );
        assertEq(uint256(status), uint256(ClaimProcessor.ClaimStatus.Paid));
    }

    function testFailSubmitClaimWithoutPolicy() public {
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(insured);
        processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );
    }

    function testFailSubmitClaimExceedingCoverage() public {
        // Create policy first
        vm.prank(insured);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = COVERAGE_AMOUNT + 1;

        vm.prank(insured);
        processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );
    }

    function testFailVerifyClaimWithoutVerifierRole() public {
        // Create policy first
        vm.prank(insured);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(insured);
        uint256 claimId = processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );

        // Create mock proof
        IEVMTransaction.RequestBody memory requestBody = IEVMTransaction
            .RequestBody({
                transactionHash: transactionHash,
                requiredConfirmations: requiredConfirmations,
                provideInput: false,
                listEvents: true,
                logIndices: new uint32[](0)
            });

        IEVMTransaction.ResponseBody memory responseBody;
        IEVMTransaction.Response memory response = IEVMTransaction.Response({
            attestationType: bytes32(0),
            sourceId: bytes32(0),
            votingRound: 0,
            lowestUsedTimestamp: 0,
            requestBody: requestBody,
            responseBody: responseBody
        });

        bytes32[] memory merkleProof = new bytes32[](0);
        IEVMTransaction.Proof memory proof = IEVMTransaction.Proof({
            merkleProof: merkleProof,
            data: response
        });

        // Try to verify claim without verifier role
        vm.prank(insured);
        processor.verifyCrossChainClaim(claimId, proof);
    }

    function testFailProcessClaimWithoutAdminRole() public {
        // Create policy first
        vm.prank(insured);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(insured);
        uint256 claimId = processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );

        // Create mock proof
        IEVMTransaction.RequestBody memory requestBody = IEVMTransaction
            .RequestBody({
                transactionHash: transactionHash,
                requiredConfirmations: requiredConfirmations,
                provideInput: false,
                listEvents: true,
                logIndices: new uint32[](0)
            });

        IEVMTransaction.ResponseBody memory responseBody;
        IEVMTransaction.Response memory response = IEVMTransaction.Response({
            attestationType: bytes32(0),
            sourceId: bytes32(0),
            votingRound: 0,
            lowestUsedTimestamp: 0,
            requestBody: requestBody,
            responseBody: responseBody
        });

        bytes32[] memory merkleProof = new bytes32[](0);
        IEVMTransaction.Proof memory proof = IEVMTransaction.Proof({
            merkleProof: merkleProof,
            data: response
        });

        // Add USDC token to supported tokens
        listener.addSupportedToken(usdc, chainId);

        // Verify claim
        vm.prank(verifier);
        processor.verifyCrossChainClaim(claimId, proof);

        // Try to process claim without admin role
        vm.prank(insured);
        processor.processCrossChainClaim(claimId);
    }
}
