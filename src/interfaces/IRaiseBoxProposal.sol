// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBoxCreation Proposal contract
*/

interface IRaiseBoxProposal {

    enum ProposalState{
        INACTIVE,
        ACTIVE,
        PASSED,
        FAILED
    } //[0,1]

    struct ProposalInfo {
        MilestoneInfo milestoneInfo;
        uint256 proposalId;
        uint256 lastProposalTime;
        ProposalState proposalState;
        bool doesProposalExist;
        uint256 conFailedProposals;
        uint256 nonConFailedProposals;
    }

    // proposal related events:
    event NewProposalHosted(
        uint256 indexed proposalId, 
        uint8 dripPercent, 
        uint256 lastProposalTime
    );
    
    event ProposalPassed();

    error raiseBoxProposal_InvalidRaiseOwner();
    error RaiseBoxProposal_hostProposal_ProjectDoesNotExist();
    error RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
    error RaiseBoxProposal_hostProposal_RaiseNotPassedYet();
    error RaiseBoxProposal_InvalidDripPercent();
    error RaiseBoxProposal_hostProposal_MaxYearlyProposalsReached();
    error RaiseBoxProposal_getProposalDetails_InvalidProposalId();
    error RaiseBoxProposal_ProposalsExceedsMax(uint256 max);

    struct MilestoneInfo {
        // different milestones: mvp ready, testnet ready, distribution site ready,
        // uint256 lastProposalTime;
        string description;
        string milestone;
        // uint256 proposalId;
        uint8 dripPercent;
        // bool proposalExist;
    }

 function getProposalState(bytes32 raiseId, uint256 proposalId) external returns(ProposalState) ;
   function updateProposalState(bytes32 raiseId, uint256 proposalId) external;
      // function getLastProposalState(bytes32 raiseId, uint256 proposalId) external returns(ProposalState);

    function getProposalCount(bytes32 raiseId) external returns (uint256);

    function getProposalInfo(bytes32 raiseId_, uint256 proposalId_)
        external
        returns (ProposalInfo memory proposalInfo_);

    function getHasHostedProposal(bytes32 raiseId) external returns (bool);

    function getLastProposalTime(bytes32 raiseId) external view returns (uint256);

    // returns total number of proposals thathave been created on raisebox.
    function getTotalProposals() external view returns (uint256);

    // returns true if a proposal exist within a raise.
    function isValidProposal(bytes32 rasieId, uint256 proposalId) external returns(bool);
}
