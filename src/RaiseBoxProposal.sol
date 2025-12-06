// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract RaiseBoxProposal is IRaiseBoxProposal, Ownable {
    IRaiseBoxCore public immutable raiseBoxCore; // the central contract that holds main storage of raisebox
    IRaiseBoxVoting public  raiseBoxVoting; // voting contract

     constructor(address raiseBoxCoreAddress) Ownable(msg.sender) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
    }

    // events

    modifier canHostProposal(address raiseCreator, bytes32 projectId) {
        // does all checks before hosting proposal

        // get valid project from storage

        (
            ,
            address raiseOwner,
            ,
            uint256 amountToRaise,
            uint256 duration,
            ,
            ,
            ,
            uint256 amountRaisedByProject,
            uint256 proposals
            ,
        ) = raiseBoxCore.getProjectInfo(projectId);

        if (block.timestamp > duration) {
            revert IRaiseBoxCore.RaiseBox_RaiseEnded(projectId);
        } else {
            // ascertain owner is host of project and is trying to host proposal
            if (raiseOwner == address(0) || raiseOwner != raiseCreator) {
                revert raiseBoxProposal_InvalidProjectOwner();
            }

            // proposal count within raise duration cannot exceed 10(tentative)

            if (proposals > 10) {
                revert RaiseBoxProposal_ProposalsExceedsMax(MAX_ALLOWED_PROPOSALS);
            }

            // ascertain that raise has infact ended
            if (amountToRaise != amountRaisedByProject) {
                revert RaiseBoxProposal_hostProposal_RaiseNotEnded();
            }

            // ascertain that project has not hosted proposal in the last 30 days
            if (hasHostedProposal[projectId]) {
                if ((block.timestamp - lastProposalTime[projectId]) < INTERVAL_BETWEEN_PROPOSALS) {
                    revert RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
                }
            }
        }

        _;
    }


    function hostProposal(string memory proposalTitle, string memory proposal, bytes32 projectId, uint8 dripPercent)
        external
        canHostProposal(msg.sender, projectId)
        returns (uint256 proposalId)
    {
        // validate dripPercent: must be multiple of 5 between 5 and 25
        if (dripPercent < 5 || dripPercent > 25 || (dripPercent % 5 != 0)) {
            revert RaiseBoxProposal_InvalidDripPercent();
        }
        // checks already done in canHostProposal modifier above.

        // effects:

        hasHostedProposal[projectId] = true;
        proposalCount += 1;
        proposalsHosted[projectId] += 1;
        lastProposalTime[projectId] = block.timestamp;

        proposalIdByProject[projectId][proposalsHosted[projectId]] = MileStoneProposalDetails({
            lastProposalTime: lastProposalTime[projectId],
            description: proposalTitle,
            milestone: proposal,
            proposalId: proposalsHosted[projectId],
            dripPercent: dripPercent
        });

        // set voting start time in RaiseBoxVoting (10 minutes after proposal hosting)
        
        raiseBoxVoting.setVotingStartTime(projectId, proposalsHosted[projectId], block.timestamp + 10 minutes);

        // update storage in RaiseBoxCore contract
        raiseBoxCore.updateNumOfProposals(projectId);

        // interactions:
        proposalId = proposalsHosted[projectId];

        emit NewProposalHosted(msg.sender, proposalId, dripPercent, lastProposalTime[projectId]);

        return proposalId;
    }

    ////                                            ////
    //          EXTERNAL/GETTER FUNCTIONS             //
    ////                                           ////

    function getProposalCount(bytes32 projectId) external view returns (uint256) {
        return proposalsHosted[projectId];
    }

    function getTotalProposals() external view returns (uint256) {
        return proposalCount;
    }

    function getLastProposalTime(bytes32 projectId) external view returns (uint256) {
        return lastProposalTime[projectId];
    }

    function getHasHostedProposal(bytes32 projectId) external returns (bool) {
        return hasHostedProposal[projectId];
    }

    function getProposalDetails(bytes32 projectId, uint256 proposalId)
        external
        view
        returns (MileStoneProposalDetails memory proposalDetails_)
    {
        if (proposalId == 0 || proposalId > proposalsHosted[projectId]) {
            revert RaiseBoxProposal_getProposalDetails_InvalidProposalId();
        }
        proposalDetails_ = proposalIdByProject[projectId][proposalId];
        return proposalDetails_;
    }

    
    function setVotingContract(address contractToSet) external onlyOwner() {
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
