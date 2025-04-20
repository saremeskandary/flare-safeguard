// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/flare/DataVerification.sol";
import "flare-periphery/src/coston2/IFdcHub.sol";
import "flare-periphery/src/coston2/IFdcVerification.sol";
import "flare-periphery/src/coston2/IFdcRequestFeeConfigurations.sol";
import "flare-periphery/src/coston2/IFdcInflationConfigurations.sol";
import "flare-periphery/src/coston2/IEVMTransaction.sol";

contract MockFdcHub is IFdcHub {
    function requestAttestation(bytes calldata _data) external payable {
        // Mock implementation
        emit AttestationRequest(_data, msg.value);
    }

    function requestsOffsetSeconds() external view returns (uint8) {
        return 1;
    }

    function fdcInflationConfigurations()
        external
        view
        returns (IFdcInflationConfigurations)
    {
        return IFdcInflationConfigurations(address(0));
    }

    function fdcRequestFeeConfigurations()
        external
        view
        returns (IFdcRequestFeeConfigurations)
    {
        return IFdcRequestFeeConfigurations(address(this));
    }

    function getRequestFee(bytes calldata) external pure returns (uint256) {
        return 0.1 ether;
    }
}

contract MockFdcVerification is IFdcVerification {
    function verifyAddressValidity(
        IAddressValidity.Proof calldata
    ) external pure returns (bool) {
        return true;
    }

    function verifyBalanceDecreasingTransaction(
        IBalanceDecreasingTransaction.Proof calldata
    ) external pure returns (bool) {
        return true;
    }

    function verifyConfirmedBlockHeightExists(
        IConfirmedBlockHeightExists.Proof calldata
    ) external pure returns (bool) {
        return true;
    }

    function verifyEVMTransaction(
        IEVMTransaction.Proof calldata
    ) external pure returns (bool) {
        return true;
    }

    function verifyPayment(
        IPayment.Proof calldata
    ) external pure returns (bool) {
        return true;
    }

    function verifyReferencedPaymentNonexistence(
        IReferencedPaymentNonexistence.Proof calldata
    ) external pure returns (bool) {
        return true;
    }

    function verify(
        bytes32 requestId,
        bytes calldata proof
    ) external pure returns (bool) {
        return true;
    }
}

contract DataVerificationTest is Test {
    DataVerification public dataVerification;
    MockFdcHub public mockFdcHub;
    MockFdcVerification public mockFdcVerification;

    address public owner;
    address public user;

    event AttestationRequested(bytes32 indexed requestId);

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        // Deploy mock contracts
        mockFdcHub = new MockFdcHub();
        mockFdcVerification = new MockFdcVerification();

        // Deploy DataVerification contract
        vm.startPrank(owner);
        dataVerification = new DataVerification();

        // Set FDC contracts
        dataVerification.setFdcHub(address(mockFdcHub));
        dataVerification.setVerificationAddress(address(mockFdcVerification));

        // Set fee
        dataVerification.setFee(0.1 ether);
        vm.stopPrank();

        // Give test users some ETH
        vm.deal(owner, 100 ether);
        vm.deal(user, 100 ether);
    }

    function test_Constructor() public {
        DataVerification newVerification = new DataVerification();
        assertEq(address(newVerification.fdcHub()), address(0));
        assertEq(address(newVerification.verificationAddress()), address(0));
    }

    function test_SetFdcHub() public {
        vm.startPrank(owner);
        address newHub = makeAddr("newHub");
        dataVerification.setFdcHub(newHub);
        assertEq(address(dataVerification.fdcHub()), newHub);
    }

    function test_SetFdcVerification() public {
        vm.startPrank(owner);
        address newVerification = makeAddr("newVerification");
        dataVerification.setVerificationAddress(newVerification);
        assertEq(
            address(dataVerification.verificationAddress()),
            newVerification
        );
    }

    function test_SubmitAttestationRequest() public {
        vm.startPrank(user);

        bytes memory request = abi.encode("test_request");
        bytes32 expectedRequestId = keccak256(
            abi.encodePacked(block.timestamp, user, request)
        );

        vm.expectEmit(true, false, false, false);
        emit AttestationRequested(expectedRequestId);

        dataVerification.submitAttestationRequest{value: 0.1 ether}(request);
    }

    function test_VerifyAttestation() public {
        bytes32 requestId = bytes32("test_request_id");
        bytes32[] memory merkleProof = new bytes32[](0);

        IEVMTransaction.RequestBody memory requestBody = IEVMTransaction
            .RequestBody({
                transactionHash: bytes32(0),
                requiredConfirmations: 0,
                provideInput: false,
                listEvents: false,
                logIndices: new uint32[](0)
            });

        IEVMTransaction.ResponseBody memory responseBody = IEVMTransaction
            .ResponseBody({
                blockNumber: 0,
                timestamp: 0,
                sourceAddress: address(0),
                isDeployment: false,
                receivingAddress: address(0),
                value: 0,
                input: hex"",
                status: 1,
                events: new IEVMTransaction.Event[](0)
            });

        IEVMTransaction.Response memory response = IEVMTransaction.Response({
            attestationType: bytes32(0),
            sourceId: bytes32(0),
            votingRound: 0,
            lowestUsedTimestamp: 0,
            requestBody: requestBody,
            responseBody: responseBody
        });

        IEVMTransaction.Proof memory proof = IEVMTransaction.Proof({
            merkleProof: merkleProof,
            data: response
        });

        bytes memory encodedProof = abi.encode(proof);
        bool success = dataVerification.verifyAttestation(
            requestId,
            encodedProof
        );
        assertTrue(success);
    }

    function test_WithdrawFees() public {
        // Send some ETH to the contract
        vm.deal(address(dataVerification), 1 ether);
        dataVerification.submitAttestationRequest{value: 1 ether}("test");

        vm.startPrank(owner);
        uint256 balanceBefore = owner.balance;
        dataVerification.withdrawFees();
        uint256 balanceAfter = owner.balance;

        assertEq(balanceAfter - balanceBefore, 1 ether);
        assertEq(address(dataVerification).balance, 0);
    }

    function test_RevertWhenInsufficientFee() public {
        vm.startPrank(user);

        bytes memory request = abi.encode("test_request");
        vm.expectRevert("Insufficient fee");
        dataVerification.submitAttestationRequest{value: 0.05 ether}(request);
    }

    function test_RevertWhenNonOwnerWithdraws() public {
        vm.deal(address(dataVerification), 1 ether);
        dataVerification.submitAttestationRequest{value: 1 ether}("test");

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        dataVerification.withdrawFees();
    }

    function test_RevertWhenNoFeesToWithdraw() public {
        vm.startPrank(owner);
        vm.expectRevert("No fees to withdraw");
        dataVerification.withdrawFees();
    }
}
