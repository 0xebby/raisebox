// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/*
    Note: this is the interface for the RaiseBoxCreation Contribution contract
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
    error RaiseBoxContribution_SelfContribution();
    error RaiseBoxContribution_NotAContributor(bytes32 raiseId);

    // contribution related events:
    event Contributed(
        address indexed user, uint256 indexed amountContributed, bytes32 indexed raiseId, uint256 amountRaised
    );

    function contribute(uint256 amount, bytes32 raiseId) external payable;

    function getContributors(bytes32 raiseId) external view returns (address[] memory);

    function getMaxContributionAllowedForProject(bytes32 raiseId) external returns (uint256);

    function getTotalContributionsToProject(bytes32 raiseId) external returns (uint256 contributions);

    function getContributionsToProject(address user, bytes32 raiseId) external returns (uint256[] memory);

    function getContributorsCount(bytes32 raiseId) external returns (uint256 contributorCount);

    function getHasContributed(bytes32 raiseId, address user) external view returns (bool);

    function getRaiseContributorsCount(bytes32 raiseId) external returns (uint256);
}
