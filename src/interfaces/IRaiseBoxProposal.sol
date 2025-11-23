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
        string milestone;
        uint256 proposalId;
    }

    function getProposalCount(bytes32 projectId) external view returns (uint256);
}


   
