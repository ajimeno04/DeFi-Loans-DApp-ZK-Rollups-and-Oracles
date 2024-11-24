// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupplyVault {
    function getCollateral(address user) external view returns (uint256);
    function reduceCollateral(address user, uint256 amount) external;
}