// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";

contract FamilySavings is Ownable {
    mapping(address => uint256) public balances;

    constructor(address _timelock) {
        transferOwnership(_timelock);
    }

    function deposit(address _token, uint256 _amount) external {
        balances[_token] += _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(address _token, uint256 _amount) external onlyOwner {
        balances[_token] -= _amount;
        IERC20(_token).transfer(address(this), _amount);
    }
}
