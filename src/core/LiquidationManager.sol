// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISupplyVault.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/ILoanVault.sol";

contract LiquidationManager is ReentrancyGuard {
    ISupplyVault public supplyVault;
    ILoanVault public loanVault;
    IPriceFeed public priceFeed;

    uint256 public constant LIQUIDATION_THRESHOLD = 120;
    uint256 public constant LIQUIDATION_PENALTY = 10;
    uint256 public priceUpdateThreshold = 1 hours;

    mapping(address => uint256) public cachedPrices;
    mapping(address => uint256) public priceTimestamps;

    event LoanLiquidated(
        address indexed borrower,
        address indexed liquidator,
        uint256 repaidAmount,
        uint256 collateralSeized
    );

    /**
     * @dev Constructor to initialize the LiquidationManager with addresses for SupplyVault, LoanVault, and PriceFeed.
     * @param _supplyVault Address of the SupplyVault contract.
     * @param _loanVault Address of the LoanVault contract.
     * @param _priceFeed Address of the Chainlink PriceFeed contract.
     */
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

    /**
     * @dev Updates the cached price of the collateral token using the Chainlink PriceFeed.
     *      Ensures the price is valid and recent.
     * @param token Address of the collateral token to update the price for.
     */
    function updatePrice(address token) external {
        int256 price = priceFeed.latestAnswer();
        require(price > 0, "Invalid price from Chainlink");
        uint256 lastUpdated = priceFeed.latestTimestamp();
        require(isPriceRecent(lastUpdated), "Price data is outdated");

        cachedPrices[token] = uint256(price);
        priceTimestamps[token] = block.timestamp;
    }

    /**
     * @dev Checks if the price data from the Chainlink feed is recent.
     * @param lastUpdated Timestamp of the last price update from the feed.
     * @return True if the price data is within the allowed threshold.
     */
    function isPriceRecent(uint256 lastUpdated) internal view returns (bool) {
        return (block.timestamp - lastUpdated) <= priceUpdateThreshold;
    }

    /**
     * @dev Determines if a borrower's loan is under-collateralized based on the cached collateral price.
     * @param borrower Address of the borrower to check.
     * @return True if the collateralization ratio is below the liquidation threshold.
     */
    function isUnderCollateralized(address borrower) public view returns (bool) {
        uint256 debt = loanVault.getDebt(borrower);
        uint256 collateral = supplyVault.getCollateral(borrower);
        uint256 price = cachedPrices[address(supplyVault)];

        uint256 collateralValueUSD = (collateral * price) / 1e8;
        uint256 collateralizationRatio = (collateralValueUSD * 100) / debt;

        return collateralizationRatio < LIQUIDATION_THRESHOLD;
    }

    /**
     * @dev Executes a liquidation for an under-collateralized borrower.
     *      The liquidator repays part of the borrower's debt and seizes a discounted portion of their collateral.
     * @param borrower Address of the borrower to liquidate.
     * @param repayAmount Amount of the borrower's debt to repay.
     */
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
