// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol"; 
import "../src/core/SupplyVaultBase.sol";
import "../src/core/LoanVaultBase.sol";
import "../src/core/LiquidationManager.sol";
import "../src/application/UserActions.sol";
import "../src/infrastructure/ChainlinkFeeds.sol";

contract DeployContracts is Script {
    // Define addresses for dependencies (to be configured per deployment)
    address public constant DUMMY_CHAINLINK_FEED = 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4; // Replace with actual feed address
    address public constant DUMMY_COLLATERAL_TOKEN = 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4; // Replace with token address (e.g., USDC)

    function run() external {
        vm.startBroadcast(); // Start broadcasting transactions

        // Deploy SupplyVaultBase (managing collateral)
        SupplyVaultBase supplyVault = new SupplyVaultBase(DUMMY_COLLATERAL_TOKEN);
        console.log("SupplyVault deployed at:", address(supplyVault));

        // Deploy ChainlinkFeeds (price feeds management)
        ChainlinkFeeds chainlinkFeeds = new ChainlinkFeeds();
        console.log("ChainlinkFeeds deployed at:", address(chainlinkFeeds));

        // Deploy LoanVaultBase (managing loans)
        LoanVaultBase loanVault = new LoanVaultBase(
            DUMMY_COLLATERAL_TOKEN,
            address(supplyVault),
            address(chainlinkFeeds)
        );
        console.log("LoanVault deployed at:", address(loanVault));

        // Deploy LiquidationManager (handling liquidations)
        LiquidationManager liquidationManager = new LiquidationManager(
            address(supplyVault),
            address(loanVault),
            address(chainlinkFeeds)
        );
        console.log("LiquidationManager deployed at:", address(liquidationManager));

        // Deploy UserActions (user-facing interactions)
        UserActions userActions = new UserActions(
            address(supplyVault),
            address(loanVault),
            address(liquidationManager)
        );
        console.log("UserActions deployed at:", address(userActions));

        vm.stopBroadcast(); // Stop broadcasting transactions
    }
}
