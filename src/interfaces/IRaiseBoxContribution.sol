// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/*
    Note: this is the interface for the RaiseBoxCreation Contribution contract
*/

interface IRaiseBoxContribution {

    function getContributors(bytes32 raiseId) external view returns (address[] memory);

    function getMaxContributionAllowedForARaise(bytes32 raiseId) external returns (uint256);

    function getTotalContributionsToRaise(bytes32 raiseId) external view returns (uint256 contributions);

    function getContributionHistory(address user, bytes32 raiseId) external view returns (uint256[] memory);

    function hasUserContributed(bytes32 raiseId, address user) external view returns (bool);

    function getTotalContributors(bytes32 raiseId) external view returns (uint256);

    function getUserRaiseContributions(bytes32 raiseId_, address user) external view returns(uint);
}
