// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISupplyVault.sol";
import "../interfaces/ILoanVault.sol";
import "../interfaces/ILiquidationManager.sol";

contract UserActions {
    ISupplyVault public supplyVault;
    ILoanVault public loanVault;
    ILiquidationManager public liquidationManager;

    /**
     * @dev Constructor to initialize the UserActions contract with references to core contracts.
     * @param _supplyVault Address of the SupplyVault interface.
     * @param _loanVault Address of the LoanVault interface.
     * @param _liquidationManager Address of the LiquidationManager interface.
     */
    constructor(
        address _supplyVault,
        address _loanVault,
        address _liquidationManager
    ) {
        require(_supplyVault != address(0), "Invalid SupplyVault address");
        require(_loanVault != address(0), "Invalid LoanVault address");
        require(_liquidationManager != address(0), "Invalid LiquidationManager address");

        supplyVault = ISupplyVault(_supplyVault);
        loanVault = ILoanVault(_loanVault);
        liquidationManager = ILiquidationManager(_liquidationManager);
    }

/**
 * @dev Deposits collateral into the SupplyVault on behalf of the user.
 *      Validates the input and ensures the transaction will succeed before calling SupplyVault.
 * @param amount Amount of tokens to deposit.
 */
function depositCollateral(uint256 amount) external {
    // Check if the deposit amount is greater than zero
    require(amount > 0, "Deposit amount must be greater than zero");

    // Call the deposit function in the SupplyVault contract
    try supplyVault.deposit(amount) {
        // Successful deposit
    } catch Error(string memory reason) {
        // Revert with the error message from SupplyVault
        revert(reason);
    } catch {
        // Fallback for unknown errors
        revert("Unknown error occurred during deposit");
    }
}

    /**
     * @dev Withdraws collateral from the SupplyVault for the user.
     * @param amount Amount of tokens to withdraw.
     */
    function withdrawCollateral(uint256 amount) external {
        supplyVault.withdraw(amount);
    }

    /**
     * @dev Allows a user to borrow tokens from the LoanVault.
     * @param amount Amount of tokens to borrow.
     */
    function borrow(uint256 amount) external {
        loanVault.issueLoan(amount);
    }

    /**
     * @dev Allows a user to repay their loan to the LoanVault.
     * @param amount Amount of tokens to repay.
     */
    function repayLoan(uint256 amount) external {
        loanVault.repayLoan(amount);
    }

    /**
     * @dev Initiates a liquidation for an under-collateralized borrower.
     * @param borrower Address of the borrower to liquidate.
     * @param repayAmount Amount of debt to repay.
     */
    function liquidate(address borrower, uint256 repayAmount) external {
        liquidationManager.liquidate(borrower, repayAmount);
    }
}
