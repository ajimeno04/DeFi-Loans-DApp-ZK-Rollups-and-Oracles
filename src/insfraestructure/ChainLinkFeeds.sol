// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IPriceFeed.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract ChainlinkFeeds is Ownable {
    IPriceFeed public priceFeed;
    uint256 public priceUpdateThreshold = 1 hours;

    event PriceFeedUpdated(address indexed oldFeed, address indexed newFeed);
    event PriceUpdated(address indexed feed, uint256 price, uint256 timestamp);

    /**
     * @dev Constructor to initialize the ChainlinkFeeds contract with a PriceFeed address.
     * @param _priceFeed Address of the initial Chainlink PriceFeed contract.
     */
    constructor(address _priceFeed) Ownable(msg.sender) { // Call the Ownable constructor explicitly
        require(_priceFeed != address(0), "Invalid PriceFeed address");
        priceFeed = IPriceFeed(_priceFeed);
    }

    /**
     * @dev Updates the address of the Chainlink PriceFeed. Only the owner can call this function.
     * @param _newPriceFeed Address of the new Chainlink PriceFeed contract.
     */
    function updatePriceFeed(address _newPriceFeed) external onlyOwner {
        require(_newPriceFeed != address(0), "Invalid PriceFeed address");
        address oldFeed = address(priceFeed);
        priceFeed = IPriceFeed(_newPriceFeed);
        emit PriceFeedUpdated(oldFeed, _newPriceFeed);
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
     * @dev Checks if the latest price data is recent.
     * @return True if the price data is recent, false otherwise.
     */
    function isPriceRecent() public view returns (bool) {
        uint256 lastUpdated = priceFeed.latestTimestamp();
        return (block.timestamp - lastUpdated) <= priceUpdateThreshold;
    }

    /**
     * @dev Emits an event with the latest price if it's recent enough.
     */
    function updatePrice() external {
        require(isPriceRecent(), "Price data is outdated");
        int256 price = getLatestPrice();
        emit PriceUpdated(address(priceFeed), uint256(price), block.timestamp);
    }
}
