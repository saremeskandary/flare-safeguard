// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/CrossChainClaimProcessor.sol";
import "../contracts/FdcTransferEventListener.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "flare-periphery/src/coston2/IEVMTransactionVerification.sol";
import "flare-periphery/src/coston2/IEVMTransaction.sol";
import "flare-periphery/src/coston2/ContractRegistry.sol";

// Mock BSD Token for testing
contract MockBSDToken is ERC20 {
    constructor() ERC20("Mock BSD Token", "mBSD") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

// Mock FDC Verification Contract
contract MockFdcVerification is IEVMTransactionVerification {
    function verifyEVMTransaction(
        IEVMTransaction.Proof calldata
    ) external pure returns (bool) {
        return true; // Always return true for testing
    }
}

// Mock Contract Registry
contract MockContractRegistry {
    MockFdcVerification public verification;
    mapping(bytes32 => address) public contractAddresses;

    constructor() {
        verification = new MockFdcVerification();
    }

    function getFdcVerification()
        external
        view
        returns (IEVMTransactionVerification)
    {
        return verification;
    }

    function getContractAddressByHash(
        bytes32 hash
    ) external view returns (address) {
        return address(verification);
    }
}

contract CrossChainClaimProcessorTest is Test {
    CrossChainClaimProcessor public processor;
    FdcTransferEventListener public listener;
    MockBSDToken public bsdToken;
    MockContractRegistry public mockRegistry;

    address public owner;
    address public user;
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
        mockRegistry = new MockContractRegistry();
        listener = new FdcTransferEventListener();
        processor = new CrossChainClaimProcessor(
            address(bsdToken),
            address(listener)
        );

        // Setup owner
        owner = address(this);
        user = address(0x3);

        // Fund accounts
        bsdToken.transfer(user, COVERAGE_AMOUNT);
        bsdToken.transfer(address(processor), COVERAGE_AMOUNT); // Fund processor with enough tokens for payouts
        vm.deal(user, 100 ether);

        // Setup approvals
        vm.prank(user);
        bsdToken.approve(address(processor), type(uint256).max);

        // Mock the ContractRegistry address
        vm.etch(
            address(0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019),
            address(mockRegistry).code
        );

        // Add USDC token to supported tokens
        listener.addSupportedToken(usdc, 11155111);

        // Mock the verification contract to always return true
        vm.mockCall(
            address(mockRegistry.verification()),
            abi.encodeWithSelector(
                IEVMTransactionVerification.verifyEVMTransaction.selector
            ),
            abi.encode(true)
        );
    }

    function testCreatePolicy() public {
        vm.prank(user);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        (
            address tokenAddress,
            uint256 coverageAmount,
            uint256 premium,
            uint256 startTime,
            uint256 endTime,
            bool isActive
        ) = processor.getPolicy(user);

        assertEq(tokenAddress, usdc);
        assertEq(coverageAmount, COVERAGE_AMOUNT);
        assertEq(premium, PREMIUM);
        assertTrue(isActive);
        assertEq(endTime - startTime, DURATION * 1 days);
    }

    function testSubmitCrossChainClaim() public {
        // Create policy first
        vm.prank(user);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit CrossChainClaimSubmitted(
            0, // First claim ID
            user,
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

        assertEq(claimInsured, user);
        assertEq(claimToken, usdc);
        assertEq(claimAmount_, claimAmount);
        assertEq(description, "Cross-chain claim");
        assertEq(uint256(status), uint256(ClaimProcessor.ClaimStatus.Pending));
        assertEq(verifier_, address(0));
        assertEq(rejectionReason, "");
    }

    // Helper function to create a mock proof
    function _createMockProof(
        bytes32 transactionHash,
        uint16 requiredConfirmations
    ) internal pure returns (IEVMTransaction.Proof memory) {
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
        return
            IEVMTransaction.Proof({merkleProof: merkleProof, data: response});
    }

    // Helper function to add a mock transfer event
    function _addMockTransferEvent(
        address from,
        address to,
        uint256 value,
        address tokenAddress,
        uint256 chainId
    ) internal {
        // Create a mock transfer event
        IFdcTransferEventListener.TokenTransfer
            memory transfer = IFdcTransferEventListener.TokenTransfer({
                from: from,
                to: to,
                value: value,
                tokenAddress: tokenAddress,
                chainId: chainId
            });

        // Add the transfer to the listener
        vm.mockCall(
            address(listener),
            abi.encodeWithSelector(
                IFdcTransferEventListener.getTokenTransfersByAddress.selector,
                to
            ),
            abi.encode(new IFdcTransferEventListener.TokenTransfer[](1))
        );

        // Add the transfer to the listener
        vm.prank(address(listener));
        listener.collectTransferEvents(
            _createMockProof(keccak256("test_tx"), 12)
        );

        // Mock the getTokenTransfersByAddress call to return our transfer
        IFdcTransferEventListener.TokenTransfer[]
            memory transfers = new IFdcTransferEventListener.TokenTransfer[](1);
        transfers[0] = transfer;
        vm.mockCall(
            address(listener),
            abi.encodeWithSelector(
                IFdcTransferEventListener.getTokenTransfersByAddress.selector,
                to
            ),
            abi.encode(transfers)
        );
    }

    // Helper function to verify claim details
    function _verifyClaimDetails(
        uint256 claimId,
        address expectedInsured,
        address expectedToken,
        uint256 expectedAmount,
        ClaimProcessor.ClaimStatus expectedStatus
    ) internal view {
        (
            address claimInsured,
            address claimToken,
            uint256 claimAmount,
            ,
            string memory description,
            ClaimProcessor.ClaimStatus status,
            ,
            string memory rejectionReason
        ) = processor.getClaim(claimId);

        assertEq(claimInsured, expectedInsured);
        assertEq(claimToken, expectedToken);
        assertEq(claimAmount, expectedAmount);
        assertEq(description, "Cross-chain claim");
        assertEq(uint256(status), uint256(expectedStatus));
        assertEq(rejectionReason, "");
    }

    function testVerifyCrossChainClaim() public {
        // Create policy first
        vm.prank(user);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(user);
        uint256 claimId = processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );

        // Add a mock transfer event
        _addMockTransferEvent(
            address(0), // from (any address)
            user, // to (the insured)
            claimAmount, // value (the claim amount)
            usdc, // token address (the insured token)
            chainId // chain ID (the same as in the claim)
        );

        // Create and verify proof
        IEVMTransaction.Proof memory proof = _createMockProof(
            transactionHash,
            requiredConfirmations
        );

        // Verify claim
        vm.prank(owner);
        processor.verifyCrossChainClaim(claimId, proof);

        // Verify claim status
        _verifyClaimDetails(
            claimId,
            user,
            usdc,
            claimAmount,
            ClaimProcessor.ClaimStatus.Approved
        );
    }

    function testProcessCrossChainClaim() public {
        // Create policy first
        vm.prank(user);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(user);
        uint256 claimId = processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );

        // Add a mock transfer event
        _addMockTransferEvent(
            address(0), // from (any address)
            user, // to (the insured)
            claimAmount, // value (the claim amount)
            usdc, // token address (the insured token)
            chainId // chain ID (the same as in the claim)
        );

        // Create and verify proof
        IEVMTransaction.Proof memory proof = _createMockProof(
            transactionHash,
            requiredConfirmations
        );

        // Verify claim
        vm.prank(owner);
        processor.verifyCrossChainClaim(claimId, proof);

        // Process claim
        vm.prank(owner);
        processor.processCrossChainClaim(claimId);

        // Verify claim was processed
        _verifyClaimDetails(
            claimId,
            user,
            usdc,
            claimAmount,
            ClaimProcessor.ClaimStatus.Paid
        );
    }

    function testFailSubmitClaimWithoutPolicy() public {
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(user);
        processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );
    }

    function testFailSubmitClaimExceedingCoverage() public {
        // Create policy first
        vm.prank(user);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = COVERAGE_AMOUNT + 1;

        vm.prank(user);
        processor.submitCrossChainClaim(
            claimAmount,
            transactionHash,
            chainId,
            requiredConfirmations
        );
    }

    function testFailVerifyClaimWithoutOwnerRole() public {
        // Create policy first
        vm.prank(user);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(user);
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

        // Try to verify claim without owner role
        vm.prank(user);
        processor.verifyCrossChainClaim(claimId, proof);
    }

    function testFailProcessClaimWithoutOwnerRole() public {
        // Create policy first
        vm.prank(user);
        processor.createPolicy(usdc, COVERAGE_AMOUNT, PREMIUM, DURATION);

        // Submit cross-chain claim
        bytes32 transactionHash = keccak256("test_tx");
        uint256 chainId = 11155111; // Sepolia
        uint16 requiredConfirmations = 12;
        uint256 claimAmount = 500 * 10 ** 18;

        vm.prank(user);
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
        vm.prank(owner);
        processor.verifyCrossChainClaim(claimId, proof);

        // Try to process claim without owner role
        vm.prank(user);
        processor.processCrossChainClaim(claimId);
    }
}
