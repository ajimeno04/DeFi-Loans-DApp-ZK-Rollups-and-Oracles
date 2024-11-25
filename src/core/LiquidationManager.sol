// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/ISupplyVault.sol";
import "../interfaces/ILoanVault.sol";
import "../interfaces/IChainlinkFeeds.sol"; 

contract LiquidationManager is ReentrancyGuard {
    ISupplyVault public supplyVault;
    ILoanVault public loanVault;
    IChainlinkFeeds public chainlinkFeeds; 

    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120% collateralization ratio
    uint256 public constant LIQUIDATION_PENALTY = 10; // 10% penalty on liquidated collateral

    event LoanLiquidated(
        address indexed borrower,
        address indexed liquidator,
        uint256 repaidAmount,
        uint256 collateralSeized
    );

    /**
     * @dev Constructor to initialize the LiquidationManager contract with SupplyVault, LoanVault, and ChainlinkFeeds.
     * @param _supplyVault Address of the SupplyVault contract.
     * @param _loanVault Address of the LoanVault contract.
     * @param _chainlinkFeeds Address of the ChainlinkFeeds contract.
     */
    constructor(
        address _supplyVault,
        address _loanVault,
        address _chainlinkFeeds
    ) {
        require(_supplyVault != address(0), "Invalid SupplyVault address");
        require(_loanVault != address(0), "Invalid LoanVault address");
        require(_chainlinkFeeds != address(0), "Invalid ChainlinkFeeds address");

        supplyVault = ISupplyVault(_supplyVault);
        loanVault = ILoanVault(_loanVault);
        chainlinkFeeds = IChainlinkFeeds(_chainlinkFeeds);
    }

    /**
     * @dev Checks if a borrower's collateralization ratio is below the liquidation threshold.
     * @param borrower Address of the borrower.
     * @return True if the collateralization ratio is below the liquidation threshold.
     */
    function isUnderCollateralized(address borrower) public view returns (bool) {
        uint256 debt = loanVault.getDebt(borrower);
        uint256 collateral = supplyVault.getCollateral(borrower);

        int256 price = chainlinkFeeds.getLatestPrice(); // Fetch collateral price from ChainlinkFeeds
        require(price > 0, "Invalid price from Chainlink");

        uint256 collateralValueUSD = (collateral * uint256(price)) / 1e8; // Adjust for 8 decimals
        uint256 collateralizationRatio = (collateralValueUSD * 100) / debt;

        return collateralizationRatio < LIQUIDATION_THRESHOLD;
    }

    /**
     * @dev Executes a liquidation for an under-collateralized borrower.
     * The liquidator repays part of the borrower's debt and seizes a discounted portion of their collateral.
     * @param borrower Address of the borrower to liquidate.
     * @param repayAmount Amount of the borrower's debt to repay.
     */
    function liquidate(address borrower, uint256 repayAmount) external nonReentrant {
        require(isUnderCollateralized(borrower), "Loan is not under-collateralized");

        uint256 debt = loanVault.getDebt(borrower);
        require(repayAmount > 0 && repayAmount <= debt, "Invalid repayment amount");

        int256 price = chainlinkFeeds.getLatestPrice(); // Fetch the latest price
        uint256 collateralToSeize = (repayAmount * 1e8 * (100 + LIQUIDATION_PENALTY)) / uint256(price) / 100;

        uint256 collateral = supplyVault.getCollateral(borrower);
        require(collateralToSeize <= collateral, "Insufficient collateral to seize");

        loanVault.reduceDebt(borrower, repayAmount);
        supplyVault.reduceCollateral(borrower, collateralToSeize);

        IERC20(address(supplyVault)).transfer(msg.sender, collateralToSeize);

        emit LoanLiquidated(borrower, msg.sender, repayAmount, collateralToSeize);
    }
}
