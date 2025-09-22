// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {RaiseBoxVoting} from "../src/RaiseBoxVoting.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {RaiseBoxFaucet} from "/home/ebby/contracts-2025/crowdfund-faucet-contract/src/RaiseBoxFaucet.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {RaiseBoxStorage} from "../src/RaiseBoxStorage.sol";
import {ICore} from "../src/interfaces/ICore.sol";

/// @title RaiseBox - Decentralized crowdfunding contract
/// @author 0xcoda
/// @notice This contract allows users to contribute ETH, RBT or any other erc20 token all cobnverted to stbales(usdt) to a project, collects protocol fees, and enables withdrawals for project owner and protocol.
/// @dev Designed for EVM-compatible blockchains. Uses custom errors for gas efficiency.

contract RaiseBox is IRaiseBoxProjectCreation, RaiseBoxVoting {
    ICore public raiseBoxCore;
    RaiseBoxStorage public raiseBoxStorage;

    using Strings for uint256;
    using Strings for bytes32;
    // ----------------------------------------------------------------------- state variables -------------------------------------------------------------------------  //

    // State variables

    // token used on testnet to interact with contract:
    // for contribution
    // for protocol fees
    // for project funds
    // this contract's currency ----- testnet ---- deployed on sepolia ---- see contract address in constructor

    // crownfund project related state variables

    // ----------------------------------------------------------------------- constants -------------------------------------------------------------------------  //

    uint256 private constant PROPOSAL_APPROVAL_PERCENTAGE = 51; // 51% of contributors vote required for a proposal to pass and  10% funds released

    // ----------------------------------------------------------------------- structs -------------------------------------------------------------------------  //

    // uint256 public projectIDCounter;

    // mapping(uint256 => ProjectInfo) public projectIndexToProject;

    uint256 public projectIndex;
    mapping(address => uint16) public projectCountPerProjectOwner;

    // ----------------------------------------------------------------------- enums -------------------------------------------------------------------------  //

    // enums

    // ----------------------------------------------------------------------- errors -------------------------------------------------------------------------  //

    // protocol fees related errors:
    error RaiseBox_NoFeesToWithdraw();
    error CrowdFund_FeesWithdrawalFailed();
    error CrowdFund_OnlyProtocolCanWithdrawFees();

    // protocol campaign escrow related errors:
    error CrowdFund_ProtocolAddressCannotBeZeroAddress();

    //project related errors:
    error CrowdFund_OnlyProjectOwnerCanWithdrawFunds();
    error CrowdFund_OnlyProjectOwnerCanCall();

    // project creation related errors:
    error RaiseBox_CreateProject_ProjectAlreadyExist();
    error RaiseBox_getProjectByIndex_InvalidProjectIndex();
    error RaiseBox_createProject_AlreadyHaveALiveProject();

    // raise related errors:
    error RaiseBox_RaiseFailed();

    error RaiseBox_NoContributionsMade();

    // ----------------------------------------------------------------------- events -------------------------------------------------------------------------  //

    // events emitted:

    event RaiseBoxCreateProject_ProjectCreated(
        string projectName,
        address projectOwner,
        string projectValueProposition,
        uint256 amountToRaise,
        uint256 duration,
        bytes32 projectID,
        bool projectExist,
        uint256 timeCreated,
        uint256 lastProjectCreationTime,
        uint256 projectsCreatedByProjectOwner
    );

    // protocol fees related events:
    event ProtocolFeesWithdrawn(address indexed protocol, uint256 fees);

    // project related events:
    event FundsWithdrawn(address indexed projectOwner, uint256 funds);

    // ----------------------------------------------------------------------- constructor -------------------------------------------------------------------------  //

    // ----------------------------------------------------------------------- modifiers -------------------------------------------------------------------------  //

    // modifiers:

    // this modifier ensures that only users that have contributed to a raise return true and can vote on proposals

    // protocol related modifiers:
    // only protocol functions
    modifier onlyProtocol() {
        // get protocol fee address from core
        address protocolFeeAddress = raiseBoxCore.getProtocolFeeAddress();

        if (msg.sender != protocolFeeAddress) {
            revert CrowdFund_OnlyProtocolCanWithdrawFees();
        }

        _;
    }

    constructor(address raiseBoxCoreAddress) {
        // raiseBoxCore = ICore(raiseBoxCoreAddress);
        raiseBoxStorage = RaiseBoxStorage(raiseBoxCoreAddress);
    }

    // ----------------------------------------------------------------------- functions -------------------------------------------------------------------------  //

    mapping(address projectOwner => uint256 lastProjectCreationTime)
        public i_lastProjectCreation;

    uint256 public constant PER_PROJECT_CREATION_COOLDOWN = 78 weeks; // [1 year and 6 months] before same project can create another raise on raisebox

    /**
     *
     * @param projectName_ name of the project to be created
     * @param valueProposition_ what problem the project is going to solve
     * @param amountToRaise_ amount project wants to raise --in ethers now, usd later
     * @param duration_ duration of the raise -- how long the raise period will last
     */
    function createProject(
        string memory projectName_,
        string memory valueProposition_,
        uint256 amountToRaise_,
        uint256 duration_
    ) public returns (bytes32) {
        // when project is created on raisebox
        uint256 timeCreated;

        // checks that a project cannot create more than one project within 78 weeks
        if (projectCountPerProjectOwner[msg.sender] > 0) {
            if (
                PER_PROJECT_CREATION_COOLDOWN >
                (block.timestamp - i_lastProjectCreation[msg.sender])
            ) {
                revert RaiseBox_createProject_AlreadyHaveALiveProject();
            }
        }

        require(msg.sender != address(0), "zero address cannot host campaign");

        require(bytes(projectName_).length > 0, "Enter valid project name");
        //need to check if project with similar project doesn't already exist

        require(
            bytes(valueProposition_).length > 0,
            "Enter valid problem statement"
        );

        require(amountToRaise_ != 0, "Cannot raise 0 funds");

        require(duration_ != 0, "Enter valid duration");

        require(
            duration_ <= 60 days,
            "Cannot host a raise on raisebox for more than 60 days"
        );
        // max duration is 60 days -- 2 months

        // generate projectID:
        bytes32 projectID = keccak256(
            abi.encode(
                projectName_,
                amountToRaise_,
                timeCreated,
                valueProposition_,
                msg.sender
            )
        );

        bool doesProjectExists = raiseBoxStorage.getProjectExist(projectID);

        if (doesProjectExists) {
            revert RaiseBox_CreateProject_ProjectAlreadyExist();
        }

        timeCreated = block.timestamp;
        
        if (!doesProjectExists) {
            raiseBoxStorage.updateStorage(
                projectID,
                projectName_,
                msg.sender,
                valueProposition_,
                amountToRaise_,
                duration_,
                true,
                timeCreated,
                0,
                0,
                projectCountPerProjectOwner[msg.sender] += 1
            );
        }

        projectIndex++;
        i_lastProjectCreation[msg.sender] = timeCreated;

        // projectIndexToProject[projectIndex] = projectIDToProject[projectID];

        emit RaiseBoxCreateProject_ProjectCreated(
            projectName_,
            msg.sender,
            valueProposition_,
            amountToRaise_,
            duration_,
            projectID,
            !doesProjectExists,
            timeCreated,
            i_lastProjectCreation[msg.sender] = timeCreated,
            projectCountPerProjectOwner[msg.sender]
        );

        return projectID;
    }

    // function calProtocolFees(
    //     bytes32 projectId_
    // ) external returns (uint256 fees) {
    //     // get project amount raised
    //     uint256 amountToRaiseByProject = getProject(projectId_).amountToRaise;

    //     // check if amount project needed to raise have been raised, raise failed
    //     if (
    //         // projectIdToProjects[projectId_].amountRaisedByProject !=
    //         // amountToRaiseByProject
    //         projectIDToProject[projectId_].amountRaisedByProject !=
    //         amountToRaiseByProject
    //     ) {
    //         revert RaiseBox_RaiseFailed();
    //     }
    //     // check if raise succeeded; temporal
    //     // if (projectIdToProjects[projectId_].amountRaisedByProject == 0) {
    //     //     revert RaiseBox_NoContributionsMade();
    //     // }

    //     if (projectIDToProject[projectId_].amountRaisedByProject == 0) {
    //         revert RaiseBox_NoContributionsMade();
    //     }

    //     // cal protocol fees
    //     fees =
    //         (PROTOCOL_FEE *
    //             (projectIDToProject[projectId_].amountRaisedByProject)) /
    //         MAX_PERCENTAGE;

    //     totalProtocolFees += fees;

    //     return fees;
    // }

    // approve Vote for milestone approval and funds withdrawal
    /// @notice protocol counts votes and approves milestone based on highest vote received for or against proposal
    /// @dev Only callable by protocol

    // function approveMilestoneProposal() external onlyProtocol {
    //     VotingState votingState;
    //     require(votingState != VotingState.VOTING_LIVE, "voting has not ended");
    // }

    // Withdraw accumulated protocol fees
    /// @notice Withdraw accumulated protocol fees to the protocol address
    /// @dev Only callable by protocol address

    // function withdrawProtocolFees() external onlyProtocol {
    //     if (totalProtocolFees == 0) {
    //         revert RaiseBox_NoFeesToWithdraw();
    //     }
    //     if (address(protocolFeeAddress) == address(0)) {
    //         revert CrowdFund_ProtocolAddressCannotBeZeroAddress();
    //     }

    //     totalProtocolFees = 0; // Reset before transfer to prevent reentrancy

    //     // Interactions
    //     (bool success, ) = protocolFeeAddress.call{value: totalProtocolFees}(
    //         ""
    //     ); // this should be sent to protocolFees address - will implement
    //     if (!success) {
    //         revert CrowdFund_FeesWithdrawalFailed();
    //     }

    //     emit ProtocolFeesWithdrawn(raiseBoxOwner, totalProtocolFees);
    // }

    // Allow contract to receive ETH
    /// @notice Allow contract to receive ETH directly
    // receive() external payable {}

    // notes of task for commit message:
    // 1. added getter functions
    // 2. added getter function tests
    // 3. tested contribute function

    // if target is not reached within the alloted time then contributors should be refunded their contributions
    // but should protocol should keep fees?

    // function withdrawFundsRaised(
    //     uint256 amountToWithdraw
    // ) external onlyProtocol {
    //     // this function implements withdrawal of raised funds by the projectOwner
    //     // only a project owner can call this function
    //     // emit FundsWithdrawn(projectOwner, amountToWithdraw);
    // }

    // getter functions

    // function getProjectByIndex(
    //     uint256 index
    // ) external view returns (ProjectInfo memory projectInfo) {

    //     if (projectIndexToProject[index].projectOwner == address(0)) {
    //         revert RaiseBox_getProjectByIndex_InvalidProjectIndex();
    //     }
    //     projectInfo = projectIDToProject[projectIndexToProject[index].projectID];

    // }

    // function viewProjectInfo(bytes32 projectId) external  {
    //     ProjectInfo memory projectInfo = this.getProject(projectId);
    //     console.log(
    //         string(
    //             abi.encodePacked(
    //                 "Name: ",
    //                 projectInfo.projectName,
    //                 " | Owner: ",
    //                 Strings.toHexString(uint160(projectInfo.projectOwner), 20),
    //                 " | Problem: ",
    //                 projectInfo.valueProposition,
    //                 " | Amount To Raise: ",
    //                 projectInfo.amountToRaise.toString(),
    //                 " | Duration: ",
    //                 projectInfo.duration.toString(),
    //                 " | ID: ",
    //                 projectInfo.projectID,
    //                 " | Amount Raised: ",
    //                 projectInfo.amountRaisedByProject.toString()
    //             )
    //         )
    //     );
    // }

    // function getProtocolFee() public view returns (uint256) {
    //     return PROTOCOL_FEE;
    // }

    // // this returns the total cummulative fees across proejcts
    // // should be internal and only owner function
    // function getTotalProtocolFees() public view returns (uint256) {
    //     return totalProtocolFees;
    // }

    // function getFeesFromProject(
    //     bytes32 projectId
    // ) external view returns (uint256) {
    //     return ((PROTOCOL_FEE *
    //         (projectIDToProject[projectId].amountRaisedByProject)) /
    //         MAX_PERCENTAGE);
    // }

    // function getProjectOwner(
    //     bytes32 projectId
    // ) external view returns (address) {
    //     return projectIDToProject[projectId].projectOwner;
    // }

    // function updateAmountRaiseByProject(
    //     bytes32 projectId,
    //     uint256 amount
    // ) external {
    //     projectIDToProject[projectId].amountRaisedByProject += amount;
    // }

    // function getProtocolBalance() public view returns (uint256) {
    //     return balanceOf(protocol);
    // }

    // function setProtocol(address payable protocol_) external onlyOwner {
    //     require(protocol_ != protocol, "protocol_ already protocol owner");
    //     require(protocol_ != address(0), "Protocol cannot be zero address");
    //     protocol = protocol_;
    // }

    // function updateRaiseBoxCoreStorage() external override {
    //     ProjectInfo memory projectInfo;

    //     // projectInfo.proposalsHosted += 1;
    // }

    // function getProposals(
    //     address __projectOwner
    // ) public view returns (MileStoneProposalDetails[] memory) {
    //     return proposalByProject[__projectOwner];
    // }

    // function getMilestoneProposalDetails(
    //     address _project
    // ) public view returns (MileStoneProposalDetails[] memory) {
    //     return proposals;
    // }

    /////
}
