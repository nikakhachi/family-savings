// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./FamilySavings.t.sol";

contract DepositTest is FamilySavingsTest {
    function testDepositExisingToken() public {
        assertEq(
            token0.balanceOf(address(familySavings)),
            TOKEN0_INITIAL_DEPOSIT
        );
        assertEq(token0.balanceOf(address(this)), TOKEN0_INITIAL_SUPPLY);
        assertEq(
            familySavings.balances(address(token0)),
            TOKEN0_INITIAL_DEPOSIT
        );

        token0.approve(address(familySavings), TOKEN0_INITIAL_SUPPLY);
        familySavings.deposit(address(token0), TOKEN0_INITIAL_SUPPLY);

        assertEq(
            familySavings.balances(address(token0)),
            TOKEN0_INITIAL_SUPPLY + TOKEN0_INITIAL_DEPOSIT
        );
        assertEq(
            token0.balanceOf(address(familySavings)),
            TOKEN0_INITIAL_SUPPLY + TOKEN0_INITIAL_DEPOSIT
        );
        assertEq(token0.balanceOf(address(this)), 0);
    }

    function testDepositNewToken() public {
        assertEq(familySavings.balances(address(token1)), 0);
        assertEq(token1.balanceOf(address(familySavings)), 0);
        assertEq(token1.balanceOf(address(this)), TOKEN1_INITIAL_SUPPLY);

        token1.approve(address(familySavings), TOKEN1_INITIAL_SUPPLY);
        familySavings.deposit(address(token1), TOKEN1_INITIAL_SUPPLY);

        assertEq(
            familySavings.balances(address(token1)),
            TOKEN1_INITIAL_SUPPLY
        );
        assertEq(
            token1.balanceOf(address(familySavings)),
            TOKEN1_INITIAL_SUPPLY
        );
        assertEq(token1.balanceOf(address(this)), 0);
    }
}
