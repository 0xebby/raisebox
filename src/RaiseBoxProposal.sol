// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";

contract RaiseBoxProposal is IRaiseBoxProposal {
    IRaiseBoxCore public immutable raiseBoxCore; // the central contract that holds main storage of raisebox

    constructor(address raiseBoxCoreAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
    }

    using Strings for uint256;
    // to get funding drips from contributions, projects have to host proposals after every milestone achieved

    // max funds drip at anytime should be 25%
    // funds drip on very first proposal after raise is capped at 10%
    // 25% funds drip can only be dripped twice throughout project lifecycle
    // 25% fund drip cannot happen consecutively:
    // i.e after receiving a 25% fund drip, project cannot receive another 25%
    // in the very next drip
    // after first 25% fund drip, drips are capped at 15% untill a drip after the last 25% drip
    // drips %: in multiples of 5 up to 100
    // only 10% of overall funds contributed at time of hosting proposal is released per time

    uint256 public lastProposalTime;

    MileStoneProposalDetails[] public proposals;

    mapping(bytes32 => MileStoneProposalDetails) public proposalByProjectId;

    mapping(bytes32 => bool) public hasHostedProposal;

    mapping(bytes32 => uint256) public lastProposalTimeByProject;

    uint256 public blockTimeOfLastProposal; // track all proposals made and update +30 days for each call to host proposal
    //milestone struct to track proposals based on milestone reached
    uint256 public proposalCount; // protocol wide proposal count
    mapping(bytes32 => uint256) public proposalCountByProject; // track proposal count by project

    uint256 public constant INTERVAL_BETWEEN_PROPOSALS = 4 weeks;

    // events

    // proposal related events:
    event NewProposalHosted(
        address indexed projectCreator,
        uint256 proposalId,
        string proposalDescription,
        string proposalAchievement,
        uint256 lastProposalTime,
        uint256 numberOfProposalsHosted
    );
    event ProposalPassed();

    error raiseBoxProposal_InvalidProjectOwner();
    error RaiseBoxProposal_hostProposal_ProjectDoesNotExist();
    error RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
    error RaiseBoxProposal_hostProposal_RaiseNotEnded();
    error RaiseBoxProposal_hostProposal_InvalidProposalTextDetails();
    error RaiseBoxProposal_hostProposal_MaxYearlyProposalsReached();

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

    function hostProposal(string memory proposalTitle, string memory proposal, bytes32 projectId)
        external
        canHostProposal(msg.sender, projectId)
    {
        // checks already done in canHostProposal modifier above.

        // effects:

        hasHostedProposal[projectId] = true;
        proposalCount += 1;
        proposalCountByProject[projectId] += 1;
        lastProposalTimeByProject[projectId] = block.timestamp;

        proposalByProjectId[projectId] = MileStoneProposalDetails({
            lastProposalTime: lastProposalTimeByProject[projectId],
            description: proposalTitle,
            milestone: proposal,
            proposalId: proposalCountByProject[projectId]
        });

        // update storage in RaiseBoxCore contract
        raiseBoxCore.updateNumOfProposals(projectId);
        // interactions:

        emit NewProposalHosted(
            msg.sender,
            proposalCountByProject[projectId],
            proposalTitle,
            proposal,
            block.timestamp,
            proposalCountByProject[projectId]
        );
    }

    // 5, 10, 15, 20, 25 % fund drips only allowed
    // fund drip logic to be implemented in RaiseBoxCore contract
    // if proposalCount <= 1 => 10% fund drip
    // if proposalCount == 2 => 25% fund drip
    // if proposalCount > 2 && last fund drip != 25% => 25% fund drip
    // if proposalCount > 2 && last fund drip == 25% => 15% fund drip
    // else => 10% fund drip

    function getProposalCount(bytes32 projectId) external view returns (uint256) {
        return proposalCountByProject[projectId];
    }

    function getProtocolProposals() external view returns (uint256) { return proposalCount;}

    function getLastProposalTime(bytes32 projectId) external view returns (uint256) {
        MileStoneProposalDetails memory proposalDetails = proposalByProjectId[projectId];
        return proposalDetails.lastProposalTime;
    }

    function getHasHostedProposal(bytes32 projectId) external returns (bool) {
       return hasHostedProposal[projectId];

    }

    // function updateProposalDetails(bytes32 projectId, uint256 proposalId) external {}
}
