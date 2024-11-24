// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ISupplyVault {
    function getCollateral(address user) external view returns (uint256);
}

interface IPriceFeed {
    function latestAnswer() external view returns (int256);
}

abstract contract LoanVaultBase is ReentrancyGuard {
    mapping(address => uint256) public userDebt; // Debt record per user
    IERC20 public loanToken; // Token being loaned (e.g., USDC, DAI)
    ISupplyVault public supplyVault; // Reference to the SupplyVault contract
    IPriceFeed public priceFeed; // Chainlink price feed for collateral

    uint256 public constant COLLATERALIZATION_RATIO = 150; // 150% collateralization ratio

    event LoanIssued(address indexed user, uint256 amount);
    event LoanRepaid(address indexed user, uint256 amount);

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

    function issueLoan(uint256 amount) public virtual nonReentrant {
        // Checks
        require(amount > 0, "Amount must be greater than zero");
        require(canBorrow(msg.sender, amount), "Insufficient collateral");

        // Effects
        userDebt[msg.sender] += amount;

        // Interactions
        require(
            loanToken.transfer(msg.sender, amount),
            "Loan transfer failed"
        );

        emit LoanIssued(msg.sender, amount);
    }

    function repayLoan(uint256 amount) public virtual nonReentrant {
        // Checks
        require(amount > 0, "Amount must be greater than zero");
        require(userDebt[msg.sender] >= amount, "Amount exceeds debt");

        // Effects
        userDebt[msg.sender] -= amount;

        // Interactions
        require(
            loanToken.transferFrom(msg.sender, address(this), amount),
            "Repayment failed"
        );

        emit LoanRepaid(msg.sender, amount);
    }

    function canBorrow(address user, uint256 amount) public view returns (bool) {
        // Get the collateral balance of the user from the SupplyVault
        uint256 collateralBalance = supplyVault.getCollateral(user);

        // Fetch the current collateral price in USD from Chainlink
        int256 collateralPrice = priceFeed.latestAnswer();
        require(collateralPrice > 0, "Invalid price from Chainlink");

        // Calculate the total collateral value in USD
        uint256 collateralValueUSD = (collateralBalance *
            uint256(collateralPrice)) / 1e8; // Adjust for Chainlink's 8 decimals

        // Calculate the required collateral for the requested loan amount
        uint256 requiredCollateral = (amount * COLLATERALIZATION_RATIO) / 100;

        return collateralValueUSD >= requiredCollateral;
    }

    function reduceDebt(address user, uint256 amount) external virtual nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(userDebt[user] >= amount, "Insufficient debt");

        userDebt[user] -= amount;

        emit LoanRepaid(user, amount);
    }

    function getDebt(address user) public view returns (uint256) {
        return userDebt[user];
    }
}
