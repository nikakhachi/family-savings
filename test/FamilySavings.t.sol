// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/FamilySavings.sol";

contract FamilySavingsTest is Test {
    FamilySavings public familySavings;

    function setUp() public {
        familySavings = new FamilySavings();
    }
}
