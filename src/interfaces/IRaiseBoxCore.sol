// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Note: this is the interface for the RaiseBox Core contract
*/

interface IRaiseBoxCore {
    struct ProjectInfo {
        string projectName;
        address projectOwner;
        string valueProposition;
        uint256 amountToRaise;
        uint256 duration;
        bytes32 projectID;
        bool projectExists;
        uint256 timeCreated;
        uint256 amountRaisedByProject;
        uint256 proposalsHosted;
        uint256 numberOfProjectsCreatedByProjectOwner;
    }

    // errors:

    error RaiseBox_getProject_InvalidProjectId();
    error RaiseBox_RaiseEnded(bytes32);

    error RaiseBoxCore_updateStorage_wrongCaller();
    error RaiseBoxCore_getRaiseBoxProjectCount_CallNotFromProjectCreation();

    // events:

    event RaiseBox_RaisePassed(uint256 amountToRaise, uint256 amountRaised);

    event StorageUpdatedWithProjectCreationDetails(bytes32);

    event RaiseBoxCore_IDsStorageSuccessfullyUpdated(bool IDexists, bytes32 projectId);

    event RaiseBoxCore_ProjectCreationContractSet(address contractAddress);

    // test errors:
    error RaiseBox_updateStorage_CallNotFromRaiseBoxProjectCreationContract();
    error InvalidContract();
    error RaiseBox_updateStorage_NotAValidProjectID();
    error RaiseBoxCore_getProtocol_RaiseBoxProtocolUnset();
    error RaiseBoxCore_setProjectCreation_InvalidContract();
    error RaiseBoxCore_setProjectCreation_ContractAlreadySet();
    error RaiseBoxCore_setRaiseContribution_InvalidContract();
    error NotProposalContract();

    // this function updates the general raiseBox Storage
    // function updateStorage(bytes32 projectId) external virtual;

    function getProjectCount() external returns (uint256);

    function getProtocol() external returns (address payable);

    function getMinimumContribution() external view returns (uint256);

    function getAmountRaisedByProject(bytes32 projectId_) external returns (uint256);

    function getProtocolFeeAddress() external view returns (address);

    function getProject(bytes32 id) external returns (ProjectInfo memory projectInfo);

    function getProjectInfo(bytes32 projectID)
        external
        returns (string memory, address, string memory, uint256, uint256, bytes32, bool, uint256, uint256, uint256, uint256);

    function doesProjectExist(bytes32 projectID) external returns (bool);

    function getAmountToRaise(bytes32 projectId) external returns (uint256);

    function updateStorage(
        bytes32 projectId,
        string memory _projectName,
        address _projectOwner,
        string memory _valueProposition,
        uint256 _amountToRaise,
        uint256 _duration,
        bool _exist,
        uint256 _wenProjectCreated,
        uint256 _amountRaisedByProject,
        uint256 _noOfProposalsHosted,
        uint256 _numberOfProjectsCreatedByProjectOwner
    ) external;

    function updateAmountRaisedInStorage(bytes32 projectId, uint256 amountRaised) external;

    function updateNumOfProposals(bytes32 projectId) external;

    function getOwner() external view returns (address);
}
