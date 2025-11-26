// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBox Proposal contract
*/

interface IRaiseBoxProposal {

    // proposal related events:
    event NewProposalHosted(
        address indexed projectCreator,
        uint256 proposalId,
        uint8 dripPercent,
        string proposalAchievement,
        uint256 lastProposalTime,
        uint256 numberOfProposalsHosted
    );
    event ProposalPassed();

    error raiseBoxProposal_InvalidProjectOwner();
    error RaiseBoxProposal_hostProposal_ProjectDoesNotExist();
    error RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
    error RaiseBoxProposal_hostProposal_RaiseNotEnded();
    error RaiseBoxProposal_InvalidDrip();
    error RaiseBoxProposal_hostProposal_MaxYearlyProposalsReached();
    error RaiseBoxProposal_getProposalDetails_InvalidProposalId();

    struct MileStoneProposalDetails {
        // different milestones: mvp ready, testnet ready, distribution site ready,
        uint256 lastProposalTime;
        string description;
        string milestone;
        uint256 proposalId;
        uint8 dripPercent;
    }

    function getProposalCount(bytes32 projectId) external view returns (uint256);

    function getProposalDetails(bytes32 projectId, uint256 proposalId)
        external
        view
        returns (MileStoneProposalDetails memory proposalDetails_);

    function getHasHostedProposal(bytes32 projectId) external returns (bool);

    function getLastProposalTime(bytes32 projectId) external view returns (uint256);

    // protocol wide total proposals
    function getTotalProposals() external view returns (uint256);
}
