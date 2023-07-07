// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./FamilySavings.t.sol";

contract LendingTest is FamilySavingsTest {
    Token public borrowToken;
    Token public collateralToken;
    uint256 public annualLendingRate = 0.1 ether; /// @dev 10% | FORMAT: 1 ether = 100%
    uint256 public collateralRate = 1.5 ether; /// @dev 150% | FORMAT: 1 ether = 100%

    function testBorrow() public {
        _beforeEach();

        uint borrowAmount = 100 * 10 ** 18;
        uint periodInDays = 365 * 2;

        uint256 returnAmount = borrowAmount +
            (borrowAmount * annualLendingRate * periodInDays) /
            365 /
            1 ether;
        uint collateralAmount = (returnAmount * collateralRate) / 1 ether;

        collateralToken.approve(address(familySavings), collateralAmount);

        uint borrowingId = familySavings.borrow(
            address(borrowToken),
            borrowAmount,
            address(collateralToken),
            periodInDays
        );

        FamilySavings.Borrowing memory borrowing = familySavings
            .getBorrowingById(borrowingId);

        assertEq(borrowing.borrowToken, address(borrowToken));
        assertEq(borrowing.collateralToken, address(collateralToken));
        assertEq(borrowing.borrowAmount, borrowAmount);
        assertEq(borrowing.collateralAmount, collateralAmount);
        assertEq(borrowing.returnAmount, returnAmount);
        assertEq(borrowing.returnAmount, 120 * 10 ** 18);
        assertEq(
            borrowing.returnDateTimestamp,
            block.timestamp + (periodInDays * 24 * 60 * 60)
        );
    }

    function _beforeEach() private {
        borrowToken = token0;
        collateralToken = token1;

        targets = [address(familySavings), address(familySavings)];
        values = [0, 0];
        calldatas = [
            abi.encodeWithSignature(
                "setCollateralRate(address,address,uint256)",
                address(borrowToken),
                address(collateralToken),
                collateralRate
            ),
            abi.encodeWithSignature(
                "setAnnualLendingRate(address,uint256)",
                address(borrowToken),
                annualLendingRate
            )
        ];

        _proposeAndExecute();
    }
}
