// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {console2} from "forge-std/Test.sol";
import {FtsoV2Interface} from "flare-periphery/src/coston2/FtsoV2Interface.sol";
import {IFeeCalculator} from "flare-periphery/src/coston2/IFeeCalculator.sol";
import "./interfaces/IFtsoV2FeedConsumer.sol";

/**
 * @title FTSO V2 Feed Consumer
 * @dev Interface with Flare's FTSO (Flare Time Series Oracle) V2 for price feeds
 *
 * This contract provides a bridge to Flare's decentralized oracle system that:
 * - Retrieves price data for FLR/USD and other assets
 * - Handles fee calculation and payment for oracle queries
 * - Provides a standardized interface for accessing price feeds
 *
 * The FTSO V2 Feed Consumer is essential for the BSD Insurance Protocol as it:
 * - Enables accurate valuation of RWA tokens
 * - Provides real-time price data for insurance calculations
 * - Supports risk assessment with current market data
 * - Facilitates premium calculations based on current asset values
 *
 * This contract is designed to work with Flare's Coston2 testnet and can be
 * adapted for other Flare networks by updating the feed IDs and interfaces.
 */
contract FtsoV2FeedConsumer is IFtsoV2FeedConsumer {
    // Custom errors
    error InvalidSymbol();
    error SymbolAlreadyMonitored();
    error SymbolNotMonitored();
    error InvalidTimestamp();

    FtsoV2Interface internal ftsoV2;
    IFeeCalculator internal feeCalc;
    bytes21[] public feedIds;
    bytes21 public flrUsdId;
    uint256 public fee;

    // Mapping from symbol to PriceFeed
    mapping(string => PriceFeed) private _priceFeeds;

    // Array to store all monitored symbols
    string[] private _monitoredSymbols;

    // Mapping to track if a symbol is monitored
    mapping(string => bool) private _isMonitored;

    // Default maximum age for price validity (5 minutes)
    uint256 public constant DEFAULT_MAX_AGE = 300;

    /**
     * @dev Constructor initializes the contract with FTSO V2 and fee calculator addresses
     * @param _ftsoV2 Address of the FTSO V2 contract
     * @param _feeCalc Address of the fee calculator contract
     * @param _flrUsdId Feed ID for FLR/USD price data
     */
    constructor(address _ftsoV2, address _feeCalc, bytes21 _flrUsdId) {
        ftsoV2 = FtsoV2Interface(_ftsoV2);
        feeCalc = IFeeCalculator(_feeCalc);
        flrUsdId = _flrUsdId;
        feedIds.push(_flrUsdId);
    }

    /**
     * @dev Calculate the fee required to query the FTSO feed
     * @return _fee The calculated fee in native currency
     *
     * This function determines the fee required to query the FTSO feed
     * based on the feed IDs being accessed. The fee must be paid when
     * calling getFlrUsdPrice() to retrieve price data.
     */
    function checkFees() external returns (uint256 _fee) {
        fee = feeCalc.calculateFeeByIds(feedIds);
        return fee;
    }

    /**
     * @dev Retrieve the current FLR/USD price from the FTSO feed
     * @return feedValue The current price value
     * @return decimals The number of decimal places for the price
     * @return timestamp The timestamp when the price was recorded
     *
     * This function queries the FTSO V2 feed for the current FLR/USD price.
     * It requires a fee payment (msg.value) that matches the fee calculated
     * by checkFees(). The function returns the price value, decimal places,
     * and the timestamp when the price was recorded.
     *
     * Note: This function includes console logging for debugging purposes
     * and should be modified for production use.
     */
    function getFlrUsdPrice() external payable returns (uint256, int8, uint64) {
        (uint256 feedValue, int8 decimals, uint64 timestamp) = ftsoV2
            .getFeedById{value: msg.value}(flrUsdId);

        if (fee != msg.value) {
            console2.log("msg.value %i doesn't match fee %i", msg.value, fee);
        } else {
            console2.log("msg.value matches fee");
        }

        console2.log("feedValue %i", feedValue);
        console2.log("decimals %i", decimals);
        console2.log("timestamp %i", timestamp);
        return (feedValue, decimals, timestamp);
    }

    /**
     * @dev Add a new price feed to monitor
     * @param symbol The symbol of the asset to monitor
     * @param decimals The number of decimal places for the price
     * @return success Whether the price feed was added successfully
     */
    function addPriceFeed(
        string calldata symbol,
        uint8 decimals
    ) external override returns (bool success) {
        if (bytes(symbol).length == 0) revert InvalidSymbol();
        if (_isMonitored[symbol]) revert SymbolAlreadyMonitored();

        _priceFeeds[symbol] = PriceFeed({
            symbol: symbol,
            price: 0,
            timestamp: 0,
            decimals: decimals,
            valid: false
        });

        _monitoredSymbols.push(symbol);
        _isMonitored[symbol] = true;

        emit PriceFeedAdded(symbol, decimals);

        return true;
    }

    /**
     * @dev Remove a price feed from monitoring
     * @param symbol The symbol of the asset to stop monitoring
     * @return success Whether the price feed was removed successfully
     */
    function removePriceFeed(
        string calldata symbol
    ) external override returns (bool success) {
        if (!_isMonitored[symbol]) revert SymbolNotMonitored();

        // Find the index of the symbol in the array
        uint256 index = 0;
        for (uint256 i = 0; i < _monitoredSymbols.length; i++) {
            if (
                keccak256(bytes(_monitoredSymbols[i])) ==
                keccak256(bytes(symbol))
            ) {
                index = i;
                break;
            }
        }

        // Remove the symbol from the array
        _monitoredSymbols[index] = _monitoredSymbols[
            _monitoredSymbols.length - 1
        ];
        _monitoredSymbols.pop();

        // Remove the price feed
        delete _priceFeeds[symbol];
        _isMonitored[symbol] = false;

        emit PriceFeedRemoved(symbol);

        return true;
    }

    /**
     * @dev Update the price for a specific asset
     * @param symbol The symbol of the asset
     * @param price The new price
     * @param timestamp The timestamp of the price update
     * @return success Whether the price was updated successfully
     */
    function updatePrice(
        string calldata symbol,
        uint256 price,
        uint256 timestamp
    ) external override returns (bool success) {
        if (!_isMonitored[symbol]) revert SymbolNotMonitored();
        if (timestamp > block.timestamp) revert InvalidTimestamp();

        PriceFeed storage feed = _priceFeeds[symbol];
        feed.price = price;
        feed.timestamp = timestamp;
        feed.valid = true;

        emit PriceFeedUpdated(symbol, price, timestamp);

        return true;
    }

    /**
     * @dev Get the current price for a specific asset
     * @param symbol The symbol of the asset
     * @return price The current price
     * @return timestamp The timestamp when the price was last updated
     * @return valid Whether the price feed is currently valid
     */
    function getPrice(
        string calldata symbol
    )
        external
        view
        override
        returns (uint256 price, uint256 timestamp, bool valid)
    {
        if (!_isMonitored[symbol]) revert SymbolNotMonitored();

        PriceFeed memory feed = _priceFeeds[symbol];
        return (feed.price, feed.timestamp, feed.valid);
    }

    /**
     * @dev Get information about a specific price feed
     * @param symbol The symbol of the asset
     * @return feed The price feed information
     */
    function getPriceFeed(
        string calldata symbol
    ) external view override returns (PriceFeed memory feed) {
        if (!_isMonitored[symbol]) revert SymbolNotMonitored();

        return _priceFeeds[symbol];
    }

    /**
     * @dev Get a list of all monitored price feeds
     * @return symbols Array of symbols for all monitored price feeds
     */
    function getMonitoredSymbols()
        external
        view
        override
        returns (string[] memory symbols)
    {
        return _monitoredSymbols;
    }

    /**
     * @dev Check if a price feed is valid (not stale)
     * @param symbol The symbol of the asset
     * @param maxAge The maximum age in seconds for a valid price
     * @return valid Whether the price feed is valid
     */
    function isPriceValid(
        string calldata symbol,
        uint256 maxAge
    ) external view override returns (bool valid) {
        if (!_isMonitored[symbol]) revert SymbolNotMonitored();

        PriceFeed memory feed = _priceFeeds[symbol];

        if (!feed.valid) {
            return false;
        }

        if (feed.timestamp == 0) {
            return false;
        }

        return (block.timestamp - feed.timestamp) <= maxAge;
    }

    /**
     * @dev Internal function to check if a price feed is valid using the default max age
     * @param symbol The symbol of the asset
     * @return valid Whether the price feed is valid
     */
    function _isPriceValid(
        string memory symbol
    ) internal view returns (bool valid) {
        return this.isPriceValid(symbol, DEFAULT_MAX_AGE);
    }
}
