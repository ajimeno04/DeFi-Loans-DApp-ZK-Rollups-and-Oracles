// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILoanVault {
    function getDebt(address user) external view returns (uint256);
    function reduceDebt(address user, uint256 amount) external;
}
