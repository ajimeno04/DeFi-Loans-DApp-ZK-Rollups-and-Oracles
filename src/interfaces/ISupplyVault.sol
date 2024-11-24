// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupplyVault {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getCollateral(address user) external view returns (uint256);
    function reduceCollateral(address user, uint256 amount) external;
}
