// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";
import {IRaiseBoxCore} from "./interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxVoting} from "./interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxProposal} from "./interfaces/IRaiseBoxProposal.sol";
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";

/**
 * @title RaiseBoxDripHandler
 * @notice Handles releasing (dripping) funds to project owners when milestone proposals pass.
 * @dev Assumes voting contract provides a tally that can be used to decide if proposal passed.
 * @dev Designed to be set as the `protocol` address in `RaiseBoxCore` so contributions are
 * @dev held here and released by this contract. Owner should set core/proposal/voting addresses.
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

    // track if a proposal has already had its drip executed
    mapping(bytes32 => mapping(uint256 => bool)) public drippedForProposal;

    // total amount dripped for a project
    mapping(bytes32 => uint256) public totalDrippedForProject;

    function dripFundsForProposal(bytes32 raiseId, uint256 proposalId) external nonReentrant
    {
        if (address(raiseBoxProposal) == address(0)) revert DripHandler_NotProposalContract();

        if (msg.sender != address(raiseBoxVoting)) revert DripHandler_NotVotingContract(msg.sender);

        /// @notice checks if proposal requesting drip is valid with a valid raiseId
        raiseBoxProposal.isValidProposal(raiseId, proposalId);

        /// raise state should be in VOTING

        if (drippedForProposal[raiseId][proposalId]) revert RaiseBoxErrorsLib.RaiseBoxDripHandler_dripFunds_DripAlreadyExecutedForProposal(raiseId, proposalId);

        // determine percentage to drip using proposal count and last drip data
        uint256 propCount = raiseBoxProposal.getProposalCount(raiseId);
        uint8 dripPercent = raiseBoxProposal.getDripPercent(raiseId, proposalId);

        // compute amount to release based on amount raised at time of raise
        uint256 amountRaised = raiseBoxCore.getAmtRaisedByProject(raiseId);
        uint256 amountToDrip = ((amountRaised - totalDrippedForProject[raiseId]) * dripPercent) / 100;

        // ensure this contract has enough balance
        uint256 dripBalance = address(this).balance;
        if (dripBalance < amountToDrip) revert Drip_InsufficientBalance(dripBalance, amountToDrip);

        // effects
        drippedForProposal[raiseId][proposalId] = true;
        totalDrippedForProject[raiseId] += amountToDrip;

        // interactions - send funds to project owner
        address payable projectOwner = payable(raiseBoxCore.getRaiseCreator(raiseId));
        (bool sent,) = projectOwner.call{value: amountToDrip}("");

        if (!sent) revert Drip_InsufficientBalance(address(this).balance, amountToDrip);

        emit FundsDripped(raiseId, proposalId, dripPercent, amountToDrip);
    }

    // ---------- Read helpers ----------

    function hasDripped(bytes32 raiseId, uint256 proposalId) external view returns (bool) {
        return drippedForProposal[raiseId][proposalId];
    }

    function drip(bytes32 raiseId, uint256 proposalId) external {
        this.dripFundsForProposal(raiseId, proposalId);
    }

    /// @notice Accept ETH into the drip handler (protocol must point here)
    receive() external payable {}
}
