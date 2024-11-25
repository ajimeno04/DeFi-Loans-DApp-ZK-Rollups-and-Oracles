// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkFeeds {
    function getLatestPrice() external view returns (int256);
    function isPriceRecent() external view returns (bool);
    function updatePrice() external;
}
