// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IRaiseBoxDripHandler {
    // events
    event FundsDripped(bytes32 indexed raiseId, uint256 indexed proposalId, uint8 percent, uint256 amount);
    event CoreSet(address coreAddress);
    event VotingSet(address votingAddress);
    event ProposalSet(address proposalAddress);

    // errors
    error Drip_InvalidProject();
    error Drip_AlreadyExecuted(bytes32 raiseId, uint256 proposalId);
    error Drip_VotingNotPassed(bytes32 raiseId, uint256 proposalId);
    error Drip_InsufficientBalance(uint256 dripBalance, uint256 required);
    error Drip_InsufficientBalanceECR20(uint256 dripBalance, uint256 required);
    error Drip_InvalidPercent();
    error DripHandler_NotVotingContract(address caller);
    error DripHandler_NotProposalContract();
    error RaiseBoxDripHandler_PreviousDripIs25();

    function drip(bytes32 raiseId, uint256 proposalId) external;
    function dripFundsForProposal(bytes32 raiseId, uint256 proposalId) external;
    // function getDripPercent(bytes32 raiseId, uint256 propCount, uint8 dripPercent) external returns (uint8);
}
