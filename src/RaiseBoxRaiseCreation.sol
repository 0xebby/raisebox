// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxCreation} from "../src/interfaces/IRaiseBoxCreation.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";

/// @title RaiseBoxCreation Contract - This contract allows users to create raises  on RaiseBox
/// @author 0xebby
/// @notice This contract is part of the RaiseBox crowdfunding platform, enabling raise creation and management, updates core storage (RaiseBoxCore)
/// @dev This contract interacts with RaiseBoxCore for data persistence.

contract RaiseBox is IRaiseBoxCreation {
    // raiseBoxCore interface that exposes methods, events and errors from raiseBoxCore contract
    IRaiseBoxCore public raiseBoxCore;

    using Strings for uint256;
    using Strings for bytes32;

    // [1 year and 6 months] before same project can create another raise on raisebox
    uint256 public constant PER_PROJECT_CREATION_COOLDOWN = 78 weeks;

    uint256 public projectIndex;

    mapping(address => uint16) public raisesCreated;
    mapping(address projectOwner => uint256 lastRaiseCreated) public i_lastRaiseCreated;



    // ----------------------------------------------------------------------- constructor -------------------------------------------------------------------------  //

    constructor(address raiseBoxCoreAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
    }

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


    /**
     *
     * @param projectName_ name of the project to be created
     * @param valueProposition_ what problem the project is going to solve
     * @param raiseAmount_ amount project wants to raise --in ethers now, usd later
     * @param raiseDuration_ duration of the raise -- how long the raise period will last
     * @dev 300154 initial gas estimate for createRaise function
     * @dev 299980 gas after optimizations
     */
    function createRaise(
        string memory projectName_,
        string memory valueProposition_,
        uint256 raiseAmount_,
        uint256 raiseDuration_
    ) public returns (bytes32) {
        // when project is created on raisebox
        uint256 timeCreated;

        // checks that a project cannot create more than one project within 78 weeks
        if (raisesCreated[msg.sender] > 0) {
            if (PER_PROJECT_CREATION_COOLDOWN > (block.timestamp - i_lastRaiseCreated[msg.sender])) {
                revert RaiseBoxCreation_createProject_ActiveRaise();
            }
        }

        // require(msg.sender != address(0), "zero address cannot host campaign");
        if (msg.sender == address(0)) {
            revert RaiseBoxProjectCreation_createProject_ZeroAddress();
        }

        // require(bytes(projectName_).length > 0, "Enter valid project name");
        if (bytes(projectName_).length == 0) {
            revert RaiseBoxCreation_createProject_InvalidProjectName();
        }

        // require(bytes(valueProposition_).length > 0, "Enter valid problem statement");
        if (bytes(valueProposition_).length == 0) {
            revert RaiseBoxProjectCreation_createProject_InvalidValueProp();
        }

        // require(raiseAmount_ != 0, "Cannot raise 0 funds");
        if (raiseAmount_ == 0) {
            revert RaiseBoxProjectCreation_createProject_CannotRaiseZeroFunds();
        }

        // require(raiseDuration_ != 0, "Enter valid duration");
        if (raiseDuration_ == 0) {
            revert RaiseBoxProjectCreation_createProject_DurationCannotBeZero();
        }

        // max duration is 60 days -- 2 months 78 weeks 1 year/6months
        if (raiseDuration_ > PER_PROJECT_CREATION_COOLDOWN || raiseDuration_ < 52 weeks) {
            revert RaiseBoxProjectCreation_createProject_InvalidDuration();
        }

        // generate projectID:
        bytes32 projectID =
            keccak256(abi.encode(projectName_, raiseAmount_, timeCreated, valueProposition_, msg.sender));

        bool doesProjectExists = raiseBoxCore.doesProjectExist(projectID);

        if (doesProjectExists) {
            revert RaiseCreation_createProject_RaiseAlreadyExist();
        }

        timeCreated = block.timestamp;

        if (!doesProjectExists) {
            raiseBoxCore.updateStorage(
                projectID,
                projectName_,
                msg.sender,
                valueProposition_,
                raiseAmount_,
                raiseDuration_,
                true,
                timeCreated,
                0,
                0,
                raisesCreated[msg.sender] += 1
            );
        }

        projectIndex++;
        i_lastRaiseCreated[msg.sender] = timeCreated;
        raiseBoxCore.incrementRaiseCount();

        // projectIndexToProject[projectIndex] = projectIDToProject[projectID];

        emit RaiseBoxCreateProject_ProjectCreated(
            projectName_,
            msg.sender,
            valueProposition_,
            raiseAmount_,
            raiseDuration_,
            projectID,
            !doesProjectExists,
            timeCreated,
            i_lastRaiseCreated[msg.sender] = timeCreated,
            raisesCreated[msg.sender]
        );

        return projectID;
    }

    ////////////////////////////////////////////////////////// GETTERS //////////////////////////////////////////////////////////

    function getProjectCreator(bytes32 projectId) external returns (address) {
        (, address projectCreator,,,,,,,,,) = raiseBoxCore.getProjectInfo(projectId);
        return projectCreator;
    }

    function viewProjectInfo(bytes32 projectId) external {
        raiseBoxCore.getProjectInfo(projectId);
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

}
