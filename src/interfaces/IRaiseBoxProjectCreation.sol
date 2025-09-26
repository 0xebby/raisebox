// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRaiseBoxProjectCreation {
    function getProjectCreator(bytes32 projectId) external returns (address);
    function viewProjectInfo(bytes32 projectId) external;
}
