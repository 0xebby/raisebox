// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import "../lib/forge-std/src/Test.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";
import{RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";

contract RaiseBoxVoting is IRaiseBoxVoting {
    IRaiseBoxCore public immutable raiseBoxCore; 

    IRaiseBoxContribution public immutable raiseBoxContribution; 

    IRaiseBoxProposal public immutable raiseBoxProposal; 

    IRaiseBoxDripHandler public immutable raiseBoxDripHandler; 

    //** ------------------------------------------------------------------ **//
    //                        CONSTRUCTOR                                     //
    //** ------------------------------------------------------------------ **//

    constructor(
        address raiseBoxCoreAddress,
        address raiseBoxContributionAddress,
        address raiseBoxProposalAddress,
        address raiseBoxDripHandlerAddress
    ) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
        raiseBoxContribution = IRaiseBoxContribution(raiseBoxContributionAddress);
        raiseBoxProposal = IRaiseBoxProposal(raiseBoxProposalAddress);
        raiseBoxDripHandler = IRaiseBoxDripHandler(raiseBoxDripHandlerAddress);
    }

    //** ------------------------------------------------------------------ **//
    //                        MODIFIERS                                       //
    //** ------------------------------------------------------------------ **//

    modifier canVote(bytes32 raiseId_, address user_, uint256 proposalId_) {

        raiseBoxProposal.isValidProposal(raiseId_, proposalId_);

        uint256 _start = _voteStartTime(raiseId_, proposalId_);
        // voting must have been scheduled (start set) before voting commences
        if (_start == 0 || block.timestamp < _start) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_VotingNotStarted(raiseId_, proposalId_);
        }

        // this allows any attempt to vote after voting deadline to trigger funds dripper
        if (s_votingEnded[raiseId_][proposalId_] || block.timestamp > (_start + VOTING_DURATION)) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_VotingAlreadyEnded(raiseId_, proposalId_);
        }

        // checks if proposal is live for raise
        
        if (raiseBoxCore.getRaiseState(raiseId_) != IRaiseBoxCore.RaiseState.VOTING) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_RaiseNotInVotingState();
        }

        if (raiseBoxProposal.getProposalState(raiseId_, proposalId_) != IRaiseBoxProposal.ProposalState.ACTIVE) {
            revert RaiseBoxVoting_ProposalNotLive();
        }

        // ascertain msg.sender has contributed to project
        bool hasContributedToProject = raiseBoxContribution.hasUserContributed(raiseId_, user_);

        if (!hasContributedToProject) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_NotContributor(raiseId_, user_);
        }

        if (s_hasDelegatedForProposal[user_][raiseId_][proposalId_]) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_AlreadyDelegatedVote(user_);
        }

        if (s_hasVotedOnProposal[raiseId_][proposalId_][user_]) {
            revert RaiseBoxVoting_AlreadyVoted(proposalId_, user_);
        }

        _;
    }

    modifier canDelegate(bytes32 raiseId_, uint256 proposalId_, address from_, address to_) {
        raiseBoxProposal.isValidProposal(raiseId_, proposalId_);

        bool fromIsContributor = raiseBoxContribution.hasUserContributed(raiseId_, from_);
        bool toIsContributor = raiseBoxContribution.hasUserContributed(raiseId_, to_);

        if (!fromIsContributor || !toIsContributor) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_canDelegate_NotAContributor(raiseId_);
        }

        if (to_ == from_) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_CannotDelegateToSelf();
        }

        if (from_ != msg.sender) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_CanOnlyDelegateOwnVote();
        }

        if (s_hasVotedOnProposal[raiseId_][proposalId_][from_] || s_hasVotedOnProposal[raiseId_][proposalId_][to_]) {
            revert RaiseBoxVoting_CannotDelegateAfterVoting(proposalId_, from_);
        }

        if (block.timestamp >= _voteStartTime(raiseId_, proposalId_)) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_CannotDelegateAfterVotingBegins();
        }

        if (s_delegatedVotes[from_][raiseId_][proposalId_] > 0 ) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_CannotReDelegate();
        } // fixed redelegation after being delegated votes -- ebby

        if (s_hasDelegatedForProposal[from_][raiseId_][proposalId_]) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_CannotDelegateTwice();
        } 

        if (s_hasDelegatedForProposal[to_][raiseId_][proposalId_]) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_ToAlreadyInDelegationGraph(to_);
        }
        _;
    }

    modifier onlyRaiseCreator(bytes32 raiseId) {
        if (msg.sender != raiseBoxCore.getRaiseCreator(raiseId)) revert RaiseBoxVoting_NotRaiseOwner(msg.sender);

        _;

    }

    //** ------------------------------------------------------------------ **//
    //                        EXTERNAL FUNCTIONS                              //
    //** ------------------------------------------------------------------ **//

    /// @notice function to cast votes on an hosted proposal
    /// @dev only raise contributors can call `vote` successfully
    /// @param raiseId_ id of the raise where the proposal is hosted
    /// @param proposalId_ id of the proposal to vote for
    /// @param support_ direction of vote, either `for` or `against`
    function vote(bytes32 raiseId_, uint256 proposalId_, bool support_)
        external
        canVote(raiseId_, msg.sender, proposalId_)
    {
        if (s_delegatee[msg.sender][raiseId_][proposalId_]) {

            if (support_) {

                s_votesForProposal[raiseId_][proposalId_] += (s_delegatedVotes[msg.sender][raiseId_][proposalId_] + 1); // votes delegated to voter plus his vote

            } else {

                votesAgainstProposal[raiseId_][proposalId_] += (s_delegatedVotes[msg.sender][raiseId_][proposalId_] + 1);
            }

        } else {

            if (support_) {

                s_votesForProposal[raiseId_][proposalId_] += 1;

            } else {

                votesAgainstProposal[raiseId_][proposalId_] += 1;
            }

        }

        s_hasVotedOnProposal[raiseId_][proposalId_][msg.sender] = true;

        emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(msg.sender, raiseId_, proposalId_, support_);
    }

    /**
    /// @notice Set voting start time for a proposal, only prop contract can call
    /// @dev sets the start time for voting on a specific proposal within a project.
    /// @dev only the proposal contract should be able to set voting start times
    /// @param raiseId_ unique id of a project.
    /// @param proposalId_ unique id of a proposal within the project.
    /// @param startTime_ voting start time.
    /// @dev emits VotingStartTimeSet to mark success.
    **/
    function setVotingStartTime(bytes32 raiseId_, uint256 proposalId_, uint256 startTime_) external {

        raiseBoxProposal.isValidProposal(raiseId_, proposalId_);
        
        if (msg.sender != address(raiseBoxProposal)) {
            revert("Only proposal contract can set voting start time.");
        }
        s_votingStartTime[raiseId_][proposalId_] = startTime_;

        emit VotingStartTimeSet(raiseId_, proposalId_, startTime_);
    }

    function delegateVote(bytes32 raiseId_, uint256 proposalId_, address from_, address to_)
        external
        canDelegate(raiseId_, proposalId_, from_, to_)
    {
        
        // record delegation
        s_delegatedVoteTo[from_][raiseId_][proposalId_] = to_;
        // add voting right to 'to' address

        s_delegatedVotes[to_][raiseId_][proposalId_] += 1;
        s_hasDelegatedForProposal[from_][raiseId_][proposalId_] = true;
        s_delegatee[to_][raiseId_][proposalId_] = true;

        emit VoteDelegated(from_, to_);
    }

    //** ------------------------------------------------------------------ **//
    //                        STATE VARIABLES                                 //
    //** ------------------------------------------------------------------ **//

    mapping(bytes32 => mapping(uint256 => mapping(address => bool))) public s_hasVotedOnProposal;

    mapping(address => mapping(bytes32 => mapping(uint256 => address))) public s_delegatedVoteTo;

    mapping(bytes32 => mapping(uint256 => uint256)) public s_votesForProposal;

    mapping(bytes32 => mapping(uint256 => uint256)) public votesAgainstProposal; 

    mapping(bytes32 => mapping(uint256 => bool)) public s_votingEnded; 

    mapping(bytes32 => mapping(uint256 => uint256)) public s_votingStartTime;

    uint256 public constant VOTING_DURATION = 20 minutes ; // 7 days in production // 2 minutes for testing

    mapping(address => mapping(bytes32 => mapping(uint256 => uint256))) public s_delegatedVotes;

    mapping(address => bool) public delegated;

    // delegated votes tracker scoped to proposal:
    mapping(address => mapping(bytes32 => mapping(uint256 => bool))) public s_hasDelegatedForProposal;

    mapping(address => mapping(bytes32 => mapping(uint256 => bool))) public s_delegatee;

    mapping(bytes32 => uint256) public s_raiseFailedProposals;




    function getProposalVotes(bytes32 raiseId_, uint256 proposalId_) external view returns (uint256, uint256, uint256) {
        return _getProposalVotes(raiseId_, proposalId_);
    }

    /**
     * @notice Get votes for, against, and total votes for a proposal
     *     @param raiseId unique id of a project.
     *     @param proposalId unique id of a proposal within the project.
     *     @return forVotes total in favor.
     *     @return againstVotes total against.
     *     @return totalVotes aggregate (for + against).
     *
     */
    function _getProposalVotes(bytes32 raiseId, uint256 proposalId) internal view returns (uint256, uint256, uint256) {
        // checks: Will revert if proposal is an invalid one
        raiseBoxProposal.isValidProposal(raiseId, proposalId);

        uint256 forVotes = s_votesForProposal[raiseId][proposalId];
        uint256 againstVotes = votesAgainstProposal[raiseId][proposalId];
        uint256 totalVotes = (forVotes + againstVotes);

        return (forVotes, againstVotes, totalVotes);
    }

    function getAbsenteeVoters(bytes32 raiseId, uint256 proposalId) external view returns (uint256) {
        uint256 totalContributors = raiseBoxContribution.getTotalContributors(raiseId);
        (,, uint256 totalVotes) = _getProposalVotes(raiseId, proposalId);

        return (totalContributors - totalVotes);
    }

    function getVotingStartTime(bytes32 raiseId, uint256 proposalId) external view returns (uint256 voteStartTime) {
        return _voteStartTime(raiseId, proposalId);
    }

    function _voteStartTime(bytes32 raiseId, uint256 proposalId) internal view returns(uint256 voteStartTime) {
        raiseBoxProposal.isValidProposal(raiseId, proposalId);
        return s_votingStartTime[raiseId][proposalId];
    }

    function hasVotedForProposal(address contributor, bytes32 raiseId, uint256 proposalId)
        external
        view
        returns (bool)
    {
        return s_hasVotedOnProposal[raiseId][proposalId][contributor];
    }

    /// @notice special ownerOnly function that triggers vote end incase no voting attempt is made after voting duration elapsed
    /// @notice this has to happen to trigger vote tallying and eventual funds drip
    /// @notice any attempt to end just after voting duration exceeds will fail
    /// @dev ends voting if voting hasn't already been ended by another call
    /// @dev can only end if voting duration has been exceeded by atleast 12 hours
    function triggerVoteTally(bytes32 raiseId_, uint256 proposalId_) external
    /**onlyRaiseCreator(raiseId_)*/ {

        uint256 _start = s_votingStartTime[raiseId_][proposalId_];

        if (s_votingEnded[raiseId_][proposalId_]) revert RaiseBoxErrorsLib.RaiseBoxVoting_VotingAlreadyEnded(raiseId_, proposalId_);

        // if voting duration elapsed, mark ended and emit events:
        if (block.timestamp >= (_start + VOTING_DURATION)) {
            _tallyVotes(raiseId_, proposalId_);
            // _endVoting(raiseId_, proposalId_);
            emit RaiseBoxVoting_VoteTallyTriggered(
                msg.sender, 
                proposalId_, 
                block.timestamp
                );
        } else {
            revert RaiseBoxVoting_VotingNotEnded();
        }

    }

    function _tallyVotes(bytes32 raiseId_, uint256 proposalId_) internal returns (uint256, uint256) {
        (uint256 forVotes_, uint256 againstVotes_, uint256 totalVotes) = _getProposalVotes(raiseId_, proposalId_);

        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId_);


        // if for is greater than against, proposal passed and % of funds will be dripped
        if (forVotes_ > againstVotes_) {

            raiseBoxProposal.updateProposalInfo(raiseId_, proposalId_);

            raiseBoxCore.updateRaiseInfo(
            raiseInfo.raiseCreationInfo.projectInfo,
            0,
            0,
            raiseInfo.raiseCreationInfo.doesRaiseExist,
            raiseId_,
            raiseInfo.raiseCreationInfo.raiseOwner,
            forVotes_,
            againstVotes_,
            proposalId_
            );

            emit RaiseBoxEventsLib.RaiseBoxVoting_tallyVotes_ProposalPassed(
                proposalId_,
                forVotes_,
                againstVotes_,
                totalVotes,
                block.timestamp
            );

            // delegate call to dripHandler since proposal has passed
            raiseBoxDripHandler.dripFundsForProposal(raiseId_, proposalId_);
        } else {

            raiseBoxProposal.updateProposalInfo(raiseId_, proposalId_);

            raiseBoxCore.updateRaiseInfo(
            raiseInfo.raiseCreationInfo.projectInfo,
            0,
            0,
            raiseInfo.raiseCreationInfo.doesRaiseExist,
            raiseId_,
            raiseInfo.raiseCreationInfo.raiseOwner,
            forVotes_,
            againstVotes_,
            proposalId_
            );

            emit RaiseBoxEventsLib.RaiseBoxVoting_tallyVotes_ProposalFailed(
                proposalId_,
                forVotes_,
                againstVotes_,
                totalVotes,
                block.timestamp
            );

            s_raiseFailedProposals[raiseId_]++;
            // revert RaiseBoxVoting_ProposalFailed();
        }

        emit VotesTallied(raiseId_, proposalId_, forVotes_, againstVotes_, totalVotes);

        return (forVotes_, againstVotes_);

    }

    function getFailedProposalsCount(bytes32 raiseId) external view returns (uint256) {
        return s_raiseFailedProposals[raiseId];
    }

    /// @dev sets voting ended for a given proposalId
    function _endVoting(bytes32 raiseId_, uint256 proposalId_) internal {

        s_votingEnded[raiseId_][proposalId_] = true;

        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId_);

        (uint forVotes_, uint againstVotes_, ) = _getProposalVotes(raiseId_, proposalId_);

        raiseBoxCore.updateRaiseInfo(
        raiseInfo.raiseCreationInfo.projectInfo,
        raiseInfo.raiseCreationInfo.raiseCreatedAt,
        raiseInfo.raiseContributionInfo.amountRaisedByProject,
        raiseInfo.raiseCreationInfo.doesRaiseExist,
        raiseId_,
        raiseInfo.raiseCreationInfo.raiseOwner,
        forVotes_,
        againstVotes_,
        proposalId_
        );

        // raiseBoxProposal.updateProposalState(
        //     raiseId_, 
        //     proposalId_, 
        //     IRaiseBoxProposal.ProposalState.INACTIVE
        //     );

       emit RaiseBoxEventsLib.RaiseBoxVoting_endVoting_VotingEndedSucessfully(block.timestamp);
    }




    /// if forvotes/totalvotes * 100 >= 67 the quoromhas been achieved and proposal passes

    uint256 immutable QUORUM = 67; // 67%

    uint256 constant PARTICIPATION_QUORUM = 25; // 25% of contributors
    uint256 constant APPROVAL_THRESHOLD = 67;   // 67% approval

    function _isParticipationQuorumReached(
    uint256 totalVotes,
    uint256 totalContributors
    ) internal pure returns (bool) {
        if (totalContributors == 0) return false;

        return (100 * totalVotes) >= (PARTICIPATION_QUORUM * totalContributors);
    }


    function _isApprovalThresholdReached(
    uint256 forVotes,
    uint256 totalVotes
    ) internal pure returns (bool) {
        if (totalVotes == 0) return false;

        return (100 * forVotes) >= (APPROVAL_THRESHOLD * totalVotes);
    }

    function _isProposalApproved(
    uint256 forVotes,
    uint256 againstVotes,
    uint256 totalContributors
    ) internal pure returns (bool) {
    uint256 totalVotes = forVotes + againstVotes;

        return
        _isParticipationQuorumReached(totalVotes, totalContributors) &&
        _isApprovalThresholdReached(forVotes, totalVotes);
    }


    function _isQuorumReached(bytes32 raiseId_, uint256 proposalId_, uint256 forVotes_, uint256 againstVotes_) internal returns (bool) {

        // sanitize inputs
        raiseBoxProposal.isValidProposal(raiseId_, proposalId_);

        // 100f >= 67t
        if ((100 * forVotes_) >= (QUORUM * (forVotes_ + againstVotes_))) {
            return true;
            // quorum is reached
            // pass proposal
        } else { return false; }

    }

}
