// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/flare/Vault.sol";
import "../contracts/flare/DataVerification.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IEVMTransaction} from "flare-periphery/src/coston2/IEVMTransaction.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract VaultTest is Test {
    Vault public vault;
    DataVerification public dataVerification;
    MockERC20 public reserveToken;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy mock contracts
        vm.startPrank(owner);
        dataVerification = new DataVerification();
        reserveToken = new MockERC20("Reserve Token", "RST");

        // Set up DataVerification
        dataVerification.setVerificationAddress(address(this));

        // Deploy Vault contract
        vault = new Vault(
            address(reserveToken),
            payable(address(dataVerification))
        );
        vm.stopPrank();

        // Give test users some tokens
        vm.startPrank(owner);
        reserveToken.mint(user1, 2000 ether); // Increased initial balance
        reserveToken.mint(user2, 2000 ether);
        vm.stopPrank();

        // Approve vault to spend tokens
        vm.startPrank(user1);
        reserveToken.approve(address(vault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        reserveToken.approve(address(vault), type(uint256).max);
        vm.stopPrank();
    }

    function test_Constructor() public view {
        assertEq(address(vault.reserveToken()), address(reserveToken));
        assertEq(address(vault.dataVerification()), address(dataVerification));
        assertEq(vault.totalReserves(), 0);
        assertEq(vault.totalClaims(), 0);
    }

    function test_DepositReserves() public {
        vm.startPrank(user1);
        vault.depositReserves(100 ether);
        assertEq(vault.totalReserves(), 100 ether);
        assertEq(reserveToken.balanceOf(address(vault)), 100 ether);
    }

    function test_WithdrawReserves() public {
        // First deposit more than minimum reserves
        vm.startPrank(user1);
        vault.depositReserves(2000 ether);
        vm.stopPrank();

        // Then withdraw as owner
        vm.startPrank(owner);
        vault.withdrawReserves(500 ether);
        assertEq(vault.totalReserves(), 1500 ether);
        assertEq(reserveToken.balanceOf(address(vault)), 1500 ether);
    }

    function test_RevertWhenNonOwnerWithdraws() public {
        vm.startPrank(user1);
        vault.depositReserves(1000 ether);

        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                user1
            )
        );
        vault.withdrawReserves(500 ether);
    }

    function test_RevertWhenWithdrawingBelowMinimum() public {
        vm.startPrank(user1);
        vault.depositReserves(1000 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSignature("BelowMinimumReserve()"));
        vault.withdrawReserves(901 ether); // Would leave less than MINIMUM_RESERVE
    }

    function test_ProcessClaim() public {
        // First deposit some reserves
        vm.startPrank(user1);
        vault.depositReserves(1000 ether);
        vm.stopPrank();

        // Create proof structure
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
            merkleProof: new bytes32[](0),
            data: response
        });

        bytes memory encodedProof = abi.encode(proof);

        // Process claim (maximum 80% of reserves = 800 ether)
        bytes32 requestId = bytes32("test_request_id");
        uint256 claimAmount = 500 ether;

        vm.startPrank(user2);
        vault.processClaim(requestId, encodedProof, claimAmount);

        assertEq(vault.totalClaims(), claimAmount);
        assertEq(vault.totalReserves(), 500 ether);
        assertEq(reserveToken.balanceOf(user2), 2500 ether); // Initial 2000 + 500 claimed
    }

    function test_RevertWhenClaimExceedsMaximumRatio() public {
        // First deposit some reserves
        vm.startPrank(user1);
        vault.depositReserves(1000 ether);
        vm.stopPrank();

        // Create proof structure
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
            merkleProof: new bytes32[](0),
            data: response
        });

        bytes memory encodedProof = abi.encode(proof);

        // Try to claim more than 80% of reserves
        bytes32 requestId = bytes32("test_request_id");
        uint256 claimAmount = 801 ether;

        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSignature("ClaimExceedsMaximumRatio()"));
        vault.processClaim(requestId, encodedProof, claimAmount);
    }

    function test_GetReserveRatio() public {
        // Test with zero reserves
        assertEq(vault.getReserveRatio(), 0);

        // Deposit some reserves
        vm.startPrank(user1);
        vault.depositReserves(1000 ether);
        vm.stopPrank();

        // Test with zero claims
        assertEq(vault.getReserveRatio(), 0);
        assertEq(vault.totalClaims(), 0);
        assertEq(vault.totalReserves(), 1000 ether);

        // Create proof structure for claims
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
            merkleProof: new bytes32[](0),
            data: response
        });

        bytes memory encodedProof = abi.encode(proof);

        // Test with 25% claims
        vm.startPrank(user2);
        vault.processClaim(
            bytes32("test_request_id1"),
            encodedProof,
            250 ether
        );
        assertEq(vault.totalClaims(), 250 ether);
        assertEq(vault.totalReserves(), 750 ether);
        assertEq(vault.getReserveRatio(), 33); // 250/750 * 100 ≈ 33%

        // Test with 50% total claims
        vault.processClaim(
            bytes32("test_request_id2"),
            encodedProof,
            250 ether
        );
        assertEq(vault.totalClaims(), 500 ether);
        assertEq(vault.totalReserves(), 500 ether);
        assertEq(vault.getReserveRatio(), 100); // 500/500 * 100 = 100%
        vm.stopPrank();
    }

    function test_GetAvailableReserves() public {
        // First deposit some reserves
        vm.startPrank(user1);
        vault.depositReserves(1000 ether);
        vm.stopPrank();

        assertEq(vault.totalReserves(), 1000 ether);
        assertEq(vault.totalClaims(), 0);
        assertEq(vault.getAvailableReserves(), 1000 ether);

        // Create proof structure
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
            merkleProof: new bytes32[](0),
            data: response
        });

        bytes memory encodedProof = abi.encode(proof);

        // Process a claim
        bytes32 requestId = bytes32("test_request_id");
        uint256 claimAmount = 400 ether;

        vm.startPrank(user2);
        vault.processClaim(requestId, encodedProof, claimAmount);

        assertEq(vault.totalReserves(), 600 ether);
        assertEq(vault.totalClaims(), 400 ether);
        assertEq(vault.getAvailableReserves(), 200 ether); // 600 - 400 = 200
    }

    // Mock function for verification
    function verify(bytes32, bytes memory) external pure returns (bool) {
        return true;
    }
}
