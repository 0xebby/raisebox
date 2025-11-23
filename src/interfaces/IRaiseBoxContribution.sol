// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBox Contribution contract
*/

interface IRaiseBoxContribution {

    // contribution related errors:
    error RaiseBoxContribution_ValueSentMismatch();
    error RaiseBoxContribution_ContributeMoreEth(uint256);
    error RaiseBoxContribution_ZeroAmount();
    error RaiseBoxContribution_ContributionFailed();
    error RaiseBoxContribution_InvalidProject();
    error RaiseBoxContribution_RaiseBoxProtocolUnset();
    error RaiseContribution_ContributionEnded(uint256);
    error RaiseBoxContribution_contribute_AboveMaxAllowed(uint256, string);
    error RaiseBoxContribution_getMaxContributionAllowedForProject_CannotBeZero();

    // contribution related events:
    event Contributed(address indexed user, uint256 indexed amount, bytes32 indexed projectId, uint256 amountRaised);

    
    function contribute(uint256 amount, bytes32 projectId) external payable;

    function getContributors(bytes32 projectId) external view returns (address[] memory);

    function getMaxContributionAllowedForProject(bytes32 projectId) external returns (uint256);

    function getTotalContributionsToProject(bytes32 projectId) external returns (uint256 contributions);

    function getContributionsToProject(address user, bytes32 projectId) external returns (uint256[] memory);

    function getContributorsCount(bytes32 projectId) external returns (uint256 contributorCount);
}
