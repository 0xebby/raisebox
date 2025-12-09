// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";
import {IRaiseBoxCore} from "./interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxVoting} from "./interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxProposal} from "./interfaces/IRaiseBoxProposal.sol";

/**
 * @title RaiseBoxDripHandler
 * @notice Handles releasing (dripping) funds to project owners when milestone proposals pass.
 * @dev Assumes voting contract provides a tally that can be used to decide if proposal passed.
 *      Designed to be set as the `protocol` address in `RaiseBoxCore` so contributions are
 *      held here and released by this contract. Owner should set core/proposal/voting addresses.
 */
contract RaiseBoxDripHandler is Ownable, ReentrancyGuard, IRaiseBoxDripHandler {
    IRaiseBoxCore public raiseBoxCore;
    IRaiseBoxVoting public raiseBoxVoting;
    IRaiseBoxProposal public raiseBoxProposal;

    constructor(address core, address proposalAddress, address votingAddress) Ownable(msg.sender) {
        raiseBoxCore = IRaiseBoxCore(core);
        raiseBoxProposal = IRaiseBoxProposal(proposalAddress);
        raiseBoxVoting = IRaiseBoxVoting(votingAddress);
    }

    function setVoting(address votingContract) external onlyOwner {
        raiseBoxVoting = IRaiseBoxVoting(votingContract);
        emit VotingSet(votingContract);
    }

    // get needed raiseBox contracts from the core using the getters instead of doing it from constructor:
    // address public raiseBoxVoting = raiseBoxCore.getVotingContract();
    // address public raiseBoxProposal = raiseBoxCore.getProposalContract();

    // track if a proposal has already had its drip executed
    mapping(bytes32 => mapping(uint256 => bool)) public drippedForProposal;

    // total amount dripped for a project
    mapping(bytes32 => uint256) public totalDrippedForProject;

    // last drip percent for a project (5..100 in multiples of 5)
    // least drip is 5% and max allowed drip is 25%
    // only two 25% drips allowed and cannot be consecutive nor the first drip
    // first drip is max 10%
    mapping(bytes32 => uint8) public lastDripPercent;

    // number of times 25% drip used for a project
    mapping(bytes32 => uint8) public _25DripsUsed;

    // maximum allowed 25% drips per project lifecycle
    uint8 public constant MAX_25P_DRIPS = 2;

    // constructor() Ownable(msg.sender) {}

    /// @notice Accept ETH into the drip handler (protocol must point here)
    receive() external payable {}

    function dripFundsForProposal(bytes32 raiseId, uint256 proposalId) external 
    /**
     * nonReentrant
     */
    {
        if (address(raiseBoxProposal) == address(0)) revert DripHandler_NotProposalContract();

        if (msg.sender != address(raiseBoxVoting)) revert DripHandler_NotVotingContract(msg.sender);

        if (!raiseBoxCore.doesRaiseExist(raiseId)) revert Drip_InvalidProject();

        if (drippedForProposal[raiseId][proposalId]) revert Drip_AlreadyExecuted(raiseId, proposalId);

        // determine percentage to drip using proposal count and last drip data
        uint256 propCount = raiseBoxProposal.getProposalCount(raiseId);
        uint8 dripPercent = _determineDripPercent(raiseId, propCount);

        // compute amount to release based on amount raised at time of raise
        uint256 amountRaised = raiseBoxCore.getAmtRaisedByProject(raiseId);
        uint256 amountToDrip = ((amountRaised - totalDrippedForProject[raiseId]) * dripPercent) / 100;

        // ensure this contract has enough balance
        uint256 dripBalance = address(this).balance;
        if (dripBalance < amountToDrip) revert Drip_InsufficientBalance(dripBalance, amountToDrip);

        // effects
        drippedForProposal[raiseId][proposalId] = true;
        totalDrippedForProject[raiseId] += amountToDrip;
        lastDripPercent[raiseId] = dripPercent;

        if (dripPercent == 25) {
            // increment 25% usage
            if (_25DripsUsed[raiseId] < type(uint8).max) {
                _25DripsUsed[raiseId] += 1;
            }
        }

        // interactions - send funds to project owner
        address payable projectOwner = payable(raiseBoxCore.getRaiseCreator(raiseId));
        (bool sent,) = projectOwner.call{value: amountToDrip}("");

        if (!sent) revert Drip_InsufficientBalance(address(this).balance, amountToDrip);

        emit FundsDripped(raiseId, proposalId, dripPercent, amountToDrip);
    }

    /// @notice Determine drip percent per project/proposal following rules
    /// @dev Rules implemented:
    /// - if proposalCount <= 1 => 10%
    /// - if proposalCount == 2 => 25%
    /// - if proposalCount > 2 && lastDripPercent != 25 && _25DripsUsed < MAX_25P_DRIPS => 25%
    /// - if proposalCount > 2 && lastDripPercent == 25 => 15%
    /// - else => 10%
    function _determineDripPercent(bytes32 raiseId, uint256 propCount) internal view returns (uint8) {
        if (propCount <= 1) {
            return 10;
        }

        if (propCount == 2) {
            if (_25DripsUsed[raiseId] < MAX_25P_DRIPS && lastDripPercent[raiseId] != 25) {
                return 25;
            }
            return 15;
        }

        // propCount > 2
        if (lastDripPercent[raiseId] == 25) {
            // revert RaiseBoxDripHandler_PreviousDripIs25();
            return 15;
        }

        // attempt to give 25% if the project hasn't exhausted its two 25% drips
        if (_25DripsUsed[raiseId] < MAX_25P_DRIPS) {
            return 25;
        }

        // fallback
        return 10;
    }

    // ---------- Read helpers ----------

    function hasDripped(bytes32 raiseId, uint256 proposalId) external view returns (bool) {
        return drippedForProposal[raiseId][proposalId];
    }

    function getLastDripPercent(bytes32 raiseId) external view returns (uint8) {
        return lastDripPercent[raiseId];
    }

    function get25DripUsed(bytes32 raiseId) external view returns (uint8) {
        return _25DripsUsed[raiseId];
    }

    function drip(bytes32 raiseId, uint256 proposalId) external {
        this.dripFundsForProposal(raiseId, proposalId);
    }

    // /// @notice Set the central RaiseBoxCore contract address
    // function setCore(address coreAddress) external onlyOwner {
    //     require(coreAddress != address(0), "core address zero");
    //     raiseBoxCore = IRaiseBoxCore(coreAddress);
    //     emit CoreSet(coreAddress);
    // }

    // /// @notice Set the RaiseBoxVoting contract address
    // function setVoting(address votingAddress) external onlyOwner {
    //     require(votingAddress != address(0), "voting address zero");
    //     raiseBoxVoting = IRaiseBoxVoting(votingAddress);
    //     emit VotingSet(votingAddress);
    // }

    // /// @notice Set the RaiseBoxProposal contract address
    // function setProposal(address proposalAddress) external onlyOwner {
    //     require(proposalAddress != address(0), "proposal address zero");
    //     raiseBoxProposal = IRaiseBoxProposal(proposalAddress);
    //     emit ProposalSet(proposalAddress);
    // }

    /// @notice Called to drip funds for a passed proposal. Only callable by the Proposal contract.
    /// @dev This calls `raiseBoxVoting._tallyVotes(...)` and require [forVotes > againstVotes].
    /**
     * @notice Drip rules:
     *     - max funds drip at anytime should be 25%
     *     - funds drip on very first proposal after raise is capped at 10%
     *     - 25% funds drip can only be dripped twice throughout project lifecycle
     *     - 25% fund drip cannot happen consecutively:
     *       i.e after receiving a 25% fund drip, project cannot receive another 25%
     *       in the very next drip.
     *     - after first 25% fund drip, drips are capped at 15% untill a drip after the last 25% drip
     *     - drips %: in multiples of 5 up to 100
     *     - only 10% of overall funds contributed at time of hosting proposal is released per time?
     *     - if proposalCount <= 1 => 10% fund drip
     *     - if proposalCount == 2 => 25% fund drip
     *     - if proposalCount > 2 && lastDripPercent != 25 && _25DripsUsed < MAX_25P_DRIPS => 25%
     *     - if proposalCount > 2 && lastDripPercent == 25 => 15%
     *     - else => 10%
     *
     *     @param raiseId The project ID
     *     @param proposalId The proposal ID
     */
}
