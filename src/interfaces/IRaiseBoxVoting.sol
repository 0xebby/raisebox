// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBoxCreation Voting contract
*/

interface IRaiseBoxVoting {
    error RaiseBoxVoting_NotContributor(bytes32 projectId, address user);
    error RaiseBoxVoting_CannotDelegateToSelf();
    error RaiseBoxVoting_VotingEnded(bytes32 projectId, uint256 proposalId);
    error RaiseBoxVoting_AlreadyVoted(uint256 proposalId, address user);
    error RaiseBoxVoting_InvalidProposal();
    error RaiseBoxVoting_VotingNotStarted(bytes32 projectId, uint256 proposalId);
    error RaiseBoxVoting_AlreadyDelegatedVote(address user);
    error RaiseBoxVoting_CannotDelegateTwice();
    error RaiseBoxVoting_CannotDelegateAfterVoting(uint256 proposalId, address voter);
    error RaiseBoxVoting_DelegationToZeroAddress(address zeroAddress);
    error RaiseBoxVoting_RaiseCreator(address raiseCreator);
    error RaiseBoxVoting_NotRaiseOwner(address raiseOwner);
    error RaiseBoxVoting_VotingNotEnded();
    error RaiseBoxVoting_ProposalFailed();

    event VoteDelegated(address indexed from, address indexed to);
    event Voted(address indexed voter, bytes32 indexed projectId, uint256 indexed proposalId, bool side);
    event VotesTallied(bytes32 indexed projectId, uint256 indexed proposalId, uint256 forVotes, uint256 againstVotes, uint256 totalProposalVotes);
    event VotingStartTimeSet(bytes32 indexed projectId, uint256 indexed proposalId, uint256 startTime);
    event RaiseBoxVoting_VoteTallyTriggered(address indexed raiseOwner, uint256 proposalId, uint256 triggerTime);
    event RaiseBoxVoting_VotingEndedSucessfully();

    function vote(bytes32 projectId, uint256 proposalId, bool side, address voter) external;

    function delegateVote(bytes32 projectId, uint256 proposalId, address from, address to) external;

    function tallyVotes(bytes32 projectId, uint256 proposalId)
        external
        returns (uint256 forVotes, uint256 againstVotes);

    function getProposalVotes(bytes32 projectId, uint256 proposalId)
        external
        returns (uint256 forVotes, uint256 againstVotes, uint256 totalVotes);

    function setVotingStartTime(bytes32 projectId, uint256 proposalId, uint256 startTime) external;

    function hasVotedForProposal(address contributor, bytes32 projectId, uint256 proposalId)
        external
        view
        returns (bool);

        // owner only special function
    function triggerVoteTally(bytes32 projectId, uint256 proposalId) external;
}
