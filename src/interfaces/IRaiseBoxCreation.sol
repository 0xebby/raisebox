// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBoxCreation Raise Creation contract
*/

import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";

interface IRaiseBoxCreation {
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
    error RaiseCreation_createRaise_RaiseAlreadyExist();
    error RaiseBox_getProjectByIndex_InvalidProjectIndex();
    error RaiseBoxCreation_createRaise_RaiseAlreadyActive();
    error RaiseBoxCreation_createRaise_ZeroAddress();
    error RaiseBoxCreation_createRaise_InvalidValueProp();
    error RaiseBoxCreation_createRaise_CannotRaiseZeroFunds();
    error RaiseBoxCreation_createRaise_InvalidDuration();
    error RaiseBoxCreation_createRaise_DurationCannotBeZero();
    error RaiseBoxCreation_createRaise_InvalidProjectName();

    error RaiseBoxRaiseCreation_OwnerNotWhiteListed();

    // raise related errors:
    error RaiseBox_RaiseFailed();

    error RaiseBox_NoContributionsMade();


    event RaiseCreation_RaiseCreated(
        string projectName,
        address projectOwner,
        string projectValueProposition,
        uint256 raiseTarget,
        uint256 duration,
        bytes32 raiseId,
        bool projectExist,
        uint256 timeCreated,
        uint256 lastRaiseCreated,
        uint256 projectsCreatedByProjectOwner
    );

    // protocol fees related events:
    event ProtocolFeesWithdrawn(address indexed protocol, uint256 fees);

    // project related events:
    event FundsWithdrawn(address indexed projectOwner, uint256 funds);

    function getRaiseCreator(bytes32 raiseId) external returns (address);
    function viewProjectInfo(bytes32 raiseId) external;
        function getHasCreatedARaise(address creator) external returns (bool);

}
