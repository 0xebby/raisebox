// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBox Raise Creation contract
*/

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
    error RaiseCreation_createProject_RaiseAlreadyExist();
    error RaiseBox_getProjectByIndex_InvalidProjectIndex();
    error RaiseBoxCreation_createProject_ActiveRaise();
    error RaiseBoxProjectCreation_createProject_ZeroAddress();
    error RaiseBoxProjectCreation_createProject_InvalidValueProp();
    error RaiseBoxProjectCreation_createProject_CannotRaiseZeroFunds();
    error RaiseBoxProjectCreation_createProject_InvalidDuration();
    error RaiseBoxProjectCreation_createProject_DurationCannotBeZero();
    error RaiseBoxCreation_createProject_InvalidProjectName();

    // raise related errors:
    error RaiseBox_RaiseFailed();

    error RaiseBox_NoContributionsMade();

        event RaiseBoxCreateProject_ProjectCreated(
        string projectName,
        address projectOwner,
        string projectValueProposition,
        uint256 amountToRaise,
        uint256 duration,
        bytes32 projectID,
        bool projectExist,
        uint256 timeCreated,
        uint256 lastRaiseCreated,
        uint256 projectsCreatedByProjectOwner
    );

    // protocol fees related events:
    event ProtocolFeesWithdrawn(address indexed protocol, uint256 fees);

    // project related events:
    event FundsWithdrawn(address indexed projectOwner, uint256 funds);

    function getProjectCreator(bytes32 projectId) external returns (address);
    function viewProjectInfo(bytes32 projectId) external;
}
