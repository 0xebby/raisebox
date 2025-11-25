// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";

contract RaiseBoxProposal is IRaiseBoxProposal {
    IRaiseBoxCore public immutable raiseBoxCore; // the central contract that holds main storage of raisebox
    IRaiseBoxVoting public immutable raiseBoxVoting; // voting contract

    constructor(address raiseBoxCoreAddress, address raiseBoxVotingAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
        raiseBoxVoting = IRaiseBoxVoting(raiseBoxVotingAddress);
    }

    using Strings for uint256;
  


    MileStoneProposalDetails[] public proposals;

    mapping(bytes32 => bool) public hasHostedProposal;

    mapping(bytes32 => uint256) public lastProposalTimeByProject;

    uint256 public blockTimeOfLastProposal; // track all proposals made and update +30 days for each call to host proposal
    //milestone struct to track proposals based on milestone reached
    uint256 public proposalCount; // protocol wide proposal count
    mapping(bytes32 => uint256) public proposalCountByProject; // track proposal count by project

    mapping(bytes32 => mapping(uint256 => MileStoneProposalDetails)) public proposalIdByProject;

    uint256 public constant INTERVAL_BETWEEN_PROPOSALS = 4 weeks;

    // events



    modifier canHostProposal(address projectCreator, bytes32 projectId) {
        // does all checks before hosting proposal

        // get valid project from storage

        (, address projectOwner,, uint256 amtToRaise,uint256 duration,,, uint256 timeCreated, uint256 amountRaisedByProject,,) =
            raiseBoxCore.getProjectInfo(projectId);

        if (block.timestamp > duration) {
            revert IRaiseBoxCore.RaiseBox_RaiseEnded(projectId);

        } else {
            
            // ascertain owner is host of project and is trying to host proposal
            if (projectOwner == address(0) || projectOwner != projectCreator) {
                revert raiseBoxProposal_InvalidProjectOwner();
            }

            // ascertain that raise has infact ended
            if (amtToRaise != amountRaisedByProject) {
                revert RaiseBoxProposal_hostProposal_RaiseNotEnded();
            }

            // ascertain that project has not hosted proposal in the last 30 days
            if (hasHostedProposal[projectId]) {
                if ((block.timestamp - lastProposalTimeByProject[projectId]) < INTERVAL_BETWEEN_PROPOSALS) {
                    revert RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
                }
            }
        
        }

        _;
    }

    function hostProposal(
        string memory proposalTitle,
        string memory proposal,
        bytes32 projectId,
        uint8 dripPercent
    ) external canHostProposal(msg.sender, projectId)
    {
        // validate dripPercent: must be multiple of 5 between 5 and 25
        if (dripPercent < 5 || dripPercent > 25 || (dripPercent % 5 != 0)) {
            revert RaiseBoxProposal_InvalidDrip();
        }
        // checks already done in canHostProposal modifier above.

        // effects:

        hasHostedProposal[projectId] = true;
        proposalCount += 1;
        proposalCountByProject[projectId] += 1;
        lastProposalTimeByProject[projectId] = block.timestamp;

        proposalIdByProject[projectId][proposalCountByProject[projectId]] = MileStoneProposalDetails({
            lastProposalTime: lastProposalTimeByProject[projectId],
            description: proposalTitle,
            milestone: proposal,
            proposalId: proposalCountByProject[projectId],
            dripPercent: dripPercent
        });

        // set voting start time in RaiseBoxVoting (10 minutes after proposal hosting)
        raiseBoxVoting.setVotingStartTime(projectId, proposalCountByProject[projectId], block.timestamp + 10 minutes);

        // update storage in RaiseBoxCore contract
        raiseBoxCore.updateNumOfProposals(projectId);
        // interactions:

        emit NewProposalHosted(
            msg.sender,
            proposalCountByProject[projectId],
            proposalTitle,
            proposal,
            lastProposalTimeByProject[projectId],
            proposalCountByProject[projectId]
        );
    }

    

  

    ////                                            ////
    //          EXTERNAL/GETTER FUNCTIONS             //
    ////                                           ////

    function getProposalCount(bytes32 projectId) external view returns (uint256) {
        return proposalCountByProject[projectId];
    }

    function getTotalProposals() external view returns (uint256) { return proposalCount;}

    function getLastProposalTime(bytes32 projectId) external view returns (uint256) {
        return lastProposalTimeByProject[projectId];
    }

    function getHasHostedProposal(bytes32 projectId) external returns (bool) {
       return hasHostedProposal[projectId];

    }

    function getProposalDetails(bytes32 projectId, uint256 proposalId)
        external
        view
        returns (MileStoneProposalDetails memory proposalDetails_)
    {
        if (proposalId == 0 || proposalId > proposalCountByProject[projectId]) {
            revert RaiseBoxProposal_getProposalDetails_InvalidProposalId();
        }
        proposalDetails_ = proposalIdByProject[projectId][proposalId];
        return proposalDetails_;
    }

}
