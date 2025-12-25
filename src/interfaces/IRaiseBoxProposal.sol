// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBoxCreation Proposal contract
*/

interface IRaiseBoxProposal {
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

    struct MilestoneProposalInfo {
        // different milestones: mvp ready, testnet ready, distribution site ready,
        uint256 lastProposalTime;
        string description;
        string milestone;
        uint256 proposalId;
        uint8 dripPercent;
        bool proposalExist;
    }

    // function getProposalState(bytes32 raiseId, uint256 proposalId) external returns(ProposalState);

    // function getLastProposalState(bytes32 raiseId, uint256 proposalId) external returns(ProposalState);

    function getProposalCount(bytes32 raiseId) external view returns (uint256);

    function getProposalDetails(bytes32 raiseId, uint256 proposalId)
        external
        returns (MilestoneProposalInfo memory proposalDetails_);

    function getHasHostedProposal(bytes32 raiseId) external returns (bool);

    function getLastProposalTime(bytes32 raiseId) external view returns (uint256);

    // protocol wide total proposals
    function getTotalProposals() external view returns (uint256);
    function isValidProposal(bytes32 rasieId, uint256 proposalId) external returns(bool);
}
