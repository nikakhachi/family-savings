// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./FamilySavings.t.sol";

/// @dev openzeppelin has already audited contracts but in these tests I just want to make sure
/// @dev that the setup of the governance over the FamilySavings is done correctly.
/// @dev That's why not every funtionality are tested but only the vital ones
contract GovernanceTest is FamilySavingsTest {
    function testProposalWithFirstAndSecondInFavor() public {
        _beforeEach();
        _proposeAndVote(1, 1, 0);
        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }

    function testProposalWithFirstAndThirdInFavor() public {
        _beforeEach();
        _proposeAndVote(1, 0, 1);
        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }

    function testProposalWithSecondAndThirdInFavor() public {
        _beforeEach();
        _proposeAndVote(1, 1, 0);
        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }

    function testProposalWithFirstInFavor() public {
        _beforeEach();
        _proposeAndVote(1, 0, 0);
        vm.expectRevert(bytes("Governor: proposal not successful"));
        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }

    function testProposalWithSecondInFavorFailing() public {
        _beforeEach();
        _proposeAndVote(0, 1, 0);
        vm.expectRevert(bytes("Governor: proposal not successful"));
        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }

    function testProposalWithThirdInFavorFailing() public {
        _beforeEach();
        _proposeAndVote(0, 0, 1);
        vm.expectRevert(bytes("Governor: proposal not successful"));
        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }

    function testProposalWithOneParticipating() public {
        _beforeEach();
        _proposeAndVote(1, 3, 3);
        vm.expectRevert(bytes("Governor: proposal not successful"));
        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }

    function _beforeEach() internal {
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
    }

    function _proposeAndVote(
        uint8 _vote1,
        uint8 _vote2,
        uint8 _vote3
    ) internal {
        uint256 proposalId = myGovernor.propose(
            targets,
            values,
            calldatas,
            description
        );

        vm.roll(VOTING_DELAY + 2);

        if (_vote1 != 3) myGovernor.castVote(proposalId, _vote1);
        if (_vote2 != 3) {
            vm.prank(address(1));
            myGovernor.castVote(proposalId, _vote2);
        }
        if (_vote3 != 3) {
            vm.prank(address(2));
            myGovernor.castVote(proposalId, _vote3);
        }

        vm.roll(VOTING_DELAY + VOTING_PERIOD + 3);
    }
}
