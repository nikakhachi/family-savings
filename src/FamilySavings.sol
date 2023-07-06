// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import "openzeppelin/access/Ownable.sol";

contract FamilySavings is Ownable, ERC20, ERC20Permit, ERC20Votes {
    uint256 public constant MEMBERS_BALANCE = 10 ** 18;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public dailyLendingRates;
    mapping(address => mapping(address => uint256)) public collateralRates;

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
