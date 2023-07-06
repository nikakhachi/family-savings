// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FamilySavings.sol";
import "../src/GovernanceToken.sol";
import "../src/MyGovernor.sol";
import "../src/TimeLock.sol";
import "../src/Token.sol";

contract FamilySavingsTest is Test {
    uint256 public constant TOKEN_INITIAL_SUPPLY = 1000 * 10 ** 18;
    uint256 public constant TIMELOCK_MIN_DELAY = 1 weeks;
    uint256 public constant VOTING_DELAY = 7200;
    uint256 public constant VOTING_PERIOD = 50400;
    uint256 public constant QUORUM_FRACTION = 30;

    address[] public voters = [address(this), address(1), address(2)];
    address[] public emptyArray;

    FamilySavings public familySavings;
    GovernanceToken public governanceToken;
    MyGovernor public myGovernor;
    TimeLock public timeLock;
    Token public token;

    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;
    string public description;

    function setUp() public {
        governanceToken = new GovernanceToken(voters);

        for (uint i = 0; i < voters.length; i++) {
            vm.prank(voters[i]);
            governanceToken.delegate(voters[i]);
        }

        timeLock = new TimeLock(
            TIMELOCK_MIN_DELAY,
            emptyArray,
            emptyArray,
            address(this)
        );

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 timelockAdminRole = timeLock.TIMELOCK_ADMIN_ROLE();

        myGovernor = new MyGovernor(
            governanceToken,
            timeLock,
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_FRACTION
        );

        timeLock.grantRole(proposerRole, address(myGovernor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(timelockAdminRole, address(this));

        familySavings = new FamilySavings(address(timeLock));
        token = new Token("Test Token", "TTK", TOKEN_INITIAL_SUPPLY);
    }

    function testDeposit() public {
        token.approve(address(familySavings), TOKEN_INITIAL_SUPPLY);
        familySavings.deposit(address(token), TOKEN_INITIAL_SUPPLY);
        assertEq(familySavings.balances(address(token)), TOKEN_INITIAL_SUPPLY);
        assertEq(token.balanceOf(address(familySavings)), TOKEN_INITIAL_SUPPLY);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testWithdraw() public {
        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "withdraw(address,address,uint256)",
                address(address(2)),
                address(token),
                TOKEN_INITIAL_SUPPLY
            )
        ];
        description = "Withdraw Funds";

        token.approve(address(familySavings), TOKEN_INITIAL_SUPPLY);
        familySavings.deposit(address(token), TOKEN_INITIAL_SUPPLY);
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

        assertEq(token.balanceOf(address(familySavings)), TOKEN_INITIAL_SUPPLY);
        assertEq(token.balanceOf(address(2)), 0);

        myGovernor.execute(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        assertEq(token.balanceOf(address(familySavings)), 0);
        assertEq(token.balanceOf(address(2)), TOKEN_INITIAL_SUPPLY);
    }
}
