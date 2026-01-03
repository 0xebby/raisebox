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
    IRaiseBoxCore public immutable raiseBoxCore; 
    IRaiseBoxVoting public raiseBoxVoting; 

    constructor(address raiseBoxCoreAddress) Ownable(msg.sender) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
    }

    // PROPOSAL MODIFIERS

    modifier canHostProposal(address proposalHost_, bytes32 raiseId_) {
        // does all checks before hosting proposal

        // sanitize inputs:
        require(proposalHost_ != address(0), "zero address cannot host");

        raiseBoxCore.doesRaiseExist(raiseId_);

        // get valid project from storage
        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId_);

        // proposal creation only possible when raise state is in PROPOSAL state
        if (raiseInfo.raiseState != IRaiseBoxCore.RaiseState.PROPOSAL) {
                revert RaiseBoxErrorsLib.RaiseBoxProposal_RaiseNotInProposalState();
        } 

        uint256 projectDuration = raiseInfo.raiseCreationInfo.projectInfo.projectDuration;

        uint256 raiseCreatedAt = raiseInfo.raiseCreationInfo.raiseCreatedAt;

        if (block.timestamp > (projectDuration + raiseCreatedAt)) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_hostProposal_RaiseEnded(raiseId_);
        } else {

            // ascertain owner is host of project and is trying to host proposal
            if (raiseInfo.raiseCreationInfo.raiseOwner != proposalHost_) {
                revert raiseBoxProposal_InvalidRaiseOwner();
            }

            // ascertain that project has not hosted proposal in the last 4 weeks
            if (s_hasHostedProposal[raiseId_]) {
                if ((block.timestamp - lastProposalTime[raiseId_]) < INTERVAL_BETWEEN_PROPOSALS) {
                    revert RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
                } 
            }  
        }

        _;
    }

    
    function hostProposal(bytes32 raiseId_, MilestoneInfo calldata milestoneInfo_) external canHostProposal(msg.sender, raiseId_) returns (uint proposalId_) {

        // get sring input length
        // uint desLen = bytes(milestoneInfo_.description).length;
        // uint mileLen = bytes(milestoneInfo_.milestone).length;

        // checks

        // ensure string inputs are not empty or greater than max allowed
        if (
            bytes(milestoneInfo_.description).length <= 0 || 
            bytes(milestoneInfo_.description).length > type(uint256).max
            ) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_hostProposal_InvalidDescLength();
        }

        if (
            bytes(milestoneInfo_.milestone).length <= 0 || 
            bytes(milestoneInfo_.milestone).length > 256
            ) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_hostProposal_InvalidMilestoneLength(); 
        }

        // validate dripPercent: must be multiple of 5 between 5 and 25
        if (
            milestoneInfo_.dripPercent < 5 || 
            milestoneInfo_.dripPercent > 25 || 
            (milestoneInfo_.dripPercent % 5 != 0)
            ) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_hostProposal_InvalidDripPercent();
        }

        // effects
        proposalCount++;
        proposalsHostedByProject[raiseId_]++;
        lastProposalTime[raiseId_] = block.timestamp;
        s_hasHostedProposal[raiseId_] = true;

        
        proposalId_ = proposalsHostedByProject[raiseId_];
        
        // update core here:
        raiseBoxCore.updateRaiseInfo(
            raiseBoxCore.getRaiseInfo(raiseId_).raiseCreationInfo.projectInfo,
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

        emit RaiseBoxEventsLib.RaiseBoxProposal_updateProposalInfo_ProposalInfoUpdated();

        /// @dev this ensures that voting begins exactly 48 hours after hosting a proposal
        /// @dev contributors can use this window to delegate votes, confirm milestone claims
        raiseBoxVoting.setVotingStartTime(
            raiseId_, 
            proposalId_, 
            (lastProposalTime[raiseId_] + 2 days)
            );

        emit RaiseBoxEventsLib.NewProposalHosted(
            proposalId_, 
            milestoneInfo_.dripPercent, 
            lastProposalTime[raiseId_]
            );

        return proposalId_;

    }

    function setVotingContract(address contractToSet) external onlyOwner {
        raiseBoxVoting = IRaiseBoxVoting(contractToSet);
    }

    // types:

    using Strings for uint256;

    /// @notice state variables

    mapping(bytes32 => bool) public s_hasHostedProposal;

    mapping(bytes32 => uint256) public lastProposalTime;

    uint256 public proposalCount; // protocol wide proposal count

    mapping(bytes32 => uint256) public proposalsHostedByProject; 

    uint256 public constant INTERVAL_BETWEEN_PROPOSALS = 4 weeks;

    uint256 public constant MAX_ALLOWED_FAILED_PROPOSALS = 5;

    mapping(bytes32 => mapping(uint256 => ProposalInfo)) public proposalInfo;

    mapping(bytes32 => ProposalState) public proposalState;

        
    //internal functions
    
    function _updateProposalInfo(
        bytes32 raiseId_, 
        uint256 proposalId_
        ) internal {

        // ensure that the calls to this function is from the voting contract only
        if (
            msg.sender != address(raiseBoxVoting) 
        ) {
            revert RaiseBoxErrorsLib.RaiseBoxProposal_updateProposalInfo_Unauthorized(); 
        }

        // ensure that the user inputs: `raiseId_` and `proposalId_ for this function are valid
        _isValidProposal(raiseId_, proposalId_);

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

    function _getProposalState(bytes32 raiseId_, uint256 proposalId_) internal view returns(ProposalState) {

        if (_isValidProposal(raiseId_, proposalId_)) {

            return proposalInfo[raiseId_][proposalId_].proposalState;
        }
    }

    function _isValidProposal(bytes32 raiseId_, uint256 proposalId_) internal view returns (bool) {

            raiseBoxCore.doesRaiseExist(raiseId_);

            // get proposalDetails
            ProposalInfo memory proposalInfo =  proposalInfo[raiseId_][proposalId_];

            if (proposalInfo.doesProposalExist) {
                
                return true;

            } else {

                revert RaiseBoxErrorsLib.RaiseBoxProposal_isValidProposal_ProposalDoesNotExist(proposalId_);

             }
    }

    ////                                            ////
    //          EXTERNAL/GETTER FUNCTIONS             //
    ////                                           ////

    function isValidProposal(bytes32 raiseId, uint256 proposalId) external view returns (bool) { return _isValidProposal(raiseId, proposalId); }

    function getProposalCount(bytes32 raiseId) external view returns (uint256) {
        raiseBoxCore.doesRaiseExist(raiseId);
        return proposalsHostedByProject[raiseId];
    }

    function getTotalProposals() external view returns (uint256) {
        return proposalCount;
    }

    function getLastProposalTime(bytes32 raiseId) external view returns (uint256) {
        return lastProposalTime[raiseId];
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

    function getProposalState(bytes32 raiseId, uint256 proposalId) external view returns(ProposalState) {
        return _getProposalState(raiseId, proposalId);
    }

    function updateProposalInfo(
        bytes32 raiseId_, 
        uint256 proposalId_
    ) external {
        _updateProposalInfo(raiseId_, proposalId_);
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


}
