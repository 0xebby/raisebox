// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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
    using SafeERC20 for IERC20;

    /// @notice state variables
    mapping(address contributor => mapping(bytes32 raiseId => uint256 amtContributed)) public amountContributedToRaise;
    
    // Track ETH and ERC20 contributions separately
    mapping(bytes32 raiseId => uint256) public ethContributionsToProject;
    mapping(bytes32 raiseId => uint256) public erc20ContributionsToProject;

    mapping(bytes32 => address[]) private contributors;

    mapping(bytes32 => mapping(address => bool)) private hasContributed;

    mapping(address => mapping(bytes32 => uint256[])) public contributionsToProjectArray; // array of contributions per user per project

    uint256 public constant MAX_CONTRIBUTION_PERCENTAGE = 200; 
    // 20.0% OF AMOUNT TO RAISE, tentative for testing, should 20 - 2.0% in production

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

        uint256 minContribution = raiseBoxCore.getMinimumContribution();
        if (amount < minContribution) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_ContributeMoreEth(minContribution);
        }

        /// @notice ascertain that raise exist busing the raiseId further down
        /// @dev getRaiseInfo has a requireRaiseExist check embedded in it call stack that reverts early if an invalid raiseId is passed
        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId);

        
        if (raiseInfo.raiseState == IRaiseBoxCore.RaiseState.ENDED) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_RaiseEnded(raiseId);
        }

        if (raiseInfo.raiseState == IRaiseBoxCore.RaiseState.FAILED) {
            revert RaiseBoxErrorsLib.
            RaiseBoxContribution_contribute_RaiseAlreadyFailed(raiseId);
        }

        if (raiseInfo.raiseState != IRaiseBoxCore.RaiseState.CONTRIBUTION) {
            revert RaiseBoxErrorsLib.RaiseBoxContribution_contribute_RaiseNotInContributionState();
        }

        if (msg.sender == raiseInfo.raiseCreationInfo.raiseOwner) revert RaiseBoxErrorsLib.RaiseBoxContribution_SelfContributionForbidden();

        // Validate contribution based on what was sent (ETH or ERC20)
        bool isETH = _validateContribution(amount);

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
                        " more ether to this project"
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
            return;
        }

        if (totalContributions + amount > raiseTarget) { 
            revert RaiseBoxErrorsLib.RaiseBoxContribution_contribute_OverContributionIsForbidden(
                 string(
                abi.encodePacked(
                    ((raiseTarget - totalContributions) / 1e18).toString(), " more ether to raiseTarget"
                    )
                )
            ); 
    
            }

        // Effects
        userPrevContribution += amount;
        contributionsToProjectArray[msg.sender][raiseId].push(amount);
        
        // Update total contributions consistently
        totalContributions += amount;
        amountContributedToRaise[msg.sender][raiseId] = userPrevContribution;
        totalContributionsToProject[raiseId] = totalContributions;

        if (isETH) {
            ethContributionsToProject[raiseId] += amount;
        } else {
            erc20ContributionsToProject[raiseId] += amount;
        }
        

        if (!hasContributed[raiseId][msg.sender]) {
            raisers[raiseId]++;
            contributors[raiseId].push(msg.sender);
            hasContributed[raiseId][msg.sender] = true;
        }

        /// @dev only update storage when raise has passed,
        /// i.e. amount to raise by project has been raised successfully
        /// instead of updating storage everytime a contribution is made, wasteful
        /// raise is successful and moved to proposal state as target has been met
        if (totalContributionsToProject[raiseId] >= raiseTarget) {
            raiseBoxCore.updateRaiseInfo(
                raiseInfo.raiseCreationInfo.projectInfo,
                raiseInfo.raiseCreationInfo.raiseCreatedAt,
                totalContributionsToProject[raiseId],
                raiseInfo.raiseCreationInfo.requireRaiseExist,
                raiseId,
                raiseInfo.raiseCreationInfo.raiseOwner,
                0,
                0,
                0
                );

        emit RaiseBoxEventsLib.RaiseBox_RaisePassed(raiseTarget, totalContributionsToProject[raiseId]);
        }

        // Interactions

        // Handle both ETH and ERC20 contributions
        if (isETH) {
            (bool successfullyContributed,) = address(raiseBoxDripHandler).call{value: amount}(""); 
            if (!successfullyContributed) {
                revert RaiseBoxErrorsLib.RaiseBoxContribution_contribute_ContributionFailed();
            }
        } else {
            address acceptedToken = raiseBoxCore.getAcceptedToken();
            if (acceptedToken == address(0)) {
                revert RaiseBoxErrorsLib.RaiseBoxCreation_createRaise_ERC20TokenNotSet();
            }
            
            IERC20 token = IERC20(acceptedToken);
            token.safeTransferFrom(msg.sender, address(raiseBoxDripHandler), amount);
        }

        emit RaiseBoxEventsLib.Contributed(
            msg.sender,
            amount,
            raiseId,
            totalContributionsToProject[raiseId],
            isETH
        );
    }

    receive() external payable { revert("eth not accepted"); } 
    // should not be able to receive eth directly except via contribute above

    // INTERNAL FUNCTIONS

    function _validateContribution(uint256 amount) internal returns (bool) {
        if (msg.value > 0) {
            // ETH contribution validation
            if (msg.value != amount) {
                revert RaiseBoxErrorsLib.RaiseBoxContribution_ValueSentMismatch();
            }
            return true;
        } else {
            // ERC20 contribution validation
            address acceptedToken = raiseBoxCore.getAcceptedToken();
            if (acceptedToken == address(0)) {
                revert RaiseBoxErrorsLib.RaiseBoxCreation_createRaise_ERC20TokenNotSet();
            }

            IERC20 token = IERC20(acceptedToken);
            if (token.balanceOf(msg.sender) < amount) {
                revert RaiseBoxErrorsLib.RaiseBoxContribution_InsufficientTokenBalance();
            }
            return false;
        }
    }

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

        maxContributionPerUser = ((MAX_CONTRIBUTION_PERCENTAGE * amountToRaise) / 1000);

        return maxContributionPerUser;
    }

    // EXTERNAL/GETTER FUNCTIONS

    function getEthAndErcRaisedByProject(bytes32 raiseId_) external view returns (uint256 ethRaised, uint256 erc20Raised) {
        raiseBoxCore.requireRaiseExist(raiseId_);
        return (ethContributionsToProject[raiseId_], erc20ContributionsToProject[raiseId_]);
    }

    function getMaxContributionAllowedForARaise(bytes32 raiseId_) external returns (uint256) {
            raiseBoxCore.requireRaiseExist(raiseId_);
            return _calMaxContribution(raiseId_);
    }

    function getContributors(bytes32 raiseId_) external view returns (address[] memory) {
        raiseBoxCore.requireRaiseExist(raiseId_);
        return contributors[raiseId_];
    }

    function getTotalContributors(bytes32 raiseId_) external view returns (uint256) {
        raiseBoxCore.requireRaiseExist(raiseId_);
        return raisers[raiseId_];
    }

    function getContributionHistory(address user, bytes32 raiseId_) external view returns (uint256[] memory) {

            raiseBoxCore.requireRaiseExist(raiseId_);
            require(user != address(0), "zero address cannot contribute");
            return contributionsToProjectArray[user][raiseId_];
    }

    function getUserRaiseContributions(bytes32 raiseId_, address user) external view returns(uint256) {
        raiseBoxCore.requireRaiseExist(raiseId_);
        require(user != address(0), "zero address cannot contribute");
        return amountContributedToRaise[user][raiseId_];
        
    }

    /// @notice this returns the total amount that a raise has accrued at an point in time
    /// @param raiseId id of the raise 
    /// @return uint256 all contributions made to raise so far
    function getTotalContributionsToRaise(bytes32 raiseId) external view returns (uint256) {

            raiseBoxCore.requireRaiseExist(raiseId);
            return totalContributionsToProject[raiseId];
    }

    function hasUserContributed(bytes32 raiseId, address user) external view returns (bool) {
        raiseBoxCore.requireRaiseExist(raiseId);
        return hasContributed[raiseId][user];
    }

}

