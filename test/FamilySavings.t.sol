// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FamilySavings.sol";
import "../src/MyGovernor.sol";
import "../src/TimeLock.sol";
import "../src/Token.sol";

/// @dev This contract is a parent test contract for FamilySavings contract
/// @dev Contains all the variables, setUp() and _proposeAndExecute() script
contract FamilySavingsTest is Test {
    uint256 public constant TOKEN0_INITIAL_SUPPLY = 10000 * 10 ** 18; /// @dev amount minted to deployer
    uint256 public constant TOKEN0_INITIAL_DEPOSIT = 1000 * 10 ** 18; /// @dev amount deposited to contract
    uint256 public constant TOKEN1_INITIAL_SUPPLY = 10000 * 10 ** 18; /// @dev amount minted to deployer
    uint256 public constant TIMELOCK_MIN_DELAY = 1 weeks; /// @dev minDelay arg for TimeLock contract

    /// @dev variables for the MyGovernor contract
    uint256 public constant VOTING_DELAY = 7200;
    uint256 public constant VOTING_PERIOD = 50400;
    uint256 public constant QUORUM_FRACTION = 50;

    /// @dev list of voters (members of the family)
    address[] public voters = [address(this), address(1), address(2)];

    address[] public emptyArray; /// @dev for utility reasons

    FamilySavings public familySavings;
    MyGovernor public myGovernor;
    TimeLock public timeLock;
    Token public token0;
    Token public token1;

    /// @dev variables for proposing proposals
    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;
    string public description;

    function setUp() public {
        timeLock = new TimeLock(TIMELOCK_MIN_DELAY, emptyArray, emptyArray);

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 timelockAdminRole = timeLock.TIMELOCK_ADMIN_ROLE();

        familySavings = new FamilySavings(address(timeLock), voters);

        /// @dev voters delegating themselves
        /// @dev "The downside is that it requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked."
        /// @dev https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Votes
        for (uint i = 0; i < voters.length; i++) {
            vm.prank(voters[i]);
            familySavings.delegate(voters[i]);
        }

        myGovernor = new MyGovernor(
            familySavings,
            timeLock,
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_FRACTION
        );

        timeLock.grantRole(proposerRole, address(myGovernor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(timelockAdminRole, address(this));

        token0 = new Token(
            "Test Token 0",
            "TTK",
            TOKEN0_INITIAL_SUPPLY + TOKEN0_INITIAL_DEPOSIT
        );

        token0.approve(address(familySavings), TOKEN0_INITIAL_DEPOSIT);
        familySavings.deposit(address(token0), TOKEN0_INITIAL_DEPOSIT);

        token1 = new Token("Test Token 1", "TTK", TOKEN1_INITIAL_SUPPLY);
    }

    function _proposeAndExecute() internal {
        uint256 proposalId = myGovernor.propose(
            targets,
            values,
            calldatas,
            description
        );

        vm.roll(VOTING_DELAY + 2);

        myGovernor.castVote(proposalId, 1);
        vm.prank(address(1));
        myGovernor.castVote(proposalId, 0);
        vm.prank(address(2));
        myGovernor.castVote(proposalId, 1);

        vm.roll(VOTING_DELAY + VOTING_PERIOD + 3);

        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        skip(TIMELOCK_MIN_DELAY + 1);

        myGovernor.execute(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }
}
