// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/FtsoV2FeedConsumer.sol";
import "flare-periphery/src/coston2/FtsoV2Interface.sol";
import "flare-periphery/src/coston2/IFeeCalculator.sol";

// Mock FtsoV2Interface for testing
contract MockFtsoV2Interface is FtsoV2Interface {
    uint256 private _feedValue;
    int8 private _decimals;
    uint64 private _timestamp;

    function setMockValues(
        uint256 feedValue,
        int8 decimals,
        uint64 timestamp
    ) external {
        _feedValue = feedValue;
        _decimals = decimals;
        _timestamp = timestamp;
    }

    function getFeedById(
        bytes21
    ) external payable returns (uint256, int8, uint64) {
        return (_feedValue, _decimals, _timestamp);
    }

    function getFeedByIdInWei(
        bytes21
    ) external payable returns (uint256, uint64) {
        return (_feedValue, _timestamp);
    }

    function getFeedByIndex(
        uint256
    ) external payable returns (uint256, int8, uint64) {
        return (_feedValue, _decimals, _timestamp);
    }

    function getFeedByIndexInWei(
        uint256
    ) external payable returns (uint256, uint64) {
        return (_feedValue, _timestamp);
    }

    function getFeedId(uint256) external view returns (bytes21) {
        return bytes21(uint168(0x123456789012345678901234567890123456789012));
    }

    function getFeedIndex(bytes21) external view returns (uint256) {
        return 0;
    }

    function getFeedsById(
        bytes21[] calldata
    ) external payable returns (uint256[] memory, int8[] memory, uint64) {
        uint256[] memory values = new uint256[](1);
        int8[] memory decimals = new int8[](1);
        values[0] = _feedValue;
        decimals[0] = _decimals;
        return (values, decimals, _timestamp);
    }

    function getFeedsByIdInWei(
        bytes21[] calldata
    ) external payable returns (uint256[] memory, uint64) {
        uint256[] memory values = new uint256[](1);
        values[0] = _feedValue;
        return (values, _timestamp);
    }

    function getFeedsByIndex(
        uint256[] calldata
    ) external payable returns (uint256[] memory, int8[] memory, uint64) {
        uint256[] memory values = new uint256[](1);
        int8[] memory decimals = new int8[](1);
        values[0] = _feedValue;
        decimals[0] = _decimals;
        return (values, decimals, _timestamp);
    }

    function getFeedsByIndexInWei(
        uint256[] calldata
    ) external payable returns (uint256[] memory, uint64) {
        uint256[] memory values = new uint256[](1);
        values[0] = _feedValue;
        return (values, _timestamp);
    }

    function verifyFeedData(
        FeedDataWithProof calldata
    ) external view returns (bool) {
        return true;
    }
}

// Mock IFeeCalculator for testing
contract MockFeeCalculator is IFeeCalculator {
    uint256 private _fee;

    function setMockFee(uint256 fee) external {
        _fee = fee;
    }

    function calculateFeeByIds(
        bytes21[] memory
    ) external view returns (uint256) {
        return _fee;
    }

    function calculateFeeByNames(
        string[] memory
    ) external view returns (uint256) {
        return _fee;
    }

    function calculateFeeById(bytes21) external view returns (uint256) {
        return _fee;
    }

    function calculateFeeByName(string memory) external view returns (uint256) {
        return _fee;
    }

    function calculateFeeByIndices(
        uint256[] memory
    ) external view returns (uint256) {
        return _fee;
    }
}

contract FtsoV2FeedConsumerTest is Test {
    FtsoV2FeedConsumer public feedConsumer;
    MockFtsoV2Interface public mockFtsoV2;
    MockFeeCalculator public mockFeeCalculator;

    address public admin = address(1);
    address public priceUpdater = address(2);
    address public feedManager = address(3);

    bytes21 public flrUsdId = bytes21("FLR/USD");
    uint256 public constant MOCK_FEE = 0.01 ether;
    uint256 public constant MOCK_FEED_VALUE = 100000000; // 1 FLR = $1.00
    int8 public constant MOCK_DECIMALS = 8;
    uint64 public constant MOCK_TIMESTAMP = 1677721600; // Some timestamp

    event PriceFeedAdded(string indexed symbol, uint8 decimals);
    event PriceFeedRemoved(string indexed symbol);
    event PriceFeedUpdated(
        string indexed symbol,
        uint256 price,
        uint256 timestamp
    );

    function setUp() public {
        // Deploy mock contracts
        mockFtsoV2 = new MockFtsoV2Interface();
        mockFeeCalculator = new MockFeeCalculator();

        // Set mock values
        mockFtsoV2.setMockValues(
            MOCK_FEED_VALUE,
            MOCK_DECIMALS,
            MOCK_TIMESTAMP
        );
        mockFeeCalculator.setMockFee(MOCK_FEE);

        // Deploy feed consumer
        feedConsumer = new FtsoV2FeedConsumer(
            address(mockFtsoV2),
            address(mockFeeCalculator),
            flrUsdId
        );

        // Setup roles
        feedConsumer.grantRole(feedConsumer.PRICE_UPDATER_ROLE(), priceUpdater);
        feedConsumer.grantRole(feedConsumer.FEED_MANAGER_ROLE(), feedManager);
    }

    function testCheckFees() public {
        uint256 fee = feedConsumer.checkFees();
        assertEq(fee, MOCK_FEE);
    }

    function testGetFlrUsdPrice() public {
        uint256 fee = feedConsumer.checkFees();

        (uint256 feedValue, int8 decimals, uint64 timestamp) = feedConsumer
            .getFlrUsdPrice{value: fee}();

        assertEq(feedValue, MOCK_FEED_VALUE);
        assertEq(decimals, MOCK_DECIMALS);
        assertEq(timestamp, MOCK_TIMESTAMP);
    }

    function testFailGetFlrUsdPriceWithIncorrectFee() public {
        uint256 fee = feedConsumer.checkFees();

        vm.expectRevert();
        feedConsumer.getFlrUsdPrice{value: fee - 1}();
    }

    function testAddPriceFeed() public {
        string memory symbol = "BTC/USD";
        uint8 decimals = 8;

        vm.prank(feedManager);
        vm.expectEmit(true, false, false, true);
        emit PriceFeedAdded(symbol, decimals);
        bool success = feedConsumer.addPriceFeed(symbol, decimals);

        assertTrue(success);

        // Verify the price feed was added
        IFtsoV2FeedConsumer.PriceFeed memory feed = feedConsumer.getPriceFeed(
            symbol
        );
        assertEq(feed.symbol, symbol);
        assertEq(feed.decimals, decimals);
        assertEq(feed.price, 0);
        assertEq(feed.timestamp, 0);
        assertFalse(feed.valid);

        // Verify the symbol is in the monitored symbols list
        string[] memory symbols = feedConsumer.getMonitoredSymbols();
        assertEq(symbols.length, 1);
        assertEq(symbols[0], symbol);
    }

    function testFailAddPriceFeedWithoutManagerRole() public {
        string memory symbol = "BTC/USD";
        uint8 decimals = 8;

        vm.prank(admin);
        feedConsumer.addPriceFeed(symbol, decimals);
    }

    function testFailAddDuplicatePriceFeed() public {
        string memory symbol = "BTC/USD";
        uint8 decimals = 8;

        vm.prank(feedManager);
        feedConsumer.addPriceFeed(symbol, decimals);

        vm.prank(feedManager);
        feedConsumer.addPriceFeed(symbol, decimals);
    }

    function testRemovePriceFeed() public {
        string memory symbol = "BTC/USD";
        uint8 decimals = 8;

        // Add price feed first
        vm.prank(feedManager);
        feedConsumer.addPriceFeed(symbol, decimals);

        // Remove price feed
        vm.prank(feedManager);
        vm.expectEmit(true, false, false, true);
        emit PriceFeedRemoved(symbol);
        bool success = feedConsumer.removePriceFeed(symbol);

        assertTrue(success);

        // Verify the price feed was removed by trying to get it (should revert)
        vm.expectRevert(abi.encodeWithSignature("SymbolNotMonitored()"));
        feedConsumer.getPriceFeed(symbol);

        // Verify the symbol is not in the monitored symbols list
        string[] memory symbols = feedConsumer.getMonitoredSymbols();
        assertEq(symbols.length, 0);
    }

    function testFailRemovePriceFeedWithoutManagerRole() public {
        string memory symbol = "BTC/USD";
        uint8 decimals = 8;

        // Add the price feed first
        vm.prank(feedManager);
        feedConsumer.addPriceFeed(symbol, decimals);

        // Try to remove the price feed without the manager role
        vm.prank(admin);
        feedConsumer.removePriceFeed(symbol);
    }

    function test_RevertWhen_RemoveNonExistentPriceFeed() public {
        string memory symbol = "BTC/USD";

        vm.prank(feedManager);
        vm.expectRevert(abi.encodeWithSignature("SymbolNotMonitored()"));
        feedConsumer.removePriceFeed(symbol);
    }

    function testUpdatePrice() public {
        string memory symbol = "BTC/USD";
        uint8 decimals = 8;
        uint256 price = 50000000000; // $50,000.00
        uint256 timestamp = block.timestamp;

        // Add the price feed first
        vm.prank(feedManager);
        feedConsumer.addPriceFeed(symbol, decimals);

        // Update the price
        vm.prank(priceUpdater);
        vm.expectEmit(true, false, false, true);
        emit PriceFeedUpdated(symbol, price, timestamp);
        bool success = feedConsumer.updatePrice(symbol, price, timestamp);

        assertTrue(success);

        // Verify the price was updated
        IFtsoV2FeedConsumer.PriceFeed memory feed = feedConsumer.getPriceFeed(
            symbol
        );
        assertEq(feed.price, price);
        assertEq(feed.timestamp, timestamp);
        assertTrue(feed.valid);

        // Verify the price can be retrieved
        (
            uint256 retrievedPrice,
            uint256 retrievedTimestamp,
            bool valid
        ) = feedConsumer.getPrice(symbol);
        assertEq(retrievedPrice, price);
        assertEq(retrievedTimestamp, timestamp);
        assertTrue(valid);
    }

    function testFailUpdatePriceWithoutUpdaterRole() public {
        string memory symbol = "BTC/USD";
        uint8 decimals = 8;
        uint256 price = 50000000000; // $50,000.00
        uint256 timestamp = block.timestamp;

        // Add the price feed first
        vm.prank(feedManager);
        feedConsumer.addPriceFeed(symbol, decimals);

        // Try to update the price without the updater role
        vm.prank(admin);
        feedConsumer.updatePrice(symbol, price, timestamp);
    }

    function testFailUpdatePriceForNonExistentFeed() public {
        string memory symbol = "BTC/USD";
        uint256 price = 50000000000; // $50,000.00
        uint256 timestamp = block.timestamp;

        vm.prank(priceUpdater);
        feedConsumer.updatePrice(symbol, price, timestamp);
    }

    function testFailUpdatePriceWithFutureTimestamp() public {
        string memory symbol = "BTC/USD";
        uint8 decimals = 8;
        uint256 price = 50000000000; // $50,000.00
        uint256 timestamp = block.timestamp + 1;

        // Add the price feed first
        vm.prank(feedManager);
        feedConsumer.addPriceFeed(symbol, decimals);

        // Try to update the price with a future timestamp
        vm.prank(priceUpdater);
        feedConsumer.updatePrice(symbol, price, timestamp);
    }

    function testIsPriceValid() public {
        string memory symbol = "BTC/USD";
        uint8 decimals = 8;
        uint256 price = 50000000000; // $50,000.00
        uint256 timestamp = block.timestamp;

        // Add the price feed first
        vm.prank(feedManager);
        feedConsumer.addPriceFeed(symbol, decimals);

        // Initially, the price should not be valid
        assertFalse(feedConsumer.isPriceValid(symbol, 300));

        // Update the price
        vm.prank(priceUpdater);
        feedConsumer.updatePrice(symbol, price, timestamp);

        // Now the price should be valid
        assertTrue(feedConsumer.isPriceValid(symbol, 300));

        // If we advance time by more than the max age, the price should no longer be valid
        vm.warp(block.timestamp + 301);
        assertFalse(feedConsumer.isPriceValid(symbol, 300));

        // But it should still be valid with a higher max age
        assertTrue(feedConsumer.isPriceValid(symbol, 301));
    }

    function testFailIsPriceValidForNonExistentFeed() public view {
        string memory symbol = "BTC/USD";

        feedConsumer.isPriceValid(symbol, 300);
    }
}
