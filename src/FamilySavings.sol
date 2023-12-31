// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import "openzeppelin/access/Ownable.sol";

/// @title FamilySavings
/// @author Nika Khachiashvili
contract FamilySavings is Ownable, ERC20, ERC20Permit, ERC20Votes {
    using SafeERC20 for IERC20;

    error PeriodTooShort();
    error TokenNotSupported();
    error TooEarlyForLiquidation();

    /// @dev amount of erc20 token for votes that will be given to a voter (family member)
    uint256 public constant MEMBERS_BALANCE = 10 ** 18;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public annualLendingRates; /// @dev FORMAT: 1 ether = 100%
    mapping(address => mapping(address => uint256)) public collateralRates; /// @dev FORMAT: 1 ether = 100%

    struct Borrowing {
        address borrowToken;
        address collateralToken;
        uint256 borrowAmount;
        uint256 collateralAmount;
        uint256 returnAmount;
        uint256 returnDateTimestamp;
    }
    mapping(uint256 => Borrowing) public borrowings;
    uint256 public borrowingsCount;

    /// @dev Contract constructor.
    /// @param _timelock timelock contract address that will directly execute proposals on the FamilySavings
    /// @param _members list of voters (family members)
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

    /// @notice deposit into the contract
    /// @param _token token address to deposit
    /// @param _amount amount to deposit
    function deposit(address _token, uint256 _amount) external {
        balances[_token] += _amount;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /// @notice withdraw from the contract to a specific address
    /// @param _to address where the funds will be withdrawn
    /// @param _token token address that will be withdrawn
    /// @param _amount amount to withdraw
    function withdraw(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        balances[_token] -= _amount;
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice set the collateral rate
    /// @param _lendingToken token address destined for lending
    /// @param _borrowingToken token address destined for borrowing
    /// @param _rate collateral rate | FORMAT: 1 ether = 100%
    function setCollateralRate(
        address _lendingToken,
        address _borrowingToken,
        uint256 _rate
    ) external onlyOwner {
        collateralRates[_lendingToken][_borrowingToken] = _rate;
    }

    /// @notice set the multiple collateral rates at once
    /// @param _lendingTokens token addresses destined for lending
    /// @param _borrowingTokens token addresses destined for borrowing
    /// @param _rates collateral rates | FORMAT: 1 ether = 100%
    function setCollateralRateBatched(
        address[] calldata _lendingTokens,
        address[] calldata _borrowingTokens,
        uint256[] calldata _rates
    ) external onlyOwner {
        for (uint256 i = 0; i < _lendingTokens.length; i++) {
            collateralRates[_lendingTokens[i]][_borrowingTokens[i]] = _rates[i];
        }
    }

    /// @notice set the annual lending rate
    /// @param _token  token address
    /// @param _rate annual rate | FORMAT: 1 ether = 100%
    function setAnnualLendingRate(
        address _token,
        uint256 _rate
    ) external onlyOwner {
        annualLendingRates[_token] = _rate;
    }

    /// @notice set the multiple annual lending rates at once
    /// @param _tokens  token addresses
    /// @param _rates annual rates | FORMAT: 1 ether = 100%
    function setAnnualLendingRateBatched(
        address[] calldata _tokens,
        uint256[] calldata _rates
    ) external onlyOwner {
        for (uint256 i = 0; i < _rates.length; i++) {
            annualLendingRates[_tokens[i]] = _rates[i];
        }
    }

    /// @notice borrow token by providing a collateral
    /// @param borrowToken token address for borrowing
    /// @param borrowAmount amount to borrow
    /// @param collateralToken token address as the collateral
    /// @param periodInDays number of days to borrow
    function borrow(
        address borrowToken,
        uint256 borrowAmount,
        address collateralToken,
        uint256 periodInDays
    ) external returns (uint256) {
        uint periodInSeconds = periodInDays * 86400;

        if (periodInSeconds < 7 days) revert PeriodTooShort();

        uint256 collateralRate = collateralRates[borrowToken][collateralToken];

        if (collateralRate == 0) revert TokenNotSupported();

        uint256 returnAmount = borrowAmount +
            (borrowAmount * annualLendingRates[borrowToken] * periodInDays) /
            365 /
            1 ether;

        uint256 collateralAmount = (returnAmount * collateralRate) / 1 ether;

        IERC20(collateralToken).safeTransferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );
        IERC20(borrowToken).safeTransfer(msg.sender, borrowAmount);

        borrowings[borrowingsCount] = Borrowing(
            borrowToken,
            collateralToken,
            borrowAmount,
            collateralAmount,
            returnAmount,
            block.timestamp + periodInSeconds
        );

        ++borrowingsCount;

        balances[borrowToken] -= borrowAmount;

        return borrowingsCount - 1;
    }

    /// @notice repay the debt
    /// @param index id of the borrowing (debt)
    function repay(uint256 index) external {
        Borrowing storage borrowing = borrowings[index];

        balances[borrowing.borrowToken] += borrowing.returnAmount;

        IERC20(borrowing.borrowToken).safeTransferFrom(
            msg.sender,
            address(this),
            borrowing.returnAmount
        );
        IERC20(borrowing.collateralToken).safeTransfer(
            msg.sender,
            borrowing.collateralAmount
        );

        borrowing.collateralAmount = 0;
        borrowing.returnAmount = 0;
    }

    /// @notice liquidate the collateral in the borrowing
    /// @param index id of the borrowing (debt)
    function liquidate(uint256 index) external {
        Borrowing storage borrowing = borrowings[index];

        if (block.timestamp < borrowing.returnDateTimestamp)
            revert TooEarlyForLiquidation();

        balances[borrowing.collateralToken] += borrowing.collateralAmount;

        borrowing.collateralAmount = 0;
        borrowing.returnAmount = 0;
    }

    /// @notice get borrowing by id
    function getBorrowingById(
        uint256 _id
    ) external view returns (Borrowing memory) {
        return borrowings[_id];
    }

    /// @notice add a voter (family member)
    function addMember(address _member) external onlyOwner {
        _mint(_member, MEMBERS_BALANCE);
    }

    /// @notice revoke a voter (family member)
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
