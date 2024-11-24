// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

abstract contract SupplyVaultBase is ReentrancyGuard {
    mapping(address => uint256) public userCollateral;
    IERC20 public collateralToken;

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        collateralToken = IERC20(_token);
    }

    function deposit(uint256 amount) public virtual nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(
            collateralToken.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );

        userCollateral[msg.sender] += amount;
        emit CollateralDeposited(msg.sender, amount);
    }

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

    function reduceCollateral(address user, uint256 amount) external virtual nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(userCollateral[user] >= amount, "Insufficient collateral");

        userCollateral[user] -= amount;

        emit CollateralWithdrawn(user, amount);
    }

    function getCollateral(address user) public view returns (uint256) {
        return userCollateral[user];
    }
}
