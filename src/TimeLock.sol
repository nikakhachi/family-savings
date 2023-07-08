// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "openzeppelin/governance/TimelockController.sol";

/**
 * @title TimeLock Contract
 * @author Nika Khachiashvili
 * @dev The contract important for the Governance. This will be the contract making the direct
 * @dev calls to the FamilySavings contract on behalf of the proposals
 */
contract TimeLock is TimelockController {
    /**
     * @dev Contract constructor.
     * @dev IMPORTANT: The optional admin can aid with initial configuration of roles after deployment
     * @dev without being subject to delay, but this role should be subsequently renounced in favor of
     * @dev administration through timelocked proposals. Previous versions of this contract would assign
     * @dev this admin to the deployer automatically and should be renounced as well.
     * @param minDelay is how long you have to wait before executing
     * @param proposers is the list of addresses that can propose
     * @param executors is the list of addresses that can execute
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors, msg.sender) {}
}
