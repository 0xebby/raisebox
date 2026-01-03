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
    uint256 public constant MIN_PROJECT_DURATION = 26 weeks; // min 6 months

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
        if (msg.sender == address(0)) { revert RaiseBoxErrorsLib.RaiseBox_ZeroAddressNotAllowed(); }

        if (!(raiseBoxCore.isVerifiedAndWhiteListed(msg.sender))) {
            revert RaiseBoxErrorsLib.RaiseBoxRaiseCreation_OwnerNotWhiteListed();
        }

        if (
            bytes(projectInfo.projectName).length <= 0 || 
            bytes(projectInfo.projectName).length > type(uint8).max
            ) {revert("invalid project name length");}

        if (
            bytes(projectInfo.valueProposition).length <= 0 || 
            bytes(projectInfo.valueProposition).length > type(uint256).max
            ) {revert("invalid valueProposition length");}

        if (
            projectInfo.projectDuration > PROJECT_LIFESPAN || 
            projectInfo.projectDuration < MIN_PROJECT_DURATION 
            ) {
            revert RaiseBoxErrorsLib.RaiseBoxCreation_createRaise_InvalidProjectDuration();

        }

        if (projectInfo.raiseTarget == 0) 
        { revert RaiseBoxErrorsLib.RaiseBoxCreation_createRaise_CannotRaiseZeroFunds();}

        uint256 timeCreated = block.timestamp;
        

        // generate raiseId:
        bytes32 raiseId = keccak256(abi.encode(projectInfo.projectName, projectInfo.raiseTarget, timeCreated, projectInfo.valueProposition, msg.sender, projectInfo.projectDuration));

        // checks that a project cannot create more than one raise within 78 weeks
        if (hasCreatedRaise[msg.sender] ) {
            if (PROJECT_LIFESPAN > (block.timestamp - i_lastRaiseCreated[msg.sender])) {
                revert RaiseBoxErrorsLib.RaiseBoxCreation_createRaise_RaiseCreationCooldown();
            }
        }

        raisesCreated[msg.sender] += 1;
        raiseBoxCore.updateRaiseInfo( // updates storage with raiseCreation info
            projectInfo,
            timeCreated,
            0,
            true,
            raiseId,
            msg.sender,
            0,
            0,
            0
        );
        i_lastRaiseCreated[msg.sender] = timeCreated;
        hasCreatedRaise[msg.sender] = true;
        raisesCreatedOnRaiseBox++;        
        

        emit RaiseBoxEventsLib.RaiseCreation_RaiseCreated(
            projectInfo.projectName,
            msg.sender,
            projectInfo.valueProposition,
            projectInfo.raiseTarget,
            raiseId,
            timeCreated
        );

        _raiseId = raiseId;

        return _raiseId;

     }  

     function getHasCreatedARaise(address creator) external view returns (bool) {
        hasCreatedRaise[creator];
     }



    ////////////////////////////////////////////////////////// GETTERS //////////////////////////////////////////////////////////

    function getRaiseCreator(bytes32 raiseId) external view returns (address) {
        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId);
        return raiseInfo.raiseCreationInfo.raiseOwner;
    }

    function getAllRaisesCreated() external view returns (uint256) {
        return raisesCreatedOnRaiseBox;
    }

    // function calProtocolFees(
    //     bytes32 projectId_
    // ) external returns (uint256 fees) {
    //     // get project amount raised
    //     uint256 amountToRaiseByProject = getRaiseInfo(projectId_).raiseTarget;

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
