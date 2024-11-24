// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

interface ISupplyVault {
    function getCollateral(address user) external view returns (uint256);
    function reduceCollateral(address user, uint256 amount) external;
}

interface ILoanVault {
    function getDebt(address user) external view returns (uint256);
    function reduceDebt(address user, uint256 amount) external;
}

interface IPriceFeed {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

contract LiquidationManager is ReentrancyGuard {
    ISupplyVault public supplyVault;
    ILoanVault public loanVault;
    IPriceFeed public priceFeed;

    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120% collateralization ratio
    uint256 public constant LIQUIDATION_PENALTY = 10; // 10% penalty
    uint256 public priceUpdateThreshold = 1 hours; // Max allowed staleness for price data

    mapping(address => uint256) public cachedPrices; // Cached prices for tokens
    mapping(address => uint256) public priceTimestamps; // Last update timestamps for cached prices

    event LoanLiquidated(
        address indexed borrower,
        address indexed liquidator,
        uint256 repaidAmount,
        uint256 collateralSeized
    );

    constructor(
        address _supplyVault,
        address _loanVault,
        address _priceFeed
    ) {
        require(_supplyVault != address(0), "Invalid SupplyVault address");
        require(_loanVault != address(0), "Invalid LoanVault address");
        require(_priceFeed != address(0), "Invalid PriceFeed address");

        supplyVault = ISupplyVault(_supplyVault);
        loanVault = ILoanVault(_loanVault);
        priceFeed = IPriceFeed(_priceFeed);
    }

    function updatePrice(address token) external {
        int256 price = priceFeed.latestAnswer();
        require(price > 0, "Invalid price from Chainlink");
        uint256 lastUpdated = priceFeed.latestTimestamp();
        require(isPriceRecent(lastUpdated), "Price data is outdated");

        cachedPrices[token] = uint256(price);
        priceTimestamps[token] = block.timestamp;
    }

    function isPriceRecent(uint256 lastUpdated) internal view returns (bool) {
        return (block.timestamp - lastUpdated) <= priceUpdateThreshold;
    }

    function isUnderCollateralized(address borrower) public view returns (bool) {
        uint256 debt = loanVault.getDebt(borrower);
        uint256 collateral = supplyVault.getCollateral(borrower);
        uint256 price = cachedPrices[address(supplyVault)];

        uint256 collateralValueUSD = (collateral * price) / 1e8; // Adjust for 8 decimals
        uint256 collateralizationRatio = (collateralValueUSD * 100) / debt;

        return collateralizationRatio < LIQUIDATION_THRESHOLD;
    }

    function liquidate(address borrower, uint256 repayAmount) external nonReentrant {
        require(isUnderCollateralized(borrower), "Loan is not under-collateralized");

        uint256 debt = loanVault.getDebt(borrower);
        require(repayAmount > 0 && repayAmount <= debt, "Invalid repayment amount");

        uint256 price = cachedPrices[address(supplyVault)];
        uint256 collateralToSeize = (repayAmount * 1e8 * (100 + LIQUIDATION_PENALTY)) / price / 100;

        uint256 collateral = supplyVault.getCollateral(borrower);
        require(collateralToSeize <= collateral, "Insufficient collateral to seize");

        loanVault.reduceDebt(borrower, repayAmount);
        supplyVault.reduceCollateral(borrower, collateralToSeize);

        IERC20(address(supplyVault)).transfer(msg.sender, collateralToSeize);

        emit LoanLiquidated(borrower, msg.sender, repayAmount, collateralToSeize);
    }
}

