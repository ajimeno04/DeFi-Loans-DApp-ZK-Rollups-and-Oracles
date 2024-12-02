// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/core/SupplyVaultBase.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MockERC20 is IERC20 {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        return true;
    }

    function mint(address account, uint256 amount) external {
        balanceOf[account] += amount;
        totalSupply += amount;
    }

    function burn(address account, uint256 amount) external {
        require(balanceOf[account] >= amount, "Insufficient balance");
        balanceOf[account] -= amount;
        totalSupply -= amount;
    }
}

contract SupplyVaultBaseTest is Test {
    SupplyVaultBase public vault;
    MockERC20 public token;

    address public user = address(0x1);
    address public anotherUser = address(0x2);

    function setUp() public {
        // Deploy the mock token and the vault
        token = new MockERC20();
        vault = new SupplyVaultBase(address(token));

        // Mint some tokens to the user and approve the vault
        // token.mint(user, 1000 ether);
        // vm.prank(user);
        // token.approve(address(vault), 1000 ether);
    }

function testDepositWithExactBalance() public {
    vm.startPrank(user);

    // Darle al usuario exactamente la cantidad que va a depositar
    token.mint(user, 50 ether);
    token.approve(address(vault), 50 ether);

    // Realizar el depósito
    vault.deposit(50 ether);

    // Verificar que el colateral se actualizó correctamente
    assertEq(vault.getCollateral(user), 50 ether, "Collateral should match the deposit amount");
    // Verificar que el saldo del usuario ahora sea 0
    assertEq(token.balanceOf(user), 0, "User balance should be zero after deposit");

    vm.stopPrank();
}

function testDepositWithInsufficientAllowance() public {
    vm.startPrank(user);

    // Aprobar menos tokens de los que se quieren depositar
    token.mint(user, 100 ether);
    token.approve(address(vault), 50 ether);

    // Intentar depositar más de lo aprobado
    vm.expectRevert("Allowance insufficient for transfer; approve more tokens");
    vault.deposit(100 ether);

    vm.stopPrank();
}

function testDepositFailsWithZeroTokens() public {
    vm.startPrank(user);

    // Intentar depositar con balance 0
    vm.expectRevert("Deposit amount must be greater than zero");
    vault.deposit(0);

    vm.stopPrank();
}

function testDepositFailsWhenInsufficientBalance() public {
    vm.startPrank(user);

    // Aprobar una cantidad pero no dar balance suficiente
    token.approve(address(vault), 100 ether);

    // Intentar depositar más de lo que el usuario tiene
    vm.expectRevert("Insufficient token balance for deposit");
    vault.deposit(100 ether);

    vm.stopPrank();
}

function testDepositMultipleTimes() public {
    vm.startPrank(user);

    token.mint(user, 500 ether);
    token.approve(address(vault), 500 ether);

    vault.deposit(100 ether); 
    vault.deposit(200 ether); 

    assertEq(vault.getCollateral(user), 300 ether, "Total collateral should equal sum of deposits");

    assertEq(token.balanceOf(user), 200 ether, "User balance should match remaining tokens");

    vm.stopPrank();
}




//     function testWithdraw() public {
//         vm.startPrank(user);

//         // Deposit first
//         vault.deposit(100 ether);

//         // Withdraw the collateral
//         vault.withdraw(50 ether);

//         // Assert the user's collateral decreased
//         assertEq(vault.getCollateral(user), 50 ether, "Collateral not updated after withdrawal");

//         // Assert that the token balance increased
//         assertEq(token.balanceOf(user), 950 ether, "Token balance not increased");

//         vm.stopPrank();
//     }

//     function testWithdrawFailsOnInsufficientCollateral() public {
//         vm.startPrank(user);

//         // Deposit some collateral
//         vault.deposit(50 ether);

//         // Attempt to withdraw more than the collateral
//         vm.expectRevert("Insufficient collateral");
//         vault.withdraw(100 ether);

//         vm.stopPrank();
//     }

//     function testReduceCollateral() public {
//         vm.startPrank(user);

//         // Deposit some collateral
//         vault.deposit(100 ether);

//         // Reduce collateral
//         vm.prank(address(this)); // Call from contract owner
//         vault.reduceCollateral(user, 50 ether);

//         // Assert the collateral is reduced
//         assertEq(vault.getCollateral(user), 50 ether, "Collateral not reduced");

//         vm.stopPrank();
//     }

//     function testReduceCollateralFailsOnInsufficientCollateral() public {
//         vm.startPrank(user);

//         // Deposit some collateral
//         vault.deposit(50 ether);

//         // Attempt to reduce more than available collateral
//         vm.expectRevert("Insufficient collateral");
//         vault.reduceCollateral(user, 100 ether);

//         vm.stopPrank();
//     }

//     function testGetCollateral() public {
//         vm.startPrank(user);

//         // Deposit some collateral
//         vault.deposit(100 ether);

//         // Assert the correct collateral balance is returned
//         assertEq(vault.getCollateral(user), 100 ether, "Collateral balance mismatch");

//         vm.stopPrank();
//     }

    // function testDepositEmitsEvent() public {
    //     vm.startPrank(user);

    //     // Expect the CollateralDeposited event
    //     vm.expectEmit(true, true, false, true);
    //     emit CollateralDeposited(user, 100 ether);

    //     // Perform deposit
    //     vault.deposit(100 ether);

    //     vm.stopPrank();
    // }

    // function testWithdrawEmitsEvent() public {
    //     vm.startPrank(user);

    //     // Deposit first
    //     vault.deposit(100 ether);

    //     // Expect the CollateralWithdrawn event
    //     vm.expectEmit(true, true, false, true);
    //     emit CollateralWithdrawn(user, 50 ether);

    //     // Perform withdrawal
    //     vault.withdraw(50 ether);

    //     vm.stopPrank();
    // }
}
