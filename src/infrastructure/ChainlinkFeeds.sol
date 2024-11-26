// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract ChainlinkFeeds is Ownable {
    // Struct to simulate price feed data
    struct FeedData {
        int256 price;
        uint256 lastUpdated;
    }

    FeedData public simulatedFeed; // Simulated feed for testing
    uint256 public priceUpdateThreshold = 1 hours;
    bool public isTestMode = false; // Flag to enable/disable test mode

    event PriceUpdated(address indexed feed, uint256 price, uint256 timestamp);
    event TestModeEnabled(bool enabled);

    /**
     * @dev Constructor to initialize the ChainlinkFeeds contract.
     */
    constructor() Ownable(msg.sender) {
        simulatedFeed = FeedData(1000 * 1e8, block.timestamp); // Default to $1000 (scaled by 1e8)
    }

    /**
     * @dev Enable or disable test mode. Only the owner can call this function.
     * @param _isTestMode Boolean to enable or disable test mode.
     */
    function setTestMode(bool _isTestMode) external onlyOwner {
        isTestMode = _isTestMode;
        emit TestModeEnabled(_isTestMode);
    }

    /**
     * @dev Simulate a price update for testing purposes. Only available in test mode.
     * @param _price Simulated price value (scaled by 1e8, e.g., $1000 = 100000000).
     * @param _timestamp Simulated timestamp of the price update.
     */
    function simulatePrice(int256 _price, uint256 _timestamp) external onlyOwner {
        require(isTestMode, "Test mode is not enabled");
        require(_price > 0, "Price must be positive");
        simulatedFeed = FeedData(_price, _timestamp);
    }

    /**
     * @dev Returns the latest price, either from the simulated feed or the real Chainlink feed.
     * @return The latest price as an int256.
     */
    function getLatestPrice() public view returns (int256) {
        if (isTestMode) {
            return simulatedFeed.price;
        } else {
            revert("Test mode is required for this deployment");
        }
    }

    /**
     * @dev Checks if the latest price data is recent.
     * @return True if the price data is recent, false otherwise.
     */
    function isPriceRecent() public view returns (bool) {
        uint256 lastUpdated = isTestMode ? simulatedFeed.lastUpdated : block.timestamp;
        return (block.timestamp - lastUpdated) <= priceUpdateThreshold;
    }

    /**
     * @dev Emits an event with the latest price if it's recent enough.
     */
    function updatePrice() external {
        require(isPriceRecent(), "Price data is outdated");
        int256 price = getLatestPrice();
        emit PriceUpdated(address(this), uint256(price), block.timestamp);
    }
}
