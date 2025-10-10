// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBox Proposal contract
*/

interface IRaiseBoxProposal {
    struct MileStoneProposalDetails {
        // different milestones: mvp ready, testnet ready, distribution site ready,
        uint256 lastProposalTime;
        string description;
        string achievement;
        uint256 proposalId;
        uint256 proposalCount;
    }

    // function viewProposalInfo(bytes32 projectId, uint256 proposalId) external;

    // function getProposals(
    //     bytes32 projectId
    // ) external returns (MileStoneProposalDetails memory mileStoneDetails);

    // function updateProposalDetails(bytes32 projectId, uint256 proposalId) external;
}

/*

event NewProposalHosted(
        address indexed projectOwner,
        uint256 proposalId,
        string proposalDescription,
        string proposalAchievement,
        uint256 timestamp,
        uint256 numberOfProposalsHosted
    );
    event ProposalPassed();

    error raiseBoxProposal_InvalidProjectOwner();
    error RaiseBoxProposal_hostProposal_ProjectDoesNotExist();
    error RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
    error RaiseBox_hostProposal_RaiseNotEnded();

    */
   
