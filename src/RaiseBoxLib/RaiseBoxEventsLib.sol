// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title RaiseBoxEventsLib
/// @author 0xebby
/// @custom:contact tech.codemojo@gmail.com
/// @notice Library exposing events.
import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxProposal} from "src/interfaces/IRaiseBoxProposal.sol";

library RaiseBoxEventsLib {

    /// @notice emitted when a new raise is successfully created
    /// @param projectName name of the project of raise created
    /// @param projectOwner raise creator/ project owner
    /// @param raiseTarget amount intended to raise by project
    /// @param raiseId id of the raie created
    /// @param timeCreated timestamp at which raise is created
    event RaiseCreation_RaiseCreated(
        string projectName,
        address indexed projectOwner,
        string valueProp,
        uint256 indexed raiseTarget,
        bytes32 indexed raiseId,
        uint256 timeCreated
    );

    /// @notice emitted when raise creation details are update in storage
    /// @param raiseId id of the raise updated in storage
    event RaiseCreationInfoUpdated(
        bytes32 indexed raiseId
        );

    /// @notice emitted when raise creation details are update in storage
    /// @param raiseId id of the raise updated in storage
    event RaiseContributionInfoUpdated(
        bytes32 indexed raiseId,
        uint256 indexed amount
        );

    event RaiseBoxCore_updateState_RaiseStateUpdated(
        IRaiseBoxCore.RaiseState indexed oldRaiseState,
        IRaiseBoxCore.RaiseState indexed newRaiseState
    );

    /// @notice emitted when anew proposal is created
    /// @param proposalId id of the proposal hosted
    /// @param dripPercent percent of the raise funds expected to be dripped for this proposal
    /// @param lastProposalTime timestamp of the last proposal hosted for a raise
    event NewProposalHosted(
        uint256 indexed proposalId, 
        uint8 dripPercent, 
        uint256 lastProposalTime
    );

    /// @notice events emitted during voting on a raise proposal

    /// @notice emitted when vote is delegated
    /// @param from the address delegating its vote
    /// @param to the address whose vote is delagated
    event VoteDelegated(
        address indexed from, 
        address indexed to
        );

    /// @notice emitted when vote on a proposal has been casted successfully
    /// @param voter address of that casted the vote
    /// @param raiseId id of the raise hosting the proposal
    /// @param proposalId id of the proposal being voted on
    /// @param support side picked by voter, for/against
    event Voted(
        address indexed voter, 
        bytes32 indexed raiseId, 
        uint256 indexed proposalId, 
        bool support
        );

    /// @notice emitted when votes are tallied
    /// @param raiseId id of the raise hosting the proposal
    /// @param proposalId id of the proposal from which the votes are tallied
    /// @param forVotes number of votes casted in favor of proposal
    /// @param againstVotes number of votes casted against proposal
    /// @param totalProposalVotes total Number of votes casted for proposal (for + against)
    event VotesTallied(
        bytes32 indexed raiseId,
        uint256 indexed proposalId,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 totalProposalVotes
    );
    
    /// @notice emitted when start time for voting is set
    /// @param raiseId id of the raise hosting the proposal
    /// @param proposalId id of the proposal
    /// @param startTime time set for voting to start
    event VotingStartTimeSet(
        bytes32 indexed raiseId, 
        uint256 indexed proposalId, 
        uint256 startTime
        );

    /// @notice emitted when vote tally is triggered
    /// @dev TriggerVoteTally is a special method that can be called by only the projectOwner to tally votes
    /// @param raiseOwner caller of the tally trigger method
    /// @param triggerTime timestamp when vote tally is triggered
    event RaiseBoxVoting_VoteTallyTriggered(
        address indexed raiseOwner, 
        uint256 proposalId, 
        uint256 triggerTime
        );

    event RaiseBoxCore_FounderVerifiedAndAddedToWhiteList(
        address indexed founder
    );

    event RaiseBox_RaisePassed(
        uint256 raiseTarget, 
        uint256 amountRaised
        );

    event RaiseBox_RaiseFailed(
        bytes32 indexed raiseId
    );

    /// @notice emitted when raise ends
    event RaiseBoxCore_endRaise_RaiseEnded(
        bytes32 indexed raiseId,
        uint256 timeEnded
    );

    event RaiseBoxCore_RaiseCreationContractSet(
        address contractAddress
        );

    event ContributionContractSet(
        address indexed contractAddress
        );

    event ProposalContractSet(
        address indexed contractAddress
        );

    event VotingContractSet(
        address indexed contractAddress
        );

    event RaiseProposalInfoUpdated();

    event RaiseBoxCore_AcceptedTokenSet(
        address indexed acceptedToken
        );

    event DripperContractSet(
        address contractAddress
        );
    
    event RaiseVotingInfoUpdated();

    // contribution related events:
    event Contributed(
        address indexed user, 
        uint256 indexed userContribution, 
        bytes32 indexed raiseId, 
        uint256 amountRaisedSoFar,
        bool isERC20
    );

    event BlockTimeAdvancedBy(
        uint256 duration
    );

    event ProposalStateUpdated(IRaiseBoxProposal.ProposalState newState); // tempp

    // emitted when proposalInfo is update
    event RaiseBoxProposal_updateProposalInfo_ProposalInfoUpdated();

    event DebugProposalState(
        bytes32 raiseId,
        uint256 proposalId,
        IRaiseBoxProposal.ProposalState proposalState
    );

    event RaiseBox_ExceededMaxConFailedProposals(uint maxConFailedProposals);

    event RaiseBox_ExceededMaxFailedProposals(uint maxFailedProposals);

    /// @notice emitted when contributor casts votes on a proposal
    event RaiseBoxVoting_vote_Voted(
        address indexed voter, 
        bytes32 indexed raiseId, 
        uint256 indexed proposalId, 
        bool support
        );

    event RaiseBoxVoting_tallyVotes_ProposalPassed(
        uint256 proposalId,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 totalVotesCasted,
        uint256 voteTallyTimestamp
    );

    event RaiseBoxVoting_tallyVotes_ProposalFailed(
        uint256 proposalId,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 totalVotesCasted,
        uint256 voteTallyTimestamp
    );

    event RaiseBoxVoting_endVoting_VotingEndedSucessfully(
        uint voteEndTimestamp
    );

    event RaiseBoxProposal_verifyDripPercent_lastDripPercent(uint256 dripPercent);
}