// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";


contract RaiseBoxContribution is ReentrancyGuard, IRaiseBoxContribution {
    IRaiseBoxCore public immutable raiseBoxCore;

    IRaiseBoxDripHandler public immutable raiseBoxDripHandler; // drip contract

    using Strings for uint256;
    using Address for address;

    // contributions/users related state variables:
    mapping(address => uint256) public contributorsToAmountContributed; // not project dependent

    mapping(address contributor => mapping(bytes32 raiseId => uint256 amtContributed)) public amountContributedToProject;

    mapping(bytes32 => address[]) private contributors;

    mapping(bytes32 => mapping(address => bool)) private hasContributed;

    mapping(address => mapping(bytes32 => uint256[])) public contributionsToProjectArray; // array of contributions per user per project

    uint256 public constant MAX_CONTRIBUTION_PERCENTAGE = 20; // 2% OF AMOUNT TO RAISE

    // tracks total amount contributed to project

    mapping(bytes32 => uint256) public totalContributionsToProject;

    mapping(bytes32 => uint256) public raisers;

    constructor(address raiseBoxCoreAddress, address dripHandlerAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
        raiseBoxDripHandler = IRaiseBoxDripHandler(dripHandlerAddress);
    }

    function contribute(uint256 amount, bytes32 raiseId) external payable nonReentrant {
        // raiseId should be filled automatically via UI for project clicked by user

        // get valid project from storage 
        IRaiseBoxCore._RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId);

        uint256 totalContributions = totalContributionsToProject[raiseId];

        uint256 maxContribution = calMaxContribution(raiseId, raiseInfo.projectInfo.raiseTarget);

        uint256 userPrevContribution = amountContributedToProject[msg.sender][raiseId];

        // Checks

        if (msg.sender == raiseInfo.projectInfo.projectOwner) revert RaiseBoxErrorsLib.RaiseBoxContribution_SelfContribution();

        if (raiseId == 0 || raiseId != raiseInfo.raiseId) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_InvalidRaiseId();
        }

        // address projectOwner = project.projectOwner;
        if (raiseInfo.projectInfo.projectOwner == address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_InvalidProject();
        }

        if (amount == 0) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_ZeroAmount();
        }

        uint256 minContribution = raiseBoxCore.getMinimumContribution();
        if (amount < minContribution) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_ContributeMoreEth(minContribution);
        }

        if (msg.value != amount) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_ValueSentMismatch();
        }

        if ((userPrevContribution + amount) > maxContribution) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_contribute_AboveMaxAllowed(
                raiseInfo.projectInfo.raiseTarget,
                string(
                    abi.encodePacked(
                        "Cannot over contribute: you can contribute only: ",
                        ((maxContribution - userPrevContribution) / 1e18).toString(),
                        " ether more to this project"
                    )
                )
            );
        }

        if (block.timestamp > raiseInfo.raiseDuration && totalContributions != raiseInfo.projectInfo.raiseTarget ) { 
            IRaiseBoxCore.RaiseState.FAILED;
            
            revert RaiseBoxErrorsLib.RaiseBox_RaiseFailed(raiseId);
            
        }

        if (raiseInfo.raiseState == IRaiseBoxCore.RaiseState.FAILED) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_RaiseFailed(raiseId);
        }

        if (raiseBoxCore.getRaiseState(raiseId) == IRaiseBoxCore.RaiseState.PROPOSAL) {
            revert RaiseBoxErrorsLib.RaiseBox_RaiseAlreadyPassed(raiseId, raiseInfo.projectInfo.raiseTarget, totalContributions);
        }

        // Effects
        userPrevContribution += amount;

        contributionsToProjectArray[msg.sender][raiseId].push(amount);

        totalContributions += amount;

        amountContributedToProject[msg.sender][raiseId] = userPrevContribution;
        totalContributionsToProject[raiseId] = totalContributions;
        raisers[raiseId]++;

        if (!hasContributed[raiseId][msg.sender]) {
            contributors[raiseId].push(msg.sender);
            hasContributed[raiseId][msg.sender] = true;
        }

        // only update storage when raise has passed,
        // i.e. the amount to raise by project has been raised successfully
        // instead of updating storage everytime a contribution is made, wasteful
        if (totalContributions == raiseInfo.projectInfo.raiseTarget) {
            raiseBoxCore.updateRaiseInfo(raiseInfo.projectInfo, raiseInfo.raiseDuration, raiseInfo.raiseCreationTime, totalContributionsToProject[raiseId], raiseInfo.projectRaiseCount, raiseInfo.proposalsHosted, raiseInfo.raiseExists, raiseId, IRaiseBoxCore.RaiseState.PROPOSAL);

            emit RaiseBoxEventsLib.RaiseBox_RaisePassed(raiseInfo.projectInfo.raiseTarget, raiseInfo.projectInfo.raiseTarget);
        }

        // Interactions

        (bool successfullyContributed,) = address(raiseBoxDripHandler).call{value: amount}(""); // funds sent to protocol for safekeeping pending release to project
        if (!successfullyContributed) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_ContributionFailed();
        }

        emit RaiseBoxEventsLib.Contributed(
            msg.sender,
            amount,
            raiseId,
            totalContributions // this should show that the main storage has been updated with totalContributionsToProject[raiseId]
        );
    }

    receive() external payable {}

    // INTERNAL FUNCTIONS

    /**
     * @dev calculates the maximum contribution allowed per user per project
     * @param raiseId the unique identifier of the project
     * @param amountToRaise the total amount the project aims to raise
     * @return maxContributionPerUser the maximum contribution allowed
     */
    function calMaxContribution(bytes32 raiseId, uint256 amountToRaise)
        internal
        returns (uint256 maxContributionPerUser)
    {
        maxContributionPerUser = ((MAX_CONTRIBUTION_PERCENTAGE * amountToRaise) / 100);
        return maxContributionPerUser;
    }

    // EXTERNAL/GETTER FUNCTIONS

    function getMaxContributionAllowedForProject(bytes32 raiseId) external returns (uint256) {
        uint256 amountToRaise = raiseBoxCore.getAmountToRaise(raiseId);
        if (amountToRaise == 0) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_getMaxContributionAllowedForProject_CannotBeZero();
        }
        return calMaxContribution(raiseId, amountToRaise);
    }

    function getContributors(bytes32 raiseId) external view returns (address[] memory) {
        return contributors[raiseId];
    }

    function getRaiseContributorsCount(bytes32 raiseId) external returns (uint256) {
        return raisers[raiseId];
    }

    function getContributionsToProject(address user, bytes32 raiseId) external returns (uint256[] memory) {
        if (!raiseBoxCore.doesRaiseExist(raiseId)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_getProject_InvalidProjectId();
        }
        return contributionsToProjectArray[user][raiseId];
    }

    function getContributorsCount(bytes32 raiseId) external returns (uint256 contributorCount) {
        if (!raiseBoxCore.doesRaiseExist(raiseId)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_getProject_InvalidProjectId();
        }
        return contributors[raiseId].length;
    }

    function getTotalContributionsToProject(bytes32 raiseId) external returns (uint256 contributionsReceived) {
        if (!raiseBoxCore.doesRaiseExist(raiseId)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_getProject_InvalidProjectId();
        }
        return totalContributionsToProject[raiseId];
    }

    function getHasContributed(bytes32 raiseId, address user) external view returns (bool) {
        return hasContributed[raiseId][user];
    }

}
