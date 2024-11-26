// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../src/core/SupplyVaultBase.sol";
import "../src/core/LoanVaultBase.sol";
import "../src/core/LiquidationManager.sol";
import "../src/application/UserActions.sol";
import "../src/infrastructure/ChainlinkFeeds.sol";
import "../src/MockERC20.sol"; // Importamos el contrato del token

contract DeployContracts is Script {
    function run() external {
        vm.startBroadcast(); // Inicia la transmisión de transacciones

        // 1. Deploy MockERC20 token
        MockERC20 mockToken = new MockERC20("MockToken", "MKT", 10_000_000 * 10**18);
        console.log("MockToken deployed at:", address(mockToken));

        // 2. Deploy ChainlinkFeeds
        ChainlinkFeeds chainlinkFeeds = new ChainlinkFeeds();
        console.log("ChainlinkFeeds deployed at:", address(chainlinkFeeds));

        // 3. Deploy SupplyVaultBase
        SupplyVaultBase supplyVault = new SupplyVaultBase(address(mockToken));
        console.log("SupplyVault deployed at:", address(supplyVault));

        // 4. Deploy LoanVaultBase
        LoanVaultBase loanVault = new LoanVaultBase(
            address(mockToken),
            address(supplyVault),
            address(chainlinkFeeds)
        );
        console.log("LoanVault deployed at:", address(loanVault));

        // 5. Deploy LiquidationManager
        LiquidationManager liquidationManager = new LiquidationManager(
            address(supplyVault),
            address(loanVault),
            address(chainlinkFeeds)
        );
        console.log("LiquidationManager deployed at:", address(liquidationManager));

        // 6. Deploy UserActions
        UserActions userActions = new UserActions(
            address(supplyVault),
            address(loanVault),
            address(liquidationManager)
        );
        console.log("UserActions deployed at:", address(userActions));

        vm.stopBroadcast(); // Finaliza la transmisión de transacciones
    }
}
