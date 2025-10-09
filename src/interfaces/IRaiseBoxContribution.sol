// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBox Contribution contract
*/

interface IRaiseBoxContribution {
    function contribute(uint256 amount, bytes32 projectId) external payable;

    function getContributors(bytes32 projectId) external view returns (address[] memory);

    function getMaxContributionAllowedForProject(bytes32 projectId) external returns (uint256);

    function getTotalContributionsToProject(bytes32 projectId) external returns (uint256 contributions);

    function getContributionsToProject(address user, bytes32 projectId) external view returns (uint256[] memory);
}
