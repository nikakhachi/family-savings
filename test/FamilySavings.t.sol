// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FamilySavings.sol";
import "../src/MyGovernor.sol";
import "../src/TimeLock.sol";
import "../src/Token.sol";

contract FamilySavingsTest is Test {
    uint256 public constant TOKEN0_INITIAL_SUPPLY = 10000 * 10 ** 18;
    uint256 public constant TOKEN0_INITIAL_DEPOSIT = 1000 * 10 ** 18;
    uint256 public constant TOKEN1_INITIAL_SUPPLY = 10000 * 10 ** 18;
    uint256 public constant TIMELOCK_MIN_DELAY = 1 weeks;
    uint256 public constant VOTING_DELAY = 7200;
    uint256 public constant VOTING_PERIOD = 50400;
    uint256 public constant QUORUM_FRACTION = 30;

    address[] public voters = [address(this), address(1), address(2)];
    address[] public emptyArray;

    FamilySavings public familySavings;
    MyGovernor public myGovernor;
    TimeLock public timeLock;
    Token public token0;
    Token public token1;

    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;
    string public description;

    function setUp() public {
        timeLock = new TimeLock(
            TIMELOCK_MIN_DELAY,
            emptyArray,
            emptyArray,
            address(this)
        );

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 timelockAdminRole = timeLock.TIMELOCK_ADMIN_ROLE();

        familySavings = new FamilySavings(address(timeLock), voters);

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

    function testDepositExisingToken() public {
        assertEq(
            token0.balanceOf(address(familySavings)),
            TOKEN0_INITIAL_DEPOSIT
        );
        assertEq(token0.balanceOf(address(this)), TOKEN0_INITIAL_SUPPLY);
        assertEq(
            familySavings.balances(address(token0)),
            TOKEN0_INITIAL_DEPOSIT
        );

        token0.approve(address(familySavings), TOKEN0_INITIAL_SUPPLY);
        familySavings.deposit(address(token0), TOKEN0_INITIAL_SUPPLY);

        assertEq(
            familySavings.balances(address(token0)),
            TOKEN0_INITIAL_SUPPLY + TOKEN0_INITIAL_DEPOSIT
        );
        assertEq(
            token0.balanceOf(address(familySavings)),
            TOKEN0_INITIAL_SUPPLY + TOKEN0_INITIAL_DEPOSIT
        );
        assertEq(token0.balanceOf(address(this)), 0);
    }

    function testDepositNewToken() public {
        assertEq(familySavings.balances(address(token1)), 0);
        assertEq(token1.balanceOf(address(familySavings)), 0);
        assertEq(token1.balanceOf(address(this)), TOKEN1_INITIAL_SUPPLY);

        token1.approve(address(familySavings), TOKEN1_INITIAL_SUPPLY);
        familySavings.deposit(address(token1), TOKEN1_INITIAL_SUPPLY);

        assertEq(
            familySavings.balances(address(token1)),
            TOKEN1_INITIAL_SUPPLY
        );
        assertEq(
            token1.balanceOf(address(familySavings)),
            TOKEN1_INITIAL_SUPPLY
        );
        assertEq(token1.balanceOf(address(this)), 0);
    }

    function testWithdraw() public {
        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "withdraw(address,address,uint256)",
                address(address(2)),
                address(token0),
                TOKEN0_INITIAL_DEPOSIT
            )
        ];
        description = "Withdraw Funds";

        assertEq(
            token0.balanceOf(address(familySavings)),
            TOKEN0_INITIAL_DEPOSIT
        );
        assertEq(token0.balanceOf(address(2)), 0);

        _proposeAndExecute();

        assertEq(token0.balanceOf(address(familySavings)), 0);
        assertEq(token0.balanceOf(address(2)), TOKEN0_INITIAL_DEPOSIT);
    }

    function testSetCollateralRate() public {
        uint rate = 10;

        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "setCollateralRate(address,address,uint256)",
                address(token0),
                address(token1),
                rate
            )
        ];
        description = "Set Collateral Rate";

        assertEq(
            familySavings.collateralRates(address(token0), address(token1)),
            0
        );

        _proposeAndExecute();

        assertEq(
            familySavings.collateralRates(address(token0), address(token1)),
            rate
        );
    }

    address[] public addressArray1;
    address[] public addressArray2;
    uint256[] public uint256Array;

    function testSetCollateralRateBatched() public {
        addressArray1 = [address(token0), address(token1)];
        addressArray2 = [address(token1), address(token0)];
        uint256Array = [10, 20];

        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "setCollateralRateBatched(address[],address[],uint256[])",
                addressArray1,
                addressArray2,
                uint256Array
            )
        ];
        description = "Set Collateral Rates";

        assertEq(
            familySavings.collateralRates(addressArray1[0], addressArray2[0]),
            0
        );
        assertEq(
            familySavings.collateralRates(addressArray1[1], addressArray2[1]),
            0
        );

        _proposeAndExecute();

        assertEq(
            familySavings.collateralRates(addressArray1[0], addressArray2[0]),
            uint256Array[0]
        );
        assertEq(
            familySavings.collateralRates(addressArray1[1], addressArray2[1]),
            uint256Array[1]
        );
    }

    function testSetDailyLendingRate() public {
        uint rate = 10;

        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "setDailyLendingRate(address,uint256)",
                address(token0),
                rate
            )
        ];
        description = "Set Daily Lending Rate";

        assertEq(familySavings.dailyLendingRates(address(token0)), 0);

        _proposeAndExecute();

        assertEq(familySavings.dailyLendingRates(address(token0)), rate);
    }

    function testSetDailyLendingRatesBatched() public {
        addressArray1 = [address(token0), address(token1)];
        uint256Array = [10, 20];

        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "setDailyLendingRateBatched(address[],uint256[])",
                addressArray1,
                uint256Array
            )
        ];
        description = "Set Daily Lending Rates";

        assertEq(familySavings.dailyLendingRates(addressArray1[0]), 0);
        assertEq(familySavings.dailyLendingRates(addressArray1[1]), 0);

        _proposeAndExecute();

        assertEq(
            familySavings.dailyLendingRates(addressArray1[0]),
            uint256Array[0]
        );
        assertEq(
            familySavings.dailyLendingRates(addressArray1[1]),
            uint256Array[1]
        );
    }

    function _proposeAndExecute() private {
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
