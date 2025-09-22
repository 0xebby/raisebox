// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
