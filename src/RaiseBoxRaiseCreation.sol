// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxCreation} from "../src/interfaces/IRaiseBoxCreation.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";
import "../lib/forge-std/src/Test.sol";


/// @title RaiseBoxCreation Contract - This contract allows users to create raises  on RaiseBoxCreation
/// @author 0xebby
/// @notice This contract is part of the RaiseBox crowdfunding platform, enabling raise creation and management, updates core storage (RaiseBoxCore)
/// @dev This contract interacts with RaiseBoxCore for data persistence.

contract RaiseBoxCreation is IRaiseBoxCreation {
    
    IRaiseBoxCore public raiseBoxCore;

    using Strings for uint256;
    using Strings for bytes32;

    // [1 year and 6 months] before same project can create another raise on raisebox
    uint256 public constant PROJECT_LIFESPAN = 60 weeks; // 1 year and 2 months
    uint256 public constant MIN_PROJECT_DURATION = 52 weeks; // min 1 year

    mapping(address => uint16) public raisesCreated;
    mapping(address projectOwner => uint256 lastRaiseCreated) public i_lastRaiseCreated;
    mapping(address => bool) public hasCreatedRaise;
    uint256 private raisesCreatedOnRaiseBox;

    // ----------------------------------------------------------------------- constructor -------------------------------------------------------------------------  //

    constructor(address raiseBoxCoreAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
    }

    function createNewRaise(
        IRaiseBoxCore.ProjectInfo calldata projectInfo
     ) external returns (bytes32 _raiseId) {


        // clean up user input -- projectInfo
        if (projectInfo.projectOwner == address(0)) { revert RaiseBoxErrorsLib.ZeroAddress(); }

        if (!(raiseBoxCore.isVerifiedAndWhiteListed(projectInfo.projectOwner))) {
            revert RaiseBoxErrorsLib.RaiseBoxRaiseCreation_OwnerNotWhiteListed();
        }

        if (projectInfo.projectDuration > PROJECT_LIFESPAN || projectInfo.projectDuration < MIN_PROJECT_DURATION ) {
            revert RaiseBoxErrorsLib.RaiseBoxCreation_createRaise_InvalidProjectDuration();

        }

        if (projectInfo.raiseTarget == 0) { revert RaiseBoxErrorsLib.RaiseBoxCreation_createRaise_CannotRaiseZeroFunds();}

        uint256 timeCreated = block.timestamp;
        

        // generate raiseId:
        bytes32 raiseId = keccak256(abi.encode(projectInfo.projectName, projectInfo.raiseTarget, timeCreated, projectInfo.valueProposition, msg.sender, projectInfo.projectDuration));

        // checks that a project cannot create more than one raise within 78 weeks
        if (raiseBoxCore.getRaiseState(raiseId) == IRaiseBoxCore.RaiseState.CONTRIBUTION || hasCreatedRaise[msg.sender] ) {
            if (PROJECT_LIFESPAN > (block.timestamp - i_lastRaiseCreated[msg.sender])) {
                revert RaiseBoxErrorsLib.RaiseBoxCreation_createRaise_RaiseCreationCooldown();
            }
        }

        raisesCreated[msg.sender] += 1;
        raiseBoxCore.updateRaiseInfo( // updates storage with raiseCreation info
            projectInfo,
            raiseBoxCore.getRaiseDuration(),
            timeCreated,
            0,
            0,
            raisesCreated[msg.sender],
            true,
            raiseId,
            IRaiseBoxCore.RaiseState.CONTRIBUTION
        );
        i_lastRaiseCreated[msg.sender] = timeCreated;
        hasCreatedRaise[msg.sender] = true;
        raisesCreatedOnRaiseBox++;
        
        

        emit RaiseBoxEventsLib.RaiseCreation_RaiseCreated(
            projectInfo.projectName,
            projectInfo.projectOwner,
            projectInfo.valueProposition,
            projectInfo.raiseTarget,
            raiseId,
            timeCreated
        );

        _raiseId = raiseId;

        return _raiseId;

     }  

     function getHasCreatedARaise(address creator) external returns (bool) {
        hasCreatedRaise[creator];
     }




    // /**
    //  *
    //  * @param raiseName_ name of the project to be created
    //  * @param valueProposition_ what problem the project is going to solve
    //  * @param raiseAmount_ amount project wants to raise --in ethers now, usd later
    //  * @param raiseDuration_ duration of the raise -- how long the raise period will last
    //  * @dev 300154 initial gas estimate for createRaise function
    //  * @dev 299980 gas after optimizations
    //  */


    // function createRaise(
    //     string memory raiseName_,
    //     string memory valueProposition_,
    //     uint256 raiseAmount_,
    //     uint256 raiseDuration_
    // ) public returns (bytes32) {
    //     // when raise is created on raisebox
    //     uint256 timeCreated;

    //     // checks that a project cannot create more than one project within 78 weeks
    //     if (raisesCreated[msg.sender] > 0 ) {
    //         if (PROJECT_LIFESPAN > (block.timestamp - i_lastRaiseCreated[msg.sender])) {
    //             revert RaiseBoxCreation_createRaise_RaiseAlreadyActive();
    //         }
    //     }

    //     if (msg.sender == address(0)) {
    //         revert RaiseBoxCreation_createRaise_ZeroAddress();
    //     }

    //     if (bytes(raiseName_).length == 0) {
    //         revert RaiseBoxCreation_createRaise_InvalidProjectName();
    //     }

    //     if (bytes(valueProposition_).length == 0) {
    //         revert RaiseBoxCreation_createRaise_InvalidValueProp();
    //     }

    //     if (raiseAmount_ == 0) {
    //         revert RaiseBoxCreation_createRaise_CannotRaiseZeroFunds();
    //     }

    //     if (raiseDuration_ == 0) {
    //         revert RaiseBoxCreation_createRaise_DurationCannotBeZero();
    //     }

    //     if (raiseDuration_ > PROJECT_LIFESPAN || raiseDuration_ < 52 weeks) {
    //         revert RaiseBoxCreation_createRaise_InvalidDuration();
    //     }

        

    //     // generate raiseId:
    //     bytes32 raiseId = keccak256(abi.encode(raiseName_, raiseAmount_, timeCreated, valueProposition_, msg.sender));
    //     if (raiseBoxCore.getRaiseState(raiseId, msg.sender) != IRaiseBoxCore.RaiseState.CONTRIBUTION) {
    //         revert RaiseCreation_createRaise_RaiseAlreadyExist();
    //     }

    //     bool doesRaiseExist = raiseBoxCore.doesRaiseExist(raiseId);

    //     // if (doesRaiseExist) {
    //     //     revert RaiseCreation_createRaise_RaiseAlreadyExist();
    //     // }

    //     timeCreated = block.timestamp;

    //     if (!doesRaiseExist) {
    //         raiseBoxCore.updateRaiseInfo(
    //             raiseId,
    //             raiseName_,
    //             msg.sender,
    //             valueProposition_,
    //             raiseAmount_,
    //             raiseDuration_,
    //             true,
    //             timeCreated,
    //             0,
    //             0,
    //             raisesCreated[msg.sender] += 1
    //         );
    //     }

    //     i_lastRaiseCreated[msg.sender] = timeCreated;
    //     raiseBoxCore.incrementRaiseCount();
    //     raiseBoxCore.setRaiseState(raiseId, IRaiseBoxCore.RaiseState.CONTRIBUTION, msg.sender);

    //     emit RaiseCreation_RaiseCreated(
    //         raiseName_,
    //         msg.sender,
    //         valueProposition_,
    //         raiseAmount_,
    //         raiseDuration_,
    //         raiseId,
    //         !doesRaiseExist,
    //         timeCreated,
    //         i_lastRaiseCreated[msg.sender] = timeCreated,
    //         raisesCreated[msg.sender]
    //     );

    //     return raiseId;
    // }

    ////////////////////////////////////////////////////////// GETTERS //////////////////////////////////////////////////////////

    function getRaiseCreator(bytes32 raiseId) external returns (address) {
        IRaiseBoxCore._RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId);
        return raiseInfo.projectInfo.projectOwner;
    }

    function viewProjectInfo(bytes32 raiseId) external {
        raiseBoxCore.getRaiseInfo(raiseId);
    }

    function getAllRaisesCreated() external view returns (uint256) {
        return raisesCreatedOnRaiseBox;
    }

    // function calProtocolFees(
    //     bytes32 projectId_
    // ) external returns (uint256 fees) {
    //     // get project amount raised
    //     uint256 amountToRaiseByProject = getProject(projectId_).raiseTarget;

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
