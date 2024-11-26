// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract SupplyVaultBase is ReentrancyGuard {
    mapping(address => uint256) public userCollateral;
    IERC20 public collateralToken;

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    /**
     * @dev Constructor to initialize the SupplyVault with the collateral token.
     * @param _token Address of the ERC20 token to be used as collateral.
     */
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        collateralToken = IERC20(_token);
    }

   /**
 * @dev Allows a user to deposit collateral tokens into the vault.
 *      Updates the user's collateral balance and emits a deposit event.
 * @param amount The amount of tokens to deposit.
 */
function deposit(uint256 amount) public virtual nonReentrant {
    // Ensure the deposit amount is valid
    require(amount > 0, "Deposit amount must be greater than zero");

    // Check the sender's token balance
    uint256 senderBalance = collateralToken.balanceOf(msg.sender);
    require(senderBalance >= amount, "Insufficient token balance for deposit");

    // Check the allowance provided by the sender
    uint256 allowance = collateralToken.allowance(msg.sender, address(this));
    require(
        allowance >= amount,
        "Allowance insufficient for transfer; approve more tokens"
    );

    // Attempt to transfer tokens from sender to the vault
    bool transferSuccess = collateralToken.transferFrom(
        msg.sender,
        address(this),
        amount
    );
    require(transferSuccess, "Token transfer failed due to contract error");

    // Update the user's collateral balance
    userCollateral[msg.sender] += amount;

    // Emit an event to notify about the deposit
    emit CollateralDeposited(msg.sender, amount);
}

    /**
     * @dev Allows a user to withdraw their collateral tokens from the vault.
     *      Ensures the user has sufficient collateral before allowing withdrawal.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) public virtual nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(userCollateral[msg.sender] >= amount, "Insufficient collateral");

        userCollateral[msg.sender] -= amount;
        require(
            collateralToken.transfer(msg.sender, amount),
            "Token transfer failed"
        );

        emit CollateralWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Reduces a user's collateral balance.
     *      Typically used during liquidation processes to seize collateral.
     * @param user Address of the user whose collateral is to be reduced.
     * @param amount The amount of collateral to reduce.
     */
    function reduceCollateral(address user, uint256 amount) external virtual nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(userCollateral[user] >= amount, "Insufficient collateral");

        userCollateral[user] -= amount;

        emit CollateralWithdrawn(user, amount);
    }

    /**
     * @dev Returns the total collateral balance of a specific user.
     * @param user Address of the user to query.
     * @return The collateral balance of the user.
     */
    function getCollateral(address user) public view returns (uint256) {
        return userCollateral[user];
    }
}
