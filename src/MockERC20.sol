// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts//contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockERC20 is ERC20, Ownable {
    /**
     * @dev Constructor for MockERC20.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param initialSupply Initial supply of tokens (in wei).
     */
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Allows the owner to mint new tokens.
     * @param account The address to mint tokens to.
     * @param amount The amount of tokens to mint (in wei).
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
