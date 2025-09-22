// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRaiseBoxContribution {
    function contribute(uint256 amount, bytes32 projectid_) external payable;
    function getContributions(address contributor, bytes32 projectId) external view returns (uint256);
    function getContributors(bytes32 projectId) external view returns (address[] memory);
    function getRemainingContributionInEth(bytes32 projectId) external returns (uint256 remainingWei);

    // function getAllowedContributionAmount(uint256 projectId) external returns (uint256);
}
