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
    }
    
    event ProposalPassed();
    error RaiseBoxProposal_hostProposal_ProjectDoesNotExist();
    error RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
    error RaiseBoxProposal_hostProposal_RaiseNotPassedYet();
    error RaiseBoxProposal_hostProposal_MaxYearlyProposalsReached();
    error RaiseBoxProposal_getProposalDetails_InvalidProposalId();
    error RaiseBoxProposal_ProposalsExceedsMax(uint256 max);

    struct MilestoneInfo {
        // different milestones: mvp ready, testnet ready, distribution site ready,
        string description;
        string milestone;
        uint8 dripPercent;
    }

    function getProposalState(bytes32 raiseId, uint256 proposalId) external view returns(ProposalState);
 
    function updateProposalState(bytes32 raiseId_, uint256 proposalId_, ProposalState proposalState_) external;

    function updateProposalInfo(
        bytes32 raiseId_, 
        uint256 proposalId_
    ) external;

    function getProposalCount(bytes32 raiseId) external view returns (uint256);

    function getProposalInfo(bytes32 raiseId_, uint256 proposalId_)
        external
        view
        returns (ProposalInfo memory proposalInfo_);

    function getLastProposalTime(bytes32 raiseId) external view returns (uint256);

    // returns total number of proposals that have been created on raisebox.
    function getTotalProposals() external view returns (uint256);

    // returns true if a proposal exist within a raise.
    function isValidProposal(bytes32 raiseId, uint256 proposalId) external view returns (bool);

    function get25DripsCount(bytes32 raiseId_ ) external returns (uint8);

    function getLastProposalDripPercent(bytes32 raiseId) external returns (uint8);

    function getDripPercent(bytes32 raiseId_, uint256 proposalId_) external returns (uint8);
}
