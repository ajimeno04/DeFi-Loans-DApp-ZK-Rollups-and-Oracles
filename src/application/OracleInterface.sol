// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/IPriceFeed.sol";

contract OracleInterface {
    IPriceFeed public priceFeed;
    uint256 public priceUpdateThreshold = 1 hours; // Maximum allowed staleness for price data

    /**
     * @dev Constructor to initialize the OracleInterface with a Chainlink PriceFeed.
     * @param _priceFeed Address of the Chainlink PriceFeed contract.
     */
    constructor(address _priceFeed) {
        require(_priceFeed != address(0), "Invalid PriceFeed address");
        priceFeed = IPriceFeed(_priceFeed);
    }

    /**
     * @dev Returns the latest price from the Chainlink PriceFeed.
     * @return The latest price as an int256.
     */
    function getLatestPrice() public view returns (int256) {
        int256 price = priceFeed.latestAnswer();
        require(price > 0, "Invalid price from Chainlink");
        return price;
    }

    /**
     * @dev Checks if the latest price data is recent enough.
     * @return True if the price data is recent, false otherwise.
     */
    function isPriceRecent() public view returns (bool) {
        uint256 lastUpdated = priceFeed.latestTimestamp();
        return (block.timestamp - lastUpdated) <= priceUpdateThreshold;
    }
}
