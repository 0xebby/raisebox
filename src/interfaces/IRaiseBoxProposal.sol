// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBoxCreation Proposal contract
*/

interface IRaiseBoxProposal {
    // proposal related events:
    event NewProposalHosted(
        address indexed projectCreator, uint256 indexed proposalId, uint8 dripPercent, uint256 lastProposalTime
    );
    event ProposalPassed();

    error raiseBoxProposal_InvalidProjectOwner();
    error RaiseBoxProposal_hostProposal_ProjectDoesNotExist();
    error RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
    error RaiseBoxProposal_hostProposal_RaiseNotEnded();
    error RaiseBoxProposal_InvalidDripPercent();
    error RaiseBoxProposal_hostProposal_MaxYearlyProposalsReached();
    error RaiseBoxProposal_getProposalDetails_InvalidProposalId();
    error RaiseBoxProposal_ProposalsExceedsMax(uint256 max);

    struct MileStoneProposalDetails {
        // different milestones: mvp ready, testnet ready, distribution site ready,
        uint256 lastProposalTime;
        string description;
        string milestone;
        uint256 proposalId;
        uint8 dripPercent;
    }

    function getProposalCount(bytes32 raiseId) external view returns (uint256);

    function getProposalDetails(bytes32 raiseId, uint256 proposalId)
        external
        view
        returns (MileStoneProposalDetails memory proposalDetails_);

    function getHasHostedProposal(bytes32 raiseId) external returns (bool);

    function getLastProposalTime(bytes32 raiseId) external view returns (uint256);

    // protocol wide total proposals
    function getTotalProposals() external view returns (uint256);
}
