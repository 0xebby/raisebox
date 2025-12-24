// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";

contract RaiseBoxProposal is IRaiseBoxProposal, Ownable {
    IRaiseBoxCore public immutable raiseBoxCore; // the central contract that holds main storage of raisebox
    IRaiseBoxVoting public raiseBoxVoting; // voting contract

    constructor(address raiseBoxCoreAddress) Ownable(msg.sender) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
    }

    // PROPOSAL MODIFIERS

    modifier canHostProposal(address raiseCreator, bytes32 raiseId) {
        // does all checks before hosting proposal

        // get valid project from storage

        IRaiseBoxCore._RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId);
        address raiseOwner = raiseInfo.projectInfo.projectOwner;
        uint256 projectDuration = raiseInfo.projectInfo.projectDuration;
        uint256 raiseTarget = raiseInfo.projectInfo.raiseTarget;
        uint256 amountRaisedByProject = raiseInfo.amountRaisedByProject;
        uint256 proposals = raiseInfo.proposalsHosted;

        if (block.timestamp > projectDuration) {
            revert RaiseBoxErrorsLib.RaiseBox_RaiseEnded(raiseId);
        } else {
            // ascertain owner is host of project and is trying to host proposal
            if (raiseOwner == address(0) || raiseOwner != raiseCreator) {
                revert raiseBoxProposal_InvalidProjectOwner();
            }

            // proposal count within raise projectDuration cannot exceed 10(tentative)

            if (proposals > 10) {
                revert RaiseBoxProposal_ProposalsExceedsMax(MAX_ALLOWED_PROPOSALS);
            }

            // if (block.timestamp >= INTERVAL_BETWEEN_PROPOSALS ) {
            //        raiseInfo.raiseState = IRaiseBoxCore.RaiseState.PROPOSAL;
            // }

            // ascertain that project has not hosted proposal in the last 30 days
            if (hasHostedProposal[raiseId]) {
                if ((block.timestamp - lastProposalTime[raiseId]) < INTERVAL_BETWEEN_PROPOSALS) {
                    revert RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
                } 
            }

            // ascertain that raise has infact ended
            if (raiseTarget != amountRaisedByProject) {
                revert RaiseBoxProposal_hostProposal_RaiseNotPassedYet();
            }

            if (raiseBoxCore.getRaiseState(raiseId) != IRaiseBoxCore.RaiseState.PROPOSAL) {
                revert RaiseBoxErrorsLib.RaiseBoxProposal_hostProposal_NotInProposalState();
            }

           
        }

        _;
    }

    function hostProposal(string memory proposalTitle, string memory proposal, bytes32 raiseId, uint8 dripPercent)
        external
        canHostProposal(msg.sender, raiseId)
        returns (uint256 proposalId)
    {
        // validate dripPercent: must be multiple of 5 between 5 and 25
        if (dripPercent < 5 || dripPercent > 25 || (dripPercent % 5 != 0)) {
            revert RaiseBoxProposal_InvalidDripPercent();
        }
        // checks already done in canHostProposal modifier above.

        // get valid project from storage 
        IRaiseBoxCore._RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId);

        // effects:

        hasHostedProposal[raiseId] = true;
        proposalCount += 1;
        proposalsHosted[raiseId] += 1;
        lastProposalTime[raiseId] = block.timestamp;

        proposalIdByProject[raiseId][proposalsHosted[raiseId]] = MileStoneProposalDetails({
            lastProposalTime: lastProposalTime[raiseId],
            description: proposalTitle,
            milestone: proposal,
            proposalId: proposalsHosted[raiseId],
            dripPercent: dripPercent
        });

        // set voting start time in RaiseBoxVoting (48 hours after proposal hosting)
        // this gives time for vote delegation and studying of proposals ahead of voting

        raiseBoxVoting.setVotingStartTime(raiseId, proposalsHosted[raiseId], block.timestamp + 48 hours);

        // update storage in RaiseBoxCore contract
        raiseBoxCore.updateRaiseInfo(raiseInfo.projectInfo, raiseInfo.raiseDuration, raiseInfo.raiseCreationTime, raiseInfo.amountRaisedByProject, raiseInfo.projectRaiseCount, raiseInfo.proposalsHosted, raiseInfo.raiseExists, raiseId, IRaiseBoxCore.RaiseState.VOTING);

        // interactions:
        proposalId = proposalsHosted[raiseId];
        IRaiseBoxCore.RaiseState.VOTING;

        emit NewProposalHosted(proposalId, dripPercent, lastProposalTime[raiseId]);

        return proposalId;
    }

    ////                                            ////
    //          EXTERNAL/GETTER FUNCTIONS             //
    ////                                           ////

    function getProposalCount(bytes32 raiseId) external view returns (uint256) {
        return proposalsHosted[raiseId];
    }

    function getTotalProposals() external view returns (uint256) {
        return proposalCount;
    }

    function getLastProposalTime(bytes32 raiseId) external view returns (uint256) {
        return lastProposalTime[raiseId];
    }

    function getHasHostedProposal(bytes32 raiseId) external returns (bool) {
        return hasHostedProposal[raiseId];
    }

    function getProposalDetails(bytes32 raiseId, uint256 proposalId)
        external
        view
        returns (MileStoneProposalDetails memory proposalDetails_)
    {
        if (proposalId == 0 || proposalId > proposalsHosted[raiseId]) {
            revert RaiseBoxProposal_getProposalDetails_InvalidProposalId();
        }
        proposalDetails_ = proposalIdByProject[raiseId][proposalId];
        return proposalDetails_;
    }

    function setVotingContract(address contractToSet) external onlyOwner {
        raiseBoxVoting = IRaiseBoxVoting(contractToSet);
    }

    using Strings for uint256;

    MileStoneProposalDetails[] public proposals;

    mapping(bytes32 => bool) public hasHostedProposal;

    mapping(bytes32 => uint256) public lastProposalTime;

    //milestone struct to track proposals based on milestone reached
    uint256 public proposalCount; // protocol wide proposal count

    mapping(bytes32 => uint256) public proposalsHosted; // track proposal count by project

    mapping(bytes32 => mapping(uint256 => MileStoneProposalDetails)) public proposalIdByProject;

    uint256 public constant INTERVAL_BETWEEN_PROPOSALS = 4 weeks;

    uint256 public constant MAX_ALLOWED_PROPOSALS = 5;
}
