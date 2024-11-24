// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISupplyVault.sol";
import "./interfaces/IPriceFeed.sol";

abstract contract LoanVaultBase is ReentrancyGuard {
    mapping(address => uint256) public userDebt;
    IERC20 public loanToken;
    ISupplyVault public supplyVault;
    IPriceFeed public priceFeed;

    uint256 public constant COLLATERALIZATION_RATIO = 150;

    event LoanIssued(address indexed user, uint256 amount);
    event LoanRepaid(address indexed user, uint256 amount);

    /**
     * @dev Constructor to initialize the LoanVault with required dependencies.
     * @param _loanToken Address of the token to be loaned (e.g., USDC, DAI).
     * @param _supplyVault Address of the SupplyVault contract for collateral management.
     * @param _priceFeed Address of the Chainlink PriceFeed contract for price data.
     */
    constructor(
        address _loanToken,
        address _supplyVault,
        address _priceFeed
    ) {
        require(_loanToken != address(0), "Invalid loan token address");
        require(_supplyVault != address(0), "Invalid supply vault address");
        require(_priceFeed != address(0), "Invalid price feed address");

        loanToken = IERC20(_loanToken);
        supplyVault = ISupplyVault(_supplyVault);
        priceFeed = IPriceFeed(_priceFeed);
    }

    /**
     * @dev Allows a user to borrow tokens based on their collateral.
     *      Checks that the user has sufficient collateral to cover the loan.
     * @param amount The amount of tokens to borrow.
     */
    function issueLoan(uint256 amount) public virtual nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(canBorrow(msg.sender, amount), "Insufficient collateral");

        userDebt[msg.sender] += amount;

        require(
            loanToken.transfer(msg.sender, amount),
            "Loan transfer failed"
        );

        emit LoanIssued(msg.sender, amount);
    }

    /**
     * @dev Allows a user to repay their outstanding loan.
     *      The debt balance of the user is reduced by the amount repaid.
     * @param amount The amount of tokens to repay.
     */
    function repayLoan(uint256 amount) public virtual nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(userDebt[msg.sender] >= amount, "Amount exceeds debt");

        userDebt[msg.sender] -= amount;

        require(
            loanToken.transferFrom(msg.sender, address(this), amount),
            "Repayment failed"
        );

        emit LoanRepaid(msg.sender, amount);
    }

    /**
     * @dev Checks if a user has sufficient collateral to borrow a specified amount.
     *      Uses Chainlink PriceFeed to determine the current collateral value.
     * @param user The address of the user.
     * @param amount The amount the user wants to borrow.
     * @return True if the user has sufficient collateral, false otherwise.
     */
    function canBorrow(address user, uint256 amount) public view returns (bool) {
        uint256 collateralBalance = supplyVault.getCollateral(user);

        int256 collateralPrice = priceFeed.latestAnswer();
        require(collateralPrice > 0, "Invalid price from Chainlink");

        uint256 collateralValueUSD = (collateralBalance *
            uint256(collateralPrice)) / 1e8;

        uint256 requiredCollateral = (amount * COLLATERALIZATION_RATIO) / 100;

        return collateralValueUSD >= requiredCollateral;
    }

    /**
     * @dev Reduces the debt of a user by a specified amount.
     *      This function is typically used during liquidations.
     * @param user The address of the user whose debt is to be reduced.
     * @param amount The amount by which to reduce the user's debt.
     */
    function reduceDebt(address user, uint256 amount) external virtual nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(userDebt[user] >= amount, "Insufficient debt");

        userDebt[user] -= amount;

        emit LoanRepaid(user, amount);
    }

    /**
     * @dev Returns the current debt of a user.
     * @param user The address of the user.
     * @return The current debt balance of the user.
     */
    function getDebt(address user) public view returns (uint256) {
        return userDebt[user];
    }
}
