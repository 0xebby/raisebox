// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";
import {IRaiseBoxCore} from "./interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxVoting} from "./interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxProposal} from "./interfaces/IRaiseBoxProposal.sol";
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";
import {IRaiseBoxContribution} from "src/interfaces/IRaiseBoxContribution.sol";

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
    IRaiseBoxContribution public raiseBoxContribution;


    constructor(
        address core, 
        address proposalAddress, 
        address votingAddress,
        address contributionAddress
        ) Ownable(msg.sender) {
        raiseBoxCore = IRaiseBoxCore(core);
        raiseBoxProposal = IRaiseBoxProposal(proposalAddress);
        raiseBoxVoting = IRaiseBoxVoting(votingAddress);
        raiseBoxContribution = IRaiseBoxContribution(contributionAddress);
    }

    function setVoting(address votingContract) external onlyOwner {
        raiseBoxVoting = IRaiseBoxVoting(votingContract);
        emit VotingSet(votingContract);
    }

    function setContribution(address contributionContract) external onlyOwner {
        raiseBoxContribution = IRaiseBoxContribution(contributionContract);
        emit RaiseBoxEventsLib.ContributionContractSetByDripHandler(contributionContract);
    }

    // track if a proposal has already had its drip executed
    mapping(bytes32 => mapping(uint256 => bool)) public drippedForProposal;

    // total amount dripped for a project
    mapping(bytes32 => uint256) public totalDrippedForProject;

    // tracks if any drip has been made for a raise
    mapping(bytes32 => bool) public dripped;

    // mapping to track refunds made to contributor
    mapping(bytes32 => mapping(address =>bool)) public refunded;

    function dripFundsForProposal(bytes32 raiseId_, uint256 proposalId) external nonReentrant
    {
        if (address(raiseBoxProposal) == address(0)) revert DripHandler_NotProposalContract();

        if (msg.sender != address(raiseBoxVoting)) revert DripHandler_NotVotingContract(msg.sender);

        /// @notice checks if proposal requesting drip is valid with a valid raiseId_
        raiseBoxProposal.isValidProposal(raiseId_, proposalId);

        // get raise info:
        /// @notice ascertain that raise exist using the raiseId further down
        /// @dev getRaiseInfo has a doesRaiseExist check embedded in it call stack that reverts early if an invalid raiseId is passed
        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId_);


        /// raise state should be in VOTING
        if (raiseInfo.raiseState != IRaiseBoxCore.RaiseState.DRIPPING) {
            revert RaiseBoxErrorsLib.RaiseBoxDripHandler_dripFunds_NotInDrippingState(raiseId_, raiseInfo.raiseState);
        }

        if (drippedForProposal[raiseId_][proposalId]) revert RaiseBoxErrorsLib.RaiseBoxDripHandler_dripFunds_DripAlreadyExecuted(raiseId_, proposalId);

        // determine percentage to drip using proposal count and last drip data
        uint256 propCount = raiseBoxProposal.getProposalCount(raiseId_);
        uint8 dripPercent = raiseBoxProposal.getDripPercent(raiseId_, proposalId);

        // compute amount to release based on amount raised at time of raise
        uint256 amountRaised = raiseInfo.raiseContributionInfo.amountRaisedByProject;
        uint256 amountToDrip = ((amountRaised - totalDrippedForProject[raiseId_]) * dripPercent) / 100;

        // ensure this contract has enough balance
        uint256 dripBalance = address(this).balance;
        if (dripBalance < amountToDrip) revert Drip_InsufficientBalance(dripBalance, amountToDrip);

        // effects
        drippedForProposal[raiseId_][proposalId] = true;
        totalDrippedForProject[raiseId_] += amountToDrip;
        dripped[raiseId_] = true;

        // interactions - send funds to project owner
        address payable projectOwner = payable(raiseInfo.raiseCreationInfo.raiseOwner);
        (bool sent,) = projectOwner.call{value: amountToDrip}("");

        if (!sent) revert Drip_InsufficientBalance(address(this).balance, amountToDrip);

        emit FundsDripped(raiseId_, proposalId, dripPercent, amountToDrip);
    }

    // ---------- Read helpers ----------

    function hasDripped(bytes32 raiseId_, uint256 proposalId) external view returns (bool) {
        return drippedForProposal[raiseId_][proposalId];
    }

    function drippedForRaise(bytes32 raiseId_) external view returns (bool) {
        _drippedForRaise(raiseId_);
    }

    function _drippedForRaise(bytes32 raiseId_) internal view returns (bool) {
        raiseBoxCore.doesRaiseExist(raiseId_);
        return dripped[raiseId_];
    }

    function drip(bytes32 raiseId_, uint256 proposalId) external {
        this.dripFundsForProposal(raiseId_, proposalId);
    }

    /// @notice Accept ETH into the drip handler (protocol must point here)
    receive() external payable {}

    modifier onlyContributor(bytes32 raiseId_) {

        // valid raise check
        raiseBoxCore.doesRaiseExist(raiseId_);

        // sender is contributor
        bool contributed = raiseBoxContribution.hasUserContributed(raiseId_, msg.sender);

        _;
    }

    function refund(bytes32 raiseId_) external onlyContributor(raiseId_) {
        // actually processes refund to contributors for failed raises
        // get raise info:
        /// @notice ascertain that raise exist busing the raiseId further down
        /// @dev getRaiseInfo has a doesRaiseExist check embedded in it call stack that reverts early if an invalid raiseId is passed
        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId_);

        if (raiseInfo.raiseState != IRaiseBoxCore.RaiseState.FAILED) {
            revert RaiseBoxErrorsLib.RaiseBoxDripHandler_refund_NotFailedRaise(raiseId_, raiseInfo.raiseState);
        }
        
        // amount contributed === amount to refund for raise target not met failure
        bool dripped = _drippedForRaise(raiseId_);

        if (!dripped) {

            // contributor's refund amount is the full contributions
            uint256 contributions = raiseBoxContribution.getUserRaiseContributions(raiseId_, msg.sender);

            refunded[raiseId_][msg.sender] = true;

            // send contributions back to contributor
            (bool refundedSuccessfully,) = msg.sender.call{value: contributions}("");

            if (!refundedSuccessfully) {
                revert RaiseBoxErrorsLib.RaiseBoxRefunds_refundContribution_RefundFailed(raiseId_, msg.sender);
            }

            emit RaiseBoxEventsLib.RaiseBoxRefunds_refundContribution_Refunded(
                block.timestamp, 
                msg.sender, 
                contributions, 
                raiseId_
                );

        } else {
            // this would handle refunds for after proposals were dripped and protocol fees deducted

            //  emit RaiseBoxEventsLib.RaiseBoxRefunds_refundContribution_Refunded(
            //     block.timestamp, 
            //     msg.sender, 
            //     contributions, 
            //     raiseId_
            //     );
        }
        

    }




    
}
