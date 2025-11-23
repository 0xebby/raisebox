// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";

contract RaiseBoxContribution is ReentrancyGuard, IRaiseBoxContribution {

    IRaiseBoxCore public immutable raiseBoxCore; // the central contract that holds main storage of raisebox

    using Strings for uint256;
    using Address for address;

    // contributions/users related state variables:
    mapping(address => uint256) public contributorsToAmountContributed; // not project dependent

    mapping(address contributor => mapping(bytes32 projectId => uint256 amtContributed)) public
        amountContributedToProject;

    mapping(bytes32 => address[]) private contributors;

    mapping(bytes32 => mapping(address => bool)) private hasContributed;

    mapping(address => mapping(bytes32 => uint256[])) public contributionsToProjectArray; // array of contributions per user per project

    uint256 public constant MAX_CONTRIBUTION_PERCENTAGE = 20; // 2% OF AMOUNT TO RAISE

    // tracks total amount contributed to project

    mapping(bytes32 => uint256) public totalContributionsToProject;

    // contribution state enum
    enum ContributionState {
        CONTRIBUTION_LIVE,
        CONTRIBUTION_ENDED
    }

    constructor(address raiseBoxCoreAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
    }
    

    function contribute(uint256 amount, bytes32 projectId) external payable nonReentrant {
        // projectId should be filled automatically via UI for project clicked by user

        // get protocol address so funds can be sent there:
        address payable raiseBoxProtocol = raiseBoxCore.getProtocol();

        // get valid project from storage

        (
            , 
            address projectOwner
            , 
            , 
            uint256 amtToRaise
            , 
            , 
            bytes32 projectId
            , 
            , 
            , 
            ,

        ) = raiseBoxCore.getProjectInfo(projectId);

        uint256 totalContributions = totalContributionsToProject[projectId];

        uint256 maxContribution = calMaxContribution(projectId, amtToRaise);

        uint256 userPrevContribution = amountContributedToProject[msg.sender][projectId];

        // Checks

        if (projectId == 0) {
            revert RaiseBoxContribution_InvalidProject();
        }

        // address projectOwner = project.projectOwner;
        if (projectOwner == address(0)) {
            revert RaiseBoxContribution_InvalidProject();
        }

        if (amount == 0) {
            revert RaiseBoxContribution_ZeroAmount();
        }

        uint256 minContribution = raiseBoxCore.getMinimumContribution();
        if (amount < minContribution) {
            revert RaiseBoxContribution_ContributeMoreEth(minContribution);
        }

        if (msg.value != amount) {
            revert RaiseBoxContribution_ValueSentMismatch();
        }

        if ((userPrevContribution + amount) > maxContribution) {
            revert RaiseBoxContribution_contribute_AboveMaxAllowed(
                amtToRaise,
                string(
                    abi.encodePacked(
                        "Cannot over contribute: you can contribute only: ",
                        ((maxContribution - userPrevContribution) / 1e18).toString(),
                        " ether more to this project"
                    )
                )
            );
        }

        if (totalContributions == amtToRaise) {
            revert IRaiseBoxCore.RaiseBox_RaiseEnded(projectId);
        }

        // Effects
        userPrevContribution += amount;

        contributionsToProjectArray[msg.sender][projectId].push(amount);

        totalContributions += amount;

        amountContributedToProject[msg.sender][projectId] = userPrevContribution;
        totalContributionsToProject[projectId] = totalContributions;

        if (!hasContributed[projectId][msg.sender]) {
            contributors[projectId].push(msg.sender);
            hasContributed[projectId][msg.sender] = true;
        }

        // only update storage when raise has passed,
        // i.e. the amount to raise by project has been raised successfully
        // instead of updating storage everytime a contribution is made, wasteful
        if (totalContributions == amtToRaise) {
            raiseBoxCore.updateAmountRaisedInStorage(
                projectId,
               totalContributions
            );

            emit IRaiseBoxCore.RaiseBox_RaisePassed(amtToRaise, amtToRaise);
        }

        // Interactions
        
        (bool successfullyContributed,) = raiseBoxProtocol.call{value: amount}(""); // funds sent to protocol for safekeeping pending release to project
        if (!successfullyContributed) {
            revert RaiseBoxContribution_ContributionFailed();
        }

        emit Contributed(
            msg.sender,
            amount,
            projectId,
            totalContributions // this should show that the main storage has been updated with totalContributionsToProject[projectid]
        );
    }

    receive() external payable {}

    // INTERNAL FUNCTIONS

    /**
     * @dev calculates the maximum contribution allowed per user per project
     * @param projectId the unique identifier of the project
     * @param amountToRaise the total amount the project aims to raise
     * @return maxContributionPerUser the maximum contribution allowed
     */

    function calMaxContribution(bytes32 projectId, uint256 amountToRaise) internal returns (uint256 maxContributionPerUser) {
        maxContributionPerUser = ((MAX_CONTRIBUTION_PERCENTAGE * amountToRaise) / 100);
        return maxContributionPerUser;
    }

    // EXTERNAL/GETTER FUNCTIONS

    function getMaxContributionAllowedForProject(bytes32 projectId) external returns (uint256) {
        uint256 amountToRaise = raiseBoxCore.getAmountToRaise(projectId);
        if (amountToRaise == 0) {
            revert RaiseBoxContribution_getMaxContributionAllowedForProject_CannotBeZero();
        }
        return calMaxContribution(projectId, amountToRaise);
    }

    function getContributors(bytes32 projectId) external view returns (address[] memory) {
        return contributors[projectId];
    }

    function getContributionsToProject(address user, bytes32 projectId) external returns (uint256[] memory) {
        if (!raiseBoxCore.doesProjectExist(projectId)) {
            revert IRaiseBoxCore.RaiseBox_getProject_InvalidProjectId();
        }
        return contributionsToProjectArray[user][projectId];
    }

    function getContributorsCount(bytes32 projectId) external returns (uint256 contributorCount) {
        if (!raiseBoxCore.doesProjectExist(projectId)) {
            revert IRaiseBoxCore.RaiseBox_getProject_InvalidProjectId();
        }
        return contributors[projectId].length;
    }

    function getTotalContributionsToProject(bytes32 projectId) external returns (uint256 contributionsReceived) {
        if (!raiseBoxCore.doesProjectExist(projectId)) {
            revert IRaiseBoxCore.RaiseBox_getProject_InvalidProjectId();
        }
        return totalContributionsToProject[projectId];
    }
    // testing
}
