// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {ICore} from "../src/interfaces/ICore.sol";
import {RaiseBoxStorage} from "../src/RaiseBoxStorage.sol";

contract RaiseBoxProposal is ICore, IRaiseBoxProposal, RaiseBoxStorage {
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
    address raiseBoxCoreaddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    IRaiseBoxProjectCreation public immutable i_raiseBoxProjectCreator;
    ICore public raiseBoxCore; // the central contract that holds main storage of raisebox

    uint256 public lastProposalTime;

    MileStoneProposalDetails[] public proposals;

    mapping(address => uint256) public lastProposalTimeByProject;

    mapping(bytes32 => MileStoneProposalDetails) public proposalByProjectId;

    // projectid => proposalid => proposalInfo for that id

    mapping(uint256 => string) public proposalByType;

    mapping(uint256 => MileStoneProposalDetails) proposalIdToProposal;

    mapping (bytes32 => bool) public hasHostedProposal;

    mapping(bytes32 => uint256) public proposalCountByProjectId;

    uint256 public blockTimeOfLastProposal; // track all proposals made and update +30 days for each call to host proposal
    //milestone struct to track proposals based on milestone reached

    uint256 public constant INTERVAL_BETWEEN_PROPOSALS = 30 days; // DAYS == 36 proposals/year

    // events

    // proposal related events:
    event NewProposalHosted(
        address indexed projectCreator,
        uint256 proposalId,
        string proposalDescription,
        string proposalAchievement,
        uint256 timestamp,
        uint256 numberOfProposalsHosted
    );
    event ProposalPassed();

    error raiseBoxProposal_InvalidProjectOwner();
    error RaiseBoxProposal_hostProposal_ProjectDoesNotExist();
    error RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
    error RaiseBoxProposal_hostProposal_RaiseNotEnded();
    error RaiseBoxProposal_hostProposal_InvalidProposalTextDetails();

    constructor(address raiseBoxCoreaddress_) RaiseBoxStorage() {
        raiseBoxCoreaddress = raiseBoxCoreaddress_;
        i_raiseBoxProjectCreator = IRaiseBoxProjectCreation(raiseBoxCoreaddress_);
    }

    modifier onlyProjectOwner(address projectCreator, bytes32 projectId) {
        
        if (projectCreator == address(0) || projectCreator != i_raiseBoxProjectCreator.getProjectCreator(projectId)) {
            revert raiseBoxProposal_InvalidProjectOwner();
        }

        _;
    }

    function hostProposal(
        string memory proposalTitle,
        string memory proposal,
        bytes32 projectId
    ) public onlyProjectOwner(msg.sender, projectId) {

        ProjectInfo memory project = raiseBoxCore.getProject(projectId);

        // does project exist
        bool projectExist = project.projectExists;

        if (!projectExist) {
            revert RaiseBoxProposal_hostProposal_ProjectDoesNotExist();
        }

        if ((block.timestamp < project.duration)) {
            revert RaiseBoxProposal_hostProposal_RaiseNotEnded();
        }

        if (bytes(proposalTitle).length == 0 || bytes(proposal).length == 0 ) {
            revert RaiseBoxProposal_hostProposal_InvalidProposalTextDetails();
        }

        if (hasHostedProposal[projectId]) {
            if (block.timestamp < INTERVAL_BETWEEN_PROPOSALS) {
                revert RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
            }
            
        }

        uint256 count = proposalCountByProjectId[projectId]++;

        // update milestone struct

        MileStoneProposalDetails storage mileStoneProposalDetails;

      
        proposalByProjectId[projectId] = MileStoneProposalDetails({
            lastProposalTime: block.timestamp,
            description: proposalTitle,
            achievement: proposal,
            proposalId: count,
            proposalCount: count
        });



        hasHostedProposal[projectId] = true;

    }

    // function to host a proposal by project:

    // function updateStorage(bytes32 projectId) external override {
    //         proposalByProjectId[projectId].proposalCount += 1;
    //         projectIDToProject[projectId].proposalsHosted +=1;

    //     }

    // function hostProposal(
    //     string memory _description,
    //     string memory _achievement,
    //     bytes32 projectId
    // ) public onlyProjectOwner(msg.sender, projectId) {
    //     // get project by the id provided by the caller:
    //     bool projectExist = i_raiseBoxProjectCreator.getProject(projectId).projectExists;
    //     uint256 amountRaisedByProject = i_raiseBoxProjectCreator.getAmountRaisedByProject(
    //         projectId
    //     );

    //     uint256 amountToRaise = i_raiseBoxProjectCreator
    //         .getProject(projectId)
    //         .amountToRaise;

    //     if (!projectExist) {
    //         revert RaiseBoxProposal_hostProposal_ProjectDoesNotExist();
    //     }

    //     if (
    //         block.timestamp <
    //         lastProposalTimeByProject[msg.sender] + INTERVAL_BETWEEN_PROPOSALS
    //     ) {
    //         revert RaiseBoxProposal_hostProposal_ProposalCoolDownOn();
    //     }

    //     if (amountRaisedByProject != amountToRaise) {
    //         revert RaiseBoxProposal_hostProposal_RaiseNotEnded();
    //     }

    //     require(
    //         bytes(_description).length > 0,
    //         "description cannot be empty string"
    //     );
    //     require(
    //         bytes(_achievement).length > 0,
    //         "achievement cannot be empty string"
    //     );
    //     // effects:
    //     // MileStoneProposalDetails memory milestoneProposal;
    //     proposalByProjectId[projectId] = MileStoneProposalDetails({
    //         lastProposalTime: block.timestamp,
    //         description: _description,
    //         achievement: _achievement,
    //         proposalId: proposalByProjectId[projectId].proposalId,
    //         proposalCount: proposalByProjectId[projectId].proposalCount
    //     });

    //     proposals.push(proposalByProjectId[projectId]);

    //     // proposals.push(milestoneProposal);
    //     lastProposalTimeByProject[msg.sender] = block.timestamp;

    //     // proposalByProjectId[projectId].proposalCount += 1;

    //     proposalByProjectId[projectId].proposalId += 1;

    //     // this.updateStorage(projectId);

    //     // blockTimeOfLastProposal =
    //     //     lastProposalTimeByProject[msg.sender] +
    //     //     30 days;
    //     // numberOfProposalsHosted += 1;

    //     emit NewProposalHosted(
    //         msg.sender,
    //         proposalByProjectId[projectId].proposalId,
    //         _description,
    //         _achievement,
    //         block.timestamp,
    //         proposalByProjectId[projectId].proposalCount
    //     );
    // }

    // getters

    // function getAProposal(uint256 proposalId, bytes32 projectId) public view {
    //     for (uint256 i = 0; i <= proposals.length; i++) {
    //         console.log(proposals[i].);
    //     }

    // }

    // function getProposals(
    //     bytes32 projectId
    // ) public returns (MileStoneProposalDetails memory mileStoneDetails) {
    //     require(
    //         i_raiseBoxProjectCreator.getProject(projectId).projectExists,
    //         "project does not exist"
    //     );
    //     mileStoneDetails = proposalByProjectId[projectId];
    // }

    // function viewProposalInfo(bytes32 projectId, uint256 proposalId) external {
    //     MileStoneProposalDetails memory miles;
    //     miles = proposalByProjectId(projectId)(proposalId);

    //     // console.log(
    //     //     string(
    //     //         abi.encodePacked(
    //     //             "Last Proposal Time: ",
    //     //             proposalInfo(proposalId).lastProposalTime().toString(),
    //     //             " | Description: ",
    //     //             proposalInfo(proposalId).description,
    //     //             " | achievement: ",
    //     //             proposalInfo(proposalId).achievement,
    //     //             " | proposal id ",
    //     //             proposalInfo(proposalId).proposalId.toString()
    //     //         )
    //     //     )
    //     // );
    // }

    function updateProposalDetails(bytes32 projectId, uint256 proposalId) external {}
}
