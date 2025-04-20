// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/flare/FlareDataFetcher.sol";
import "../contracts/flare/FlareDataRequest.sol";

contract MockFlareDataRequest is FlareDataRequest {
    constructor(
        address dataFetcherAddress_
    ) FlareDataRequest(dataFetcherAddress_) {}

    function callVaultHandleRWAPayment() public override {}
}

contract FlareDataRequestTest is Test {
    FlareDataFetcher public dataFetcher;
    MockFlareDataRequest public dataRequest;
    address public owner;
    address public user;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        vm.startPrank(owner);
        dataFetcher = new FlareDataFetcher();
        dataRequest = new MockFlareDataRequest(address(dataFetcher));
        vm.stopPrank();
    }

    function test_Constructor() public {
        assertEq(address(dataRequest.dataFetcher()), address(dataFetcher));
        assertEq(dataRequest.dataFetcherAddress(), address(dataFetcher));
    }

    function test_SendGetLiquidationRequest() public {
        vm.startPrank(user);
        // Give user enough ETH for the fee
        vm.deal(user, dataFetcher.MINIMUM_FEE());

        dataRequest.sendGetLiquidationRequest{value: dataFetcher.MINIMUM_FEE()}(
            address(0),
            "TEST"
        );
        bytes32 requestId = dataRequest.s_lastRequestId();
        assertTrue(requestId != bytes32(0));
        vm.stopPrank();
        vm.startPrank(owner);
        dataFetcher.fulfillRequest(requestId, abi.encode(uint256(1)), true);
        dataRequest.checkResponse(requestId);
        assertTrue(dataRequest.s_settled());
    }

    function test_UpdateDataFetcher() public {
        address newFetcher = makeAddr("newFetcher");

        vm.startPrank(owner);
        dataRequest.updateDataFetcher(newFetcher);
        assertEq(address(dataRequest.dataFetcher()), newFetcher);
        assertEq(dataRequest.dataFetcherAddress(), newFetcher);
    }

    function test_RevertWhenNonOwnerUpdatesDataFetcher() public {
        address newFetcher = makeAddr("newFetcher");

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        dataRequest.updateDataFetcher(newFetcher);
    }

    function test_DataRequestWithInvalidFee() public {
        vm.startPrank(user);
        // Give user some ETH but less than minimum fee
        vm.deal(user, 0.009 ether); // Less than MINIMUM_FEE (0.01 ether)

        // Expect the DataRequestFailed event with InsufficientFee reason
        vm.expectEmit(true, true, true, true);
        emit FlareDataRequest.DataRequestFailed(bytes32(0), "InsufficientFee");

        dataRequest.sendGetLiquidationRequest{value: 0.009 ether}(
            address(0),
            "TEST"
        );
    }

    function test_DataRequestTimeout() public {
        vm.startPrank(user);
        // Give user enough ETH for the fee
        vm.deal(user, dataFetcher.MINIMUM_FEE());

        dataRequest.sendGetLiquidationRequest{value: dataFetcher.MINIMUM_FEE()}(
            address(0),
            "TEST"
        );
        bytes32 requestId = dataRequest.s_lastRequestId();
        dataRequest.checkResponse(requestId);
        assertFalse(dataRequest.s_settled());
    }
}
