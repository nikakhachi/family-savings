// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "openzeppelin/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint _initialSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
    }
}
