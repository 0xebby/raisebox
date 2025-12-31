// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/*
    Note: this is the interface for the RaiseBoxCreation Contribution contract
*/

interface IRaiseBoxContribution {

    function contribute(uint256 amount, bytes32 raiseId) external payable;

    function getContributors(bytes32 raiseId) external view returns (address[] memory);

    function getMaxContributionAllowedForProject(bytes32 raiseId) external returns (uint256);

    function getTotalContributionsToProject(bytes32 raiseId) external view returns (uint256 contributions);

    function getContributionsToProject(address user, bytes32 raiseId) external view returns (uint256[] memory);

    function getContributorsCount(bytes32 raiseId) external view returns (uint256 contributorCount);

    function getHasContributed(bytes32 raiseId, address user) external view returns (bool);

    function getRaiseContributorsCount(bytes32 raiseId) external view returns (uint256);
}
