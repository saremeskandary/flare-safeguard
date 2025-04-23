// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IFtsoV2FeedConsumer
 * @dev Interface for the FtsoV2FeedConsumer component
 *
 * This interface defines the standard methods for interacting with the FtsoV2FeedConsumer,
 * which handles price feed data from Flare's FtsoV2 system for the BSD Insurance Protocol.
 */
interface IFtsoV2FeedConsumer {
    /**
     * @dev Structure to store information about a price feed
     * @param symbol The symbol of the asset (e.g., "BTC", "ETH")
     * @param price The current price of the asset
     * @param timestamp The timestamp when the price was last updated
     * @param decimals The number of decimal places for the price
     * @param valid Whether the price feed is currently valid
     */
    struct PriceFeed {
        string symbol;
        uint256 price;
        uint256 timestamp;
        uint8 decimals;
        bool valid;
    }

    /**
     * @dev Event emitted when a price feed is updated
     * @param symbol The symbol of the asset
     * @param price The new price
     * @param timestamp The timestamp of the update
     */
    event PriceFeedUpdated(
        string indexed symbol,
        uint256 price,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a price feed is added
     * @param symbol The symbol of the asset
     * @param decimals The number of decimal places for the price
     */
    event PriceFeedAdded(string indexed symbol, uint8 decimals);

    /**
     * @dev Event emitted when a price feed is removed
     * @param symbol The symbol of the asset
     */
    event PriceFeedRemoved(string indexed symbol);

    /**
     * @dev Add a new price feed to monitor
     * @param symbol The symbol of the asset to monitor
     * @param decimals The number of decimal places for the price
     * @return success Whether the price feed was added successfully
     */
    function addPriceFeed(
        string calldata symbol,
        uint8 decimals
    ) external returns (bool success);

    /**
     * @dev Remove a price feed from monitoring
     * @param symbol The symbol of the asset to stop monitoring
     * @return success Whether the price feed was removed successfully
     */
    function removePriceFeed(
        string calldata symbol
    ) external returns (bool success);

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
    ) external returns (bool success);

    /**
     * @dev Get the current price for a specific asset
     * @param symbol The symbol of the asset
     * @return price The current price
     * @return timestamp The timestamp when the price was last updated
     * @return valid Whether the price feed is currently valid
     */
    function getPrice(
        string calldata symbol
    ) external view returns (uint256 price, uint256 timestamp, bool valid);

    /**
     * @dev Get information about a specific price feed
     * @param symbol The symbol of the asset
     * @return feed The price feed information
     */
    function getPriceFeed(
        string calldata symbol
    ) external view returns (PriceFeed memory feed);

    /**
     * @dev Get a list of all monitored price feeds
     * @return symbols Array of symbols for all monitored price feeds
     */
    function getMonitoredSymbols()
        external
        view
        returns (string[] memory symbols);

    /**
     * @dev Check if a price feed is valid (not stale)
     * @param symbol The symbol of the asset
     * @param maxAge The maximum age in seconds for a valid price
     * @return valid Whether the price feed is valid
     */
    function isPriceValid(
        string calldata symbol,
        uint256 maxAge
    ) external view returns (bool valid);
}
