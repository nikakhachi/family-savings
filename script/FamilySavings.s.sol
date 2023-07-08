// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";

import "../src/FamilySavings.sol";
import "../src/MyGovernor.sol";
import "../src/TimeLock.sol";
import "../src/Token.sol";
import "forge-std/console.sol";

contract Deploy is Script {
    uint256 public constant TIMELOCK_MIN_DELAY = 1 weeks; /// @dev minDelay arg for TimeLock contract

    /// @dev variables for the MyGovernor contract
    uint256 public constant VOTING_DELAY = 7200;
    uint256 public constant VOTING_PERIOD = 50400;
    uint256 public constant QUORUM_FRACTION = 50;

    /// @dev list of voters (members of the family)
    address[] public voters = [address(this), address(1), address(2)];

    address[] public emptyArray; /// @dev for utility reasons

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        TimeLock timeLock = new TimeLock(
            TIMELOCK_MIN_DELAY,
            emptyArray,
            emptyArray
        );

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 timelockAdminRole = timeLock.TIMELOCK_ADMIN_ROLE();

        FamilySavings familySavings = new FamilySavings(
            address(timeLock),
            voters
        );

        MyGovernor myGovernor = new MyGovernor(
            familySavings,
            timeLock,
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_FRACTION
        );

        timeLock.grantRole(proposerRole, address(myGovernor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(timelockAdminRole, address(this));

        vm.stopBroadcast();
    }
}
