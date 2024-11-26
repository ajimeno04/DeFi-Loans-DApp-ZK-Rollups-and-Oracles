// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChainlinkFeeds {
    struct FeedData {
        int256 price;
        uint256 lastUpdated;
    }

    FeedData public simulatedFeed;
    bool public isTestMode = false; // Flag to enable/disable test mode
    uint256 private nonce = 0; // A counter to change the randomness

    /**
     * @dev Enable or disable test mode.
     * @param _isTestMode Boolean to enable or disable test mode.
     */
    function setTestMode(bool _isTestMode) external {
        isTestMode = _isTestMode;
    }

    /**
     * @dev Updates the simulated price for testing purposes.
     * @param _price Simulated price value (scaled by 1e8, e.g., $1000 = 100000000).
     */
    function simulatePrice(int256 _price) external {
        simulatedFeed = FeedData(_price, block.timestamp);
    }

    /**
     * @dev Returns the latest price, either simulated or pseudo-random for placeholder purposes.
     * @return The latest price as an int256.
     */
    function getLatestPrice() public view returns (int256) {
        if (isTestMode) {
            return simulatedFeed.price;
        } else {
            // Generate a pseudo-random number between 1 and 900 and add it to 1000
            return int256(1000 + (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 900)) * 1e8;
        }
    }

    /**
     * @dev Example function to increment the nonce for "randomness".
     */
    function incrementNonce() external {
        nonce++;
    }
}
