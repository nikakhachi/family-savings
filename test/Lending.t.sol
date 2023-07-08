// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./FamilySavings.t.sol";

contract LendingTest is FamilySavingsTest {
    Token public borrowToken;
    Token public collateralToken;
    uint256 public annualLendingRate = 0.1 ether; /// @dev 10% | FORMAT: 1 ether = 100%
    uint256 public collateralRate = 1.5 ether; /// @dev 150% | FORMAT: 1 ether = 100%

    uint public borrowAmount = 100 * 10 ** 18;
    uint public periodInDays = 365 * 2;
    uint256 public returnAmount =
        borrowAmount +
            (borrowAmount * annualLendingRate * periodInDays) /
            365 /
            1 ether;
    uint public collateralAmount = (returnAmount * collateralRate) / 1 ether;

    function testBorrow() public {
        _beforeEach();

        collateralToken.approve(address(familySavings), collateralAmount);

        uint startingBorrowTokenAmount = borrowToken.balanceOf(address(this));
        uint startingCollateralTokenAmount = collateralToken.balanceOf(
            address(this)
        );

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

        assertEq(
            borrowToken.balanceOf(address(this)),
            startingBorrowTokenAmount + borrowAmount
        );
        assertEq(
            collateralToken.balanceOf(address(this)),
            startingCollateralTokenAmount - collateralAmount
        );
    }

    function testBorrowWithShortPeriod() public {
        _beforeEach();

        vm.expectRevert(FamilySavings.PeriodTooShort.selector);
        familySavings.borrow(
            address(borrowToken),
            1,
            address(collateralToken),
            1
        );
    }

    function testBorrowNonSupportedToken() public {
        _beforeEach();

        vm.expectRevert(FamilySavings.TokenNotSupported.selector);
        familySavings.borrow(address(0), 1, address(collateralToken), 7);
    }

    function testBorrowWithNonSupportedCollateral() public {
        _beforeEach();

        vm.expectRevert(FamilySavings.TokenNotSupported.selector);
        familySavings.borrow(address(borrowToken), 1, address(0), 7);
    }

    function testRepay() public {
        _beforeEach();

        collateralToken.approve(address(familySavings), collateralAmount);

        uint borrowingId = familySavings.borrow(
            address(borrowToken),
            borrowAmount,
            address(collateralToken),
            periodInDays
        );

        skip(600);

        uint preRepayBorrowTokenAmount = borrowToken.balanceOf(address(this));
        uint preRepayCollateralTokenAmount = collateralToken.balanceOf(
            address(this)
        );

        borrowToken.approve(address(familySavings), returnAmount);
        familySavings.repay(borrowingId);

        FamilySavings.Borrowing memory borrowing = familySavings
            .getBorrowingById(borrowingId);

        assertEq(borrowing.collateralAmount, 0);
        assertEq(borrowing.returnAmount, 0);

        assertEq(
            borrowToken.balanceOf(address(this)),
            preRepayBorrowTokenAmount - returnAmount
        );
        assertEq(
            collateralToken.balanceOf(address(this)),
            preRepayCollateralTokenAmount + collateralAmount
        );
    }

    function testLiquidate() public {
        _beforeEach();

        collateralToken.approve(address(familySavings), collateralAmount);

        uint borrowingId = familySavings.borrow(
            address(borrowToken),
            borrowAmount,
            address(collateralToken),
            periodInDays
        );

        uint postBorrowBorrowTokenAmount = borrowToken.balanceOf(address(this));
        uint postBorrowCollateralTokenAmount = collateralToken.balanceOf(
            address(this)
        );

        skip(periodInDays * 24 * 60 * 60);

        familySavings.liquidate(borrowingId);

        FamilySavings.Borrowing memory borrowing = familySavings
            .getBorrowingById(borrowingId);

        assertEq(borrowing.collateralAmount, 0);
        assertEq(borrowing.returnAmount, 0);

        assertEq(
            borrowToken.balanceOf(address(this)),
            postBorrowBorrowTokenAmount
        );
        assertEq(
            collateralToken.balanceOf(address(this)),
            postBorrowCollateralTokenAmount
        );
    }

    function testLiquidateEarly() public {
        _beforeEach();

        collateralToken.approve(address(familySavings), collateralAmount);

        uint borrowingId = familySavings.borrow(
            address(borrowToken),
            borrowAmount,
            address(collateralToken),
            periodInDays
        );

        skip(periodInDays * 24 * 60 * 60 - 1);

        vm.expectRevert(FamilySavings.TooEarlyForLiquidation.selector);
        familySavings.liquidate(borrowingId);
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
