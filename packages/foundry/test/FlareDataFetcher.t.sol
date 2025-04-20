// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/flare/FlareDataFetcher.sol";

contract FlareDataFetcherTest is Test {
    FlareDataFetcher public dataFetcher;
    address public owner;
    address public user;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        // Give test users some ETH
        vm.deal(owner, 100 ether);
        vm.deal(user, 100 ether);

        vm.startPrank(owner);
        dataFetcher = new FlareDataFetcher();
        vm.stopPrank();
    }

    function test_RequestData() public {
        vm.startPrank(user);

        IFlareDataFetcher.DataRequest memory request = IFlareDataFetcher
            .DataRequest({
                url: "https://api.example.com/data",
                path: "/test",
                headers: "",
                timeout: 300
            });

        bytes32 requestId = dataFetcher.requestData{
            value: dataFetcher.MINIMUM_FEE()
        }(request);

        // Verify request was stored
        IFlareDataFetcher.DataRequest memory storedRequest = dataFetcher
            .getRequest(requestId);
        assertEq(storedRequest.url, request.url);
        assertEq(storedRequest.path, request.path);
        assertEq(storedRequest.timeout, request.timeout);
    }

    function test_FulfillRequest() public {
        vm.startPrank(user);

        IFlareDataFetcher.DataRequest memory request = IFlareDataFetcher
            .DataRequest({
                url: "https://api.example.com/data",
                path: "/test",
                headers: "",
                timeout: 300
            });

        bytes32 requestId = dataFetcher.requestData{
            value: dataFetcher.MINIMUM_FEE()
        }(request);
        vm.stopPrank();

        // Fulfill request as owner
        vm.startPrank(owner);
        bytes memory responseData = abi.encode("test response");
        dataFetcher.fulfillRequest(requestId, responseData, true);

        // Verify response
        IFlareDataFetcher.DataResponse memory response = dataFetcher
            .getResponse(requestId);
        assertTrue(response.success);
        assertEq(response.data, responseData);
    }

    function test_WithdrawFees() public {
        vm.startPrank(user);

        IFlareDataFetcher.DataRequest memory request = IFlareDataFetcher
            .DataRequest({
                url: "https://api.example.com/data",
                path: "/test",
                headers: "",
                timeout: 300
            });

        dataFetcher.requestData{value: dataFetcher.MINIMUM_FEE()}(request);
        vm.stopPrank();

        // Withdraw fees as owner
        vm.startPrank(owner);
        uint256 balanceBefore = owner.balance;
        dataFetcher.withdrawFees();
        uint256 balanceAfter = owner.balance;

        assertTrue(balanceAfter > balanceBefore);
    }

    function test_RevertWhenNonOwnerFulfillsRequest() public {
        vm.startPrank(user);

        IFlareDataFetcher.DataRequest memory request = IFlareDataFetcher
            .DataRequest({
                url: "https://api.example.com/data",
                path: "/test",
                headers: "",
                timeout: 300
            });

        bytes32 requestId = dataFetcher.requestData{
            value: dataFetcher.MINIMUM_FEE()
        }(request);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        dataFetcher.fulfillRequest(requestId, abi.encode("test"), true);
    }

    function test_RevertWhenRequestNotFound() public {
        bytes32 nonExistentRequestId = bytes32("non-existent");

        vm.expectRevert(FlareDataFetcher.RequestNotFound.selector);
        dataFetcher.getResponse(nonExistentRequestId);
    }

    function test_RevertWhenRequestAlreadyCompleted() public {
        vm.startPrank(user);

        IFlareDataFetcher.DataRequest memory request = IFlareDataFetcher
            .DataRequest({
                url: "https://api.example.com/data",
                path: "/test",
                headers: "",
                timeout: 300
            });

        bytes32 requestId = dataFetcher.requestData{
            value: dataFetcher.MINIMUM_FEE()
        }(request);
        vm.stopPrank();

        // Fulfill request first time
        vm.startPrank(owner);
        dataFetcher.fulfillRequest(requestId, abi.encode("test"), true);

        // Try to fulfill again
        vm.expectRevert(FlareDataFetcher.RequestAlreadyCompleted.selector);
        dataFetcher.fulfillRequest(requestId, abi.encode("test"), true);
    }
}
