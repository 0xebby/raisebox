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

contract RaiseBoxContribution is ReentrancyGuard, IRaiseBoxContribution {
    IRaiseBoxCore public immutable raiseBoxCore; // the central contract that holds main storage of raisebox

    IRaiseBoxDripHandler public immutable raiseBoxDripHandler; // drip contract

    using Strings for uint256;
    using Address for address;

    // contributions/users related state variables:
    mapping(address => uint256) public contributorsToAmountContributed; // not project dependent

    mapping(address contributor => mapping(bytes32 raiseId => uint256 amtContributed)) public
        amountContributedToProject;

    mapping(bytes32 => address[]) private contributors;

    mapping(bytes32 => mapping(address => bool)) private hasContributed;

    mapping(address => mapping(bytes32 => uint256[])) public contributionsToProjectArray; // array of contributions per user per project

    uint256 public constant MAX_CONTRIBUTION_PERCENTAGE = 20; // 2% OF AMOUNT TO RAISE

    // tracks total amount contributed to project

    mapping(bytes32 => uint256) public totalContributionsToProject;

    mapping(bytes32 => uint256) public raisers;

    // contribution state enum
    enum ContributionState {
        CONTRIBUTION_LIVE,
        CONTRIBUTION_ENDED
    }

    constructor(address raiseBoxCoreAddress, address dripHandlerAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
        raiseBoxDripHandler = IRaiseBoxDripHandler(dripHandlerAddress);
    }

    function contribute(uint256 amount, bytes32 raiseId) external payable nonReentrant {
        // raiseId should be filled automatically via UI for project clicked by user

        // get valid project from storage

        (, address projectOwner,, uint256 amtToRaise,, bytes32 raiseId,,,,,) = raiseBoxCore.getRaiseInfo(raiseId);

        uint256 totalContributions = totalContributionsToProject[raiseId];

        uint256 maxContribution = calMaxContribution(raiseId, amtToRaise);

        uint256 userPrevContribution = amountContributedToProject[msg.sender][raiseId];

        // Checks

        if (msg.sender == projectOwner) revert RaiseBoxContribution_SelfContribution();

        if (raiseId == 0) {
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
            revert IRaiseBoxCore.RaiseBox_RaiseEnded(raiseId);
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
        if (totalContributions == amtToRaise) {
            raiseBoxCore.updateAmountRaisedInStorage(raiseId, totalContributions);

            emit IRaiseBoxCore.RaiseBox_RaisePassed(amtToRaise, amtToRaise);
        }

        // Interactions

        (bool successfullyContributed,) = address(raiseBoxDripHandler).call{value: amount}(""); // funds sent to protocol for safekeeping pending release to project
        if (!successfullyContributed) {
            revert RaiseBoxContribution_ContributionFailed();
        }

        emit Contributed(
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
            revert RaiseBoxContribution_getMaxContributionAllowedForProject_CannotBeZero();
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
            revert IRaiseBoxCore.RaiseBoxCore_getProject_InvalidProjectId();
        }
        return contributionsToProjectArray[user][raiseId];
    }

    function getContributorsCount(bytes32 raiseId) external returns (uint256 contributorCount) {
        if (!raiseBoxCore.doesRaiseExist(raiseId)) {
            revert IRaiseBoxCore.RaiseBoxCore_getProject_InvalidProjectId();
        }
        return contributors[raiseId].length;
    }

    function getTotalContributionsToProject(bytes32 raiseId) external returns (uint256 contributionsReceived) {
        if (!raiseBoxCore.doesRaiseExist(raiseId)) {
            revert IRaiseBoxCore.RaiseBoxCore_getProject_InvalidProjectId();
        }
        return totalContributionsToProject[raiseId];
    }

    function getHasContributed(bytes32 raiseId, address user) external view returns (bool) {
        return hasContributed[raiseId][user];
    }
    // testing
}
