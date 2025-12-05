// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


interface IRaiseBoxDripHandler {
    function drip(bytes32 projectId, uint256 proposalId) external;
    function dripFundsForProposal(bytes32 projectId, uint256 proposalId) external;
}