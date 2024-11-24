// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILiquidationManager {
    function liquidate(address borrower, uint256 repayAmount) external;
}
