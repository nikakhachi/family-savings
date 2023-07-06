// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import "openzeppelin/access/Ownable.sol";

error PeriodTooShort();
error TokenNotSupported();
error TooEarlyForLiquidation();

contract FamilySavings is Ownable, ERC20, ERC20Permit, ERC20Votes {
    uint256 public constant MEMBERS_BALANCE = 10 ** 18;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public dailyLendingRates;
    mapping(address => mapping(address => uint256)) public collateralRates;

    struct Borrowing {
        address borrowToken;
        address collateralToken;
        uint256 borrowAmount;
        uint256 collateralAmount;
        uint256 returnAmount;
        uint256 returnDateTimestamp;
    }
    mapping(uint256 => Borrowing) public borrowings;
    uint256 borrowingsCount;

    constructor(
        address _timelock,
        address[] memory _members
    )
        ERC20("FamilySavingsGovernance", "FSG")
        ERC20Permit("FamilySavingsGovernance")
    {
        transferOwnership(_timelock);
        uint256 n = _members.length;
        for (uint256 i; i < n; i++) {
            _mint(_members[i], MEMBERS_BALANCE);
        }
    }

    function deposit(address _token, uint256 _amount) external {
        balances[_token] += _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        balances[_token] -= _amount;
        IERC20(_token).transfer(_to, _amount);
    }

    function setCollateralRate(
        address _lendingToken,
        address _borrowingToken,
        uint256 _rate
    ) external onlyOwner {
        collateralRates[_lendingToken][_borrowingToken] = _rate;
    }

    function setDailyLendingRate(
        address _token,
        uint256 _rate
    ) external onlyOwner {
        dailyLendingRates[_token] = _rate;
    }

    function borrow(
        address borrowToken,
        uint256 borrowAmount,
        address collateralToken,
        uint256 period
    ) external returns (uint256) {
        if (period < 7 days) revert PeriodTooShort();

        uint256 collateralRate = collateralRates[borrowToken][collateralToken];

        if (collateralRate == 0) revert TokenNotSupported();

        uint256 returnAmount = borrowAmount +
            (dailyLendingRates[borrowToken] * period) /
            1 ether;

        uint256 collateralAmount = (returnAmount * collateralRate) / 1 ether;

        IERC20(collateralToken).transferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );
        IERC20(borrowToken).transfer(msg.sender, borrowAmount);

        borrowings[borrowingsCount] = Borrowing(
            borrowToken,
            collateralToken,
            borrowAmount,
            collateralAmount,
            returnAmount,
            block.timestamp + period
        );

        ++borrowingsCount;

        balances[borrowToken] -= borrowAmount;

        return borrowingsCount - 1;
    }

    function repay(uint256 index) external {
        Borrowing storage borrowing = borrowings[index];

        balances[borrowing.borrowToken] += borrowing.returnAmount;

        IERC20(borrowing.borrowToken).transferFrom(
            msg.sender,
            address(this),
            borrowing.returnAmount
        );
        IERC20(borrowing.collateralToken).transfer(
            msg.sender,
            borrowing.collateralAmount
        );

        borrowing.collateralAmount = 0;
        borrowing.returnAmount = 0;
    }

    function liquidate(uint256 index) external {
        Borrowing storage borrowing = borrowings[index];

        if (block.timestamp < borrowing.returnDateTimestamp)
            revert TooEarlyForLiquidation();

        balances[borrowing.collateralToken] += borrowing.collateralAmount;

        borrowing.collateralAmount = 0;
        borrowing.returnAmount = 0;
    }

    function addMember(address _member) external onlyOwner {
        _mint(_member, MEMBERS_BALANCE);
    }

    function revokeMember(address _member) external onlyOwner {
        _burn(_member, balanceOf(_member));
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
