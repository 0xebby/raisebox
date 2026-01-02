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

    /// @notice state variables
    mapping(address contributor => mapping(bytes32 raiseId => uint256 amtContributed)) public amountContributedToRaise;

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

        // sanitize `amount` input before getting raiseInfo 
        if (amount == 0) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_ZeroAmount();
        }

        if (msg.value != amount) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_ValueSentMismatch();
        }

        uint256 minContribution = raiseBoxCore.getMinimumContribution();
        if (amount < minContribution) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_ContributeMoreEth(minContribution);
        }

        /// @notice ascertain that raise exist busing the raiseId further down
        /// @dev getRaiseInfo has a doesRaiseExist check embedded in it call stack that reverts early if an invalid raiseId is passed
        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId);

        if (raiseInfo.raiseState != IRaiseBoxCore.RaiseState.CONTRIBUTION) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_contribute_RaiseNotInContributionState();
        }

        address raiseOwner = raiseInfo.raiseCreationInfo.raiseOwner;
        if (msg.sender == raiseOwner) revert RaiseBoxErrorsLib.RaiseBoxContribution_SelfContributionForbidden();

        uint256 raiseTarget = raiseInfo.raiseCreationInfo.projectInfo.raiseTarget;

        uint256 constRaiseDuration = raiseBoxCore.getRaiseDeadline(raiseId);

        uint256 totalContributions = totalContributionsToProject[raiseId];

        uint256 maxContribution = _calMaxContribution(raiseId);

        uint256 userPrevContribution = amountContributedToRaise[msg.sender][raiseId];

        if ((userPrevContribution + amount) > maxContribution) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_contribute_AboveMaxAllowed(
                maxContribution,
                string(
                    abi.encodePacked(
                        "Cannot over contribute: you can contribute only: ",
                        ((maxContribution - userPrevContribution) / 1e18).toString(),
                        " ether more to this project"
                    )
                )
            );
        }

        // Checks

        /// @dev raise is failed at this point as target is not reached within allowed raise duration
        if (block.timestamp > constRaiseDuration && totalContributions < raiseTarget) { 

            // end the raise and mark as failed
            // target wasn't met within the raiseDuration
            /// @dev moves raise state to failed and triggers refund mechanism
            raiseBoxCore.endRaise(raiseId);
            revert RaiseBoxErrorsLib.RaiseBoxContribution_RaiseEnded(raiseId);
        }

        if (totalContributions + amount > raiseTarget) { 
            revert RaiseBoxErrorsLib.RaiseBoxContribution_contribute_OverContributionIsForbidden(
                 string(
                abi.encodePacked(
                    ((raiseTarget - totalContributions) / 1e18).toString(), "eth more to raiseTarget"
                )
                )
            ); 
           
            }

        // Effects
        userPrevContribution += amount;

        contributionsToProjectArray[msg.sender][raiseId].push(amount);

        totalContributions += amount;

        amountContributedToRaise[msg.sender][raiseId] = userPrevContribution;
        totalContributionsToProject[raiseId] = totalContributions;
        

        if (!hasContributed[raiseId][msg.sender]) {
            raisers[raiseId]++;
            contributors[raiseId].push(msg.sender);
            hasContributed[raiseId][msg.sender] = true;
        }

        /// @dev only update storage when raise has passed,
        /// i.e. the amount to raise by project has been raised successfully
        /// instead of updating storage everytime a contribution is made, wasteful
        /// raise is successful and moved to proposal state as target has been met
        if (totalContributionsToProject[raiseId] >= raiseTarget) {
            raiseBoxCore.updateRaiseInfo(
                raiseInfo.raiseCreationInfo.projectInfo,
                raiseInfo.raiseCreationInfo.raiseCreatedAt,
                totalContributionsToProject[raiseId],
                raiseInfo.raiseCreationInfo.doesRaiseExist,
                raiseId,
                raiseOwner,
                0,
                0,
                0
                );

        emit RaiseBoxEventsLib.RaiseBox_RaisePassed(raiseTarget, totalContributionsToProject[raiseId]);
        }

        // Interactions

        // funds sent to protocol for safekeeping pending release to project
        (bool successfullyContributed,) = address(raiseBoxDripHandler).call{value: amount}(""); 

        if (!successfullyContributed) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_contribute_ContributionFailed();
        }

        emit RaiseBoxEventsLib.Contributed(
            msg.sender,
            amount,
            raiseId,
            totalContributionsToProject[raiseId] 
        );
    }

    receive() external payable { revert("eth not accepted"); } 
    // should not be able to receive eth directly except via contribute above

    // INTERNAL FUNCTIONS

    /**
     * @dev calculates the maximum contribution allowed per user per project
     * @param raiseId the unique identifier of the project
     * @return maxContributionPerUser the maximum contribution allowed
     */
    function _calMaxContribution(bytes32 raiseId)
        internal
        returns (uint256 maxContributionPerUser)
    {
        uint256 amountToRaise = raiseBoxCore.getAmountToRaise(raiseId);

        maxContributionPerUser = ((MAX_CONTRIBUTION_PERCENTAGE * amountToRaise) / 100);

        return maxContributionPerUser;
    }

    // EXTERNAL/GETTER FUNCTIONS

    function getMaxContributionAllowedForARaise(bytes32 raiseId_) external returns (uint256) {
            raiseBoxCore.doesRaiseExist(raiseId_);
            return _calMaxContribution(raiseId_);
    }

    function getContributors(bytes32 raiseId_) external view returns (address[] memory) {
        return contributors[raiseId_];
    }

    function getTotalContributors(bytes32 raiseId_) external view returns (uint256) {
        raiseBoxCore.doesRaiseExist(raiseId_);
        return raisers[raiseId_];
    }

    function getContributionHistory(address user, bytes32 raiseId_) external view returns (uint256[] memory) {

            raiseBoxCore.doesRaiseExist(raiseId_);
            require(user != address(0), "zero address cannot contribute");
            return contributionsToProjectArray[user][raiseId_];
    }

    function getUserRaiseContributions(bytes32 raiseId_, address user) external view returns(uint256) {
        raiseBoxCore.doesRaiseExist(raiseId_);
        require(user != address(0), "zero address cannot contribute");
        return amountContributedToRaise[user][raiseId_];
        
    }

    /// @notice this returns the total amount that a raise has accrued at an point in time
    /// @param raiseId id of the raise 
    /// @return uint256 all contributions made to raise so far
    function getTotalContributionsToRaise(bytes32 raiseId) external view returns (uint256) {

            raiseBoxCore.doesRaiseExist(raiseId);
            return totalContributionsToProject[raiseId];
    }

    function hasUserContributed(bytes32 raiseId, address user) external view returns (bool) {
        raiseBoxCore.doesRaiseExist(raiseId);
        return hasContributed[raiseId][user];
    }

}

