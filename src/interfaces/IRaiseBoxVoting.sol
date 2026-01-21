// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBox Voting contract
*/

interface IRaiseBoxVoting {
    //** ---------------------------------------------------- **//
    //                              EVENTS                      //
    //** ---------------------------------------------------- **//
    event VoteDelegated(
        address indexed from, 
        address indexed to
        );

  

    event VotesTallied(
        bytes32 indexed raiseId,
        uint256 indexed proposalId,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 totalProposalVotes
    );
    event VotingStartTimeSet(
        bytes32 indexed raiseId, 
        uint256 indexed proposalId, 
        uint256 startTime
        );

    event RaiseBoxVoting_VoteTallyTriggered(
        address indexed raiseOwner, 
        uint256 proposalId, 
        uint256 triggerTime
        );
    

    error RaiseBoxVoting_AlreadyVoted(
        uint256 proposalId, 
        address user
        );

    error RaiseBoxVoting_ProposalNotLive();

    error RaiseBoxVoting_VotingNotStarted(
        bytes32 raiseId, 
        uint256 proposalId
        );

    
    error RaiseBoxVoting_CannotDelegateAfterVoting(uint256 proposalId, address voter);
    error RaiseBoxVoting_DelegationToZeroAddress(address zeroAddress);
    error RaiseBoxVoting_RaiseCreator(address raiseCreator);
    error RaiseBoxVoting_NotRaiseOwner(address raiseOwner);
    error RaiseBoxVoting_VotingNotEnded();
    error RaiseBoxVoting_ProposalFailed();
    error RaiseBoxVoting_LoopDelegationForbidden();

    function vote(bytes32 raiseId, uint256 proposalId, bool support) external;

    function delegateVote(bytes32 raiseId, uint256 proposalId, address from, address to) external;

    function getProposalVotes(bytes32 raiseId, uint256 proposalId)
        external
        view
        returns (uint256 forVotes, uint256 againstVotes, uint256 totalVotes);

    function setVotingStartTime(bytes32 raiseId, uint256 proposalId, uint256 startTime) external;

    function hasVotedForProposal(
        address contributor, 
        bytes32 raiseId, 
        uint256 proposalId
        ) external view returns (bool);

    // owner only special function
    function triggerVoteTally(
        bytes32 raiseId, 
        uint256 proposalId
        ) external;

    function getAbsenteeVoters(
        bytes32 raiseId, 
        uint256 proposalId
        ) external view returns (uint256);

        function getVotingStartTime(
            bytes32 raiseId,
            uint256 proposalId
        ) external view returns (uint256);

    
}
