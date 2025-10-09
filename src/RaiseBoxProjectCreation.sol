// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {RaiseBoxVoting} from "../src/RaiseBoxVoting.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {RaiseBoxFaucet} from "/home/ebby/contracts-2025/crowdfund-faucet-contract/src/RaiseBoxFaucet.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {RaiseBoxStorage} from "../src/RaiseBoxStorage.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";

/// @title RaiseBoxProjectCreation Contract - This contract allows users to create crowdfunding projects on RaiseBox
/// @author 0xcoda
/// @notice This contract is part of the RaiseBox crowdfunding platform, enabling project creation and management, updates core storage (RaiseBoxStorage)
/// @dev This contract interacts with RaiseBoxStorage for data persistence.

contract RaiseBox is IRaiseBoxProjectCreation {
    // central contract that holds main storage of raisebox and it's interface
    IRaiseBoxCore public raiseBoxCore;
    RaiseBoxStorage public raiseBoxStorage;

    using Strings for uint256;
    using Strings for bytes32;

    // ----------------------------------------------------------------------- state variables -------------------------------------------------------------------------  //

    // raisebox project creation related state variables:

    // ----------------------------------------------------------------------- constants -------------------------------------------------------------------------  //

    // 51% of contributors vote required for a proposal to pass and  10% funds released
    uint256 private constant PROPOSAL_APPROVAL_PERCENTAGE = 51;

    // [1 year and 6 months] before same project can create another raise on raisebox
    uint256 public constant PER_PROJECT_CREATION_COOLDOWN = 78 weeks;

    // ----------------------------------------------------------------------- structs -------------------------------------------------------------------------  //

    // uint256 public projectIDCounter;

    // mapping(uint256 => ProjectInfo) public projectIndexToProject;

    uint256 public projectIndex;

    mapping(address => uint16) public projectCountPerProjectOwner;
    mapping(address projectOwner => uint256 lastProjectCreationTime) public i_lastProjectCreation;

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
    error RaiseBoxProjectCreation_createProject_ProjectAlreadyExist();
    error RaiseBox_getProjectByIndex_InvalidProjectIndex();
    error RaiseBox_createProject_AlreadyHaveLiveProject();
    error RaiseBoxProjectCreation_createProject_ZeroAddress();
    error RaiseBoxProjectCreation_createProject_InvalidValueProp();
    error RaiseBoxProjectCreation_createProject_CannotRaiseZeroFunds();
    error RaiseBoxProjectCreation_createProject_DurationAboveAllowed();
    error RaiseBoxProjectCreation_createProject_DurationCannotBeZero();

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

    constructor(address raiseBoxCoreAddress) {
        // raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
        raiseBoxStorage = RaiseBoxStorage(raiseBoxCoreAddress);
    }

    // ----------------------------------------------------------------------- modifiers -------------------------------------------------------------------------  //

    // modifiers:

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

    // ----------------------------------------------------------------------- functions -------------------------------------------------------------------------  //

    /**
     *
     * @param projectName_ name of the project to be created
     * @param valueProposition_ what problem the project is going to solve
     * @param amountToRaise_ amount project wants to raise --in ethers now, usd later
     * @param duration_ duration of the raise -- how long the raise period will last
     * @dev 300154 initial gas estimate for createProject function
     * @dev 299980 gas after optimizations
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
            if (PER_PROJECT_CREATION_COOLDOWN > (block.timestamp - i_lastProjectCreation[msg.sender])) {
                revert RaiseBox_createProject_AlreadyHaveLiveProject();
            }
        }

        // require(msg.sender != address(0), "zero address cannot host campaign");
        if (msg.sender == address(0)) {
            revert RaiseBoxProjectCreation_createProject_ZeroAddress();
        }

        // require(bytes(projectName_).length > 0, "Enter valid project name");
        if (bytes(projectName_).length == 0) {
            revert RaiseBoxProjectCreation_createProject_ProjectAlreadyExist();
        }

        // require(bytes(valueProposition_).length > 0, "Enter valid problem statement");
        if (bytes(valueProposition_).length == 0) {
            revert RaiseBoxProjectCreation_createProject_InvalidValueProp();
        }

        // require(amountToRaise_ != 0, "Cannot raise 0 funds");
        if (amountToRaise_ == 0) {
            revert RaiseBoxProjectCreation_createProject_CannotRaiseZeroFunds();
        }

        // require(duration_ != 0, "Enter valid duration");
        if (duration_ == 0) {
            revert RaiseBoxProjectCreation_createProject_DurationCannotBeZero();
        }

        // require(duration_ <= 60 days, "Cannot host a raise on raisebox for more than 60 days");
        // max duration is 60 days -- 2 months
        if (duration_ > 60 days) {
            revert RaiseBoxProjectCreation_createProject_DurationAboveAllowed();
        }

        // generate projectID:
        bytes32 projectID =
            keccak256(abi.encode(projectName_, amountToRaise_, timeCreated, valueProposition_, msg.sender));

        bool doesProjectExists = raiseBoxStorage.getProjectExist(projectID);

        if (doesProjectExists) {
            revert RaiseBoxProjectCreation_createProject_ProjectAlreadyExist();
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
        raiseBoxStorage.incrementProjectCount();

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

    ////////////////////////////////////////////////////////// GETTERS //////////////////////////////////////////////////////////

    function getProjectCreator(bytes32 projectId) external returns (address) {
        (, address projectCreator,,,,,,,,) = raiseBoxStorage.getProjectInfo(projectId);
        return projectCreator;
    }

    function viewProjectInfo(bytes32 projectId) external {
        raiseBoxStorage.getProjectInfo(projectId);
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
