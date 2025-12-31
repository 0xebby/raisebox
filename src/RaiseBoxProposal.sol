// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";

contract RaiseBoxProposal is IRaiseBoxProposal, Ownable {
    IRaiseBoxCore public immutable raiseBoxCore; // the central contract that holds main storage of raisebox
    IRaiseBoxVoting public raiseBoxVoting; // voting contract

    constructor(address raiseBoxCoreAddress) Ownable(msg.sender) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
    }

    // PROPOSAL MODIFIERS

    modifier canHostProposal(address proposalHost_, bytes32 raiseId_) {
        // does all checks before hosting proposal

        // get valid project from storage

        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId_);

        address raiseOwner = raiseInfo.raiseCreationInfo.raiseOwner;

        uint256 projectDuration = raiseInfo.raiseCreationInfo.projectInfo.projectDuration;

        uint256 raiseTarget = raiseInfo.raiseCreationInfo.projectInfo.raiseTarget;

        uint256 raiseCreatedAt = raiseInfo.raiseCreationInfo.raiseCreatedAt;

        uint256 amountRaisedByProject = raiseInfo.raiseContributionInfo.amountRaisedByProject;

        uint256 proposals = raiseInfo.proposalInfo.proposalsHostedByProject;

        if (block.timestamp > (projectDuration + raiseCreatedAt)) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_hostProposal_RaiseEnded(raiseId_);
        } else {

            // check if raise hasn't already failed
            if (raiseInfo.raiseState == IRaiseBoxCore.RaiseState.FAILED) {
                revert RaiseBoxErrorsLib.RaiseBox_RaiseFailed(raiseId_);
            }

            //check if raiseId paased is a valid one
            if (!raiseInfo.raiseCreationInfo.doesRaiseExist) {
                revert RaiseBoxErrorsLib.RaiseBoxProposal_canHostProposal_InvalidRaiseId(raiseId_);
            }

            // ascertain owner is host of project and is trying to host proposal
            if (raiseOwner == address(0) || raiseOwner != proposalHost_) {
                revert raiseBoxProposal_InvalidRaiseOwner();
            }



            // proposal count within raise projectDuration cannot exceed 10(tentative)

            // if (proposals > 15) {
            //     revert RaiseBoxProposal_ProposalsExceedsMax(MAX_ALLOWED_FAILED_PROPOSALS);
            // }

            // if (proposals => 15 && block.timestamp < projectDuration) {
            //     revert RaiseBoxErrorsLib.RaiseBox_RaiseFailed(raiseId);

            // }

            // if (raiseBoxVoting.getFailedProposalsCount(raiseId_) >= MAX_ALLOWED_FAILED_PROPOSALS) {
            //     revert RaiseBoxErrorsLib.RaiseBox_RaiseFailed(raiseId_); 
            // }

            // if (block.timestamp >= INTERVAL_BETWEEN_PROPOSALS ) {
            //        raiseInfo.raiseState = IRaiseBoxCore.RaiseState.PROPOSAL;
            // }

            // ascertain that project has not hosted proposal in the last 4 weeks
            if (hasHostedProposal[raiseId_]) {
                if ((block.timestamp - lastProposalTime[raiseId_]) < INTERVAL_BETWEEN_PROPOSALS) {
                    revert RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
                } 
            }

            // ascertain that raise has infact ended
            if (raiseTarget != amountRaisedByProject) {
                revert RaiseBoxProposal_hostProposal_RaiseNotPassedYet();
            }

            // proposal creation only possible when raise state is in PROPOSAL
            if (raiseBoxCore.getRaiseState(raiseId_) != IRaiseBoxCore.RaiseState.PROPOSAL) {
                revert RaiseBoxErrorsLib.RaiseBoxProposal_RaiseNotInProposalState();
            }
        }

        _;
    }

    
    function hostProposal(bytes32 raiseId_, MilestoneInfo calldata milestoneInfo_) external canHostProposal(msg.sender, raiseId_) returns (uint proposalId_) {

        // get sring input length
        uint desLen = bytes(milestoneInfo_.description).length;
        uint mileLen = bytes(milestoneInfo_.milestone).length;

        // checks
        // ensure string inputs are not empty or greater than max allowed
        if (desLen <= 0 || desLen > type(uint32).max) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_hostProposal_InvalidDescLength();
        }

        if (mileLen <= 0 || mileLen > 256) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_hostProposal_InvalidMilestoneLength(); 
        }

        // validate dripPercent: must be multiple of 5 between 5 and 25
        if (
            milestoneInfo_.dripPercent < 5 || 
            milestoneInfo_.dripPercent > 25 || 
            (milestoneInfo_.dripPercent % 5 != 0)
            ) {
            revert RaiseBoxProposal_InvalidDripPercent();
        }

        // effects
        proposalCount++;
        proposalsHostedByProject[raiseId_]++;
        lastProposalTime[raiseId_] = block.timestamp;
        hasHostedProposal[raiseId_] = true;

        
        proposalId_ = proposalsHostedByProject[raiseId_];
        
        // get core
        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId_);

        // update core here:
        raiseBoxCore.updateRaiseInfo(
            raiseInfo.raiseCreationInfo.projectInfo,
            lastProposalTime[raiseId_],
            0,
            true,
            raiseId_, // the only used field here
            msg.sender,
            0,
            0,
            0
        );

        // update milestone info for proposal in storage
        proposalInfo[raiseId_][proposalId_] = ProposalInfo({
            milestoneInfo: milestoneInfo_,
            proposalId: proposalId_,
            lastProposalTime: lastProposalTime[raiseId_],
            proposalState: ProposalState.ACTIVE,
            doesProposalExist: true
        });

        // emit RaiseBoxEventsLib.ProposalStateUpdated(ProposalState.ACTIVE);
        emit RaiseBoxEventsLib.RaiseBoxProposal_updateProposalInfo_ProposalInfoUpdated();

        raiseBoxVoting.setVotingStartTime(raiseId_, proposalId_, (lastProposalTime[raiseId_] + 2 days));

        emit NewProposalHosted(proposalId_, milestoneInfo_.dripPercent, lastProposalTime[raiseId_]);

        return proposalId_;

    }


    function updateProposalState(bytes32 raiseId_, uint256 proposalId_, ProposalState proposalState_) external {

        if (msg.sender != address(raiseBoxVoting)) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_updateProposalInfo_Unauthorized();
        }

        if (_isValidProposal(raiseId_, proposalId_)) {

            proposalInfo[raiseId_][proposalId_].proposalState = proposalState_;

        }
      
        emit RaiseBoxEventsLib.ProposalStateUpdated(proposalState_);
    }

    // this function updates proposalInfo based on proposalState
    // when proposalState is INACTIVE, update proposalState to ACTIVE and update proposalHosting info too: milestone, proposalid, lastProposalTime, doesProposalExist
    // when proposalState is PASSED, update to INACTIVE
    // when proposalState is FAILED,increment conFailedProposals and nonConFailedProposals by 1

    function updateProposalInfo(
        bytes32 raiseId_, 
        uint256 proposalId_
    ) external {
        _updateProposalInfo(raiseId_, proposalId_);
    }

    function _updateProposalInfo(
        bytes32 raiseId_, 
        uint256 proposalId_
        ) internal {

        // ensure that the calls to this function are either from the voting contract or this
        // contract itself.
        if (
            msg.sender != address(raiseBoxVoting) 
            // msg.sender != caller
        ) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_updateProposalInfo_Unauthorized(); 
        }

        // ensure that the user inputs: `raiseId_` and `proposalId_ for this function are valid
        if (
            raiseBoxCore.doesRaiseExist(raiseId_)
        ) {
                ProposalInfo storage proposalInfo_;
                proposalInfo_ = proposalInfo[raiseId_][proposalId_];
            // ensure that the proposalState for `rasieId_` and `proposalId_` is INACTIVE
            if (_getProposalState(raiseId_, proposalId_) == IRaiseBoxProposal.ProposalState.ACTIVE) {
                (
                    uint256 forVotes_, uint256 againstVotes_, 
                ) = raiseBoxVoting.getProposalVotes(raiseId_, proposalId_);

                if (forVotes_ > againstVotes_) {

                    proposalInfo_.proposalState = IRaiseBoxProposal.ProposalState.PASSED;
                    emit RaiseBoxEventsLib.ProposalStateUpdated(ProposalState.PASSED);

                } else {
                    
                    proposalInfo_.proposalState = IRaiseBoxProposal.ProposalState.FAILED;
                    emit RaiseBoxEventsLib.ProposalStateUpdated(ProposalState.FAILED);
                }
            }

            emit RaiseBoxEventsLib.RaiseBoxProposal_updateProposalInfo_ProposalInfoUpdated();
        }
    }


    //internal functions

    function _isValidProposal(bytes32 raiseId_, uint256 proposalId_) internal view returns (bool) {

       if (raiseBoxCore.doesRaiseExist(raiseId_)) {
            // get proposalDetails
            ProposalInfo memory proposalInfo =  proposalInfo[raiseId_][proposalId_];

            if (proposalInfo.doesProposalExist) {
                return true;
            } else {
                revert RaiseBoxErrorsLib.RaiseBoxProposal_isValidProposal_ProposalDoesNotExist(proposalId_);
             }
       }
    }

    function isValidProposal(bytes32 raiseId, uint256 proposalId) external view returns (bool) { return _isValidProposal(raiseId, proposalId); }

    ////                                            ////
    //          EXTERNAL/GETTER FUNCTIONS             //
    ////                                           ////

    function getProposalCount(bytes32 raiseId) external view returns (uint256) {
        if (raiseBoxCore.doesRaiseExist(raiseId)) {
           return proposalsHostedByProject[raiseId];
        }
        
    }

    function getTotalProposals() external view returns (uint256) {
        return proposalCount;
    }

    function getLastProposalTime(bytes32 raiseId) external view returns (uint256) {
        return lastProposalTime[raiseId];
    }

    function getHasHostedProposal(bytes32 raiseId) external view returns (bool) {
        return hasHostedProposal[raiseId];
    }

    function getProposalInfo(bytes32 raiseId_, uint256 proposalId_)
        external
        view
        returns (ProposalInfo memory proposalInfo_)
    {

        if (_isValidProposal(raiseId_, proposalId_)) {
            proposalInfo_ = proposalInfo[raiseId_][proposalId_];
            return proposalInfo_;
        }
    }

    function setVotingContract(address contractToSet) external onlyOwner {
        raiseBoxVoting = IRaiseBoxVoting(contractToSet);
    }

    using Strings for uint256;

    MilestoneInfo[] public proposals;

    mapping(bytes32 => bool) public hasHostedProposal;

    mapping(bytes32 => uint256) public lastProposalTime;

    //milestone struct to track proposals based on milestone reached
    uint256 public proposalCount; // protocol wide proposal count

    mapping(bytes32 => uint256) public proposalsHostedByProject; // track proposal count by project

    mapping(bytes32 => mapping(uint256 => MilestoneInfo)) public milestoneProposalInfo;

    uint256 public constant INTERVAL_BETWEEN_PROPOSALS = 4 weeks;

    uint256 public constant MAX_ALLOWED_FAILED_PROPOSALS = 5;

    mapping(bytes32 => mapping(uint256 => ProposalInfo)) public proposalInfo;

    mapping(bytes32 => ProposalState) public proposalState;


    function getProposalState(bytes32 raiseId, uint256 proposalId) external view returns(ProposalState) {
        return _getProposalState(raiseId, proposalId);
    }

    function _getProposalState(bytes32 raiseId_, uint256 proposalId_) internal view returns(ProposalState) {

        if (_isValidProposal(raiseId_, proposalId_)) {

            ProposalInfo memory proposalInfo_;

            proposalInfo_ = proposalInfo[raiseId_][proposalId_];
            
            return proposalInfo_.proposalState;
        }
       
           
        
    }


    function _getLastProposalState(bytes32 raiseId, uint256 proposalId) internal view returns(ProposalState) {
        uint256 lastProposalId = (proposalId - 1);
        return _getProposalState(raiseId, lastProposalId);
    }


   

}
