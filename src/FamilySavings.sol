// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import "openzeppelin/access/Ownable.sol";

contract FamilySavings is Ownable, ERC20, ERC20Permit, ERC20Votes {
    uint256 public constant VOTER_BALANCE = 10 ** 18;

    mapping(address => uint256) public balances;

    constructor(
        address _timelock,
        address[] memory _voters
    )
        ERC20("FamilySavingsGovernance", "FSG")
        ERC20Permit("FamilySavingsGovernance")
    {
        transferOwnership(_timelock);
        uint256 n = _voters.length;
        for (uint256 i; i < n; i++) {
            _mint(_voters[i], VOTER_BALANCE);
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
