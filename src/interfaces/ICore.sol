// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICore {
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

    // this function updates the general raiseBox Storage
    // function updateStorage(bytes32 projectId) external virtual;

    function getProtocol() external returns (address payable);

    function getMinimumContribution() external view returns (uint256);

    function getAmountRaisedByProject(bytes32 projectId_) external returns (uint256);

    function getProtocolFeeAddress() external view returns (address);

    function getProject(bytes32 id) external returns (ProjectInfo memory projectInfo);

    function getProjectInfo(bytes32 projectID)
        external
        returns (string memory, address, string memory, uint256, uint256, bytes32, bool, uint256, uint256, uint256);

    function getProjectExist(bytes32 projectID) external returns (bool);

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

    function getOwner() external view returns (address);
}
