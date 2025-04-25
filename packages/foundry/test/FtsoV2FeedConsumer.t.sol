// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/FtsoV2FeedConsumer.sol";
import "flare-periphery/src/coston2/FtsoV2Interface.sol";
import "flare-periphery/src/coston2/IFeeCalculator.sol";

contract FtsoV2FeedConsumerTest is Test {
    FtsoV2FeedConsumer public consumer;
    address public mockFtso;
    address public mockFeeCalc;
    bytes21 public flrUsdId;

    event PriceUpdated(uint256 price, uint256 timestamp);

    function setUp() public {
        mockFtso = address(0x3);
        mockFeeCalc = address(0x4);
        flrUsdId = bytes21("FLR/USD");

        // Deploy the consumer with required parameters
        consumer = new FtsoV2FeedConsumer(mockFtso, mockFeeCalc, flrUsdId);
    }

    function testGetLatestPrice() public {
        uint256 price = 1000 ether;
        uint256 timestamp = block.timestamp;

        // Mock the FTSO price feed
        vm.mockCall(
            mockFtso,
            abi.encodeWithSignature("getFeedById(bytes21)"),
            abi.encode(price, int8(18), uint64(timestamp))
        );

        // Get the latest price
        (uint256 latestPrice, int8 decimals, uint64 latestTimestamp) = consumer
            .getFlrUsdPrice{value: 0.01 ether}();

        assertEq(latestPrice, price);
        assertEq(latestTimestamp, timestamp);
    }

    function test_RevertWhen_GetLatestPriceNoFee() public {
        vm.expectRevert();
        consumer.getFlrUsdPrice{value: 0}();
    }
}
