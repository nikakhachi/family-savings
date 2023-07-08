// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./FamilySavings.t.sol";

contract WithdrawTest is FamilySavingsTest {
    /// @dev test withdraw() functionality with voting system
    function testWithdraw() public {
        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "withdraw(address,address,uint256)",
                address(address(2)),
                address(token0),
                TOKEN0_INITIAL_DEPOSIT
            )
        ];
        description = "Withdraw Funds";

        assertEq(
            token0.balanceOf(address(familySavings)),
            TOKEN0_INITIAL_DEPOSIT
        );
        assertEq(token0.balanceOf(address(2)), 0);

        _proposeAndExecute();

        assertEq(token0.balanceOf(address(familySavings)), 0);
        assertEq(token0.balanceOf(address(2)), TOKEN0_INITIAL_DEPOSIT);
    }
}
