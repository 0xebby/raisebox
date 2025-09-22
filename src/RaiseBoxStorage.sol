// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ICore} from "../src/interfaces/ICore.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RaiseBox} from "../src/RaiseBoxProjectCreation.sol";

contract RaiseBoxStorage is ICore, ERC20, Ownable {
    using SafeERC20 for IERC20;

    // MINIMUM_CONTRIBUTION = 0.01 ether; // 1e16
    uint256 public constant MINIMUM_CONTRIBUTION = 0.01 ether;

    uint256 public constant MAX_PERCENTAGE = 100;

    // percent of the amount raised by the project that goes to protocol
    uint256 private constant PROTOCOL_FEE = 2; // 2%

    // protocol address - raisebox
    address payable public protocol;

    // protocol related state variables:
    address private raiseBoxOwner; //0x3989F40a2b256004A2866Ab0805859d30605Ca4a;

    address public protocolFeeAddress = address(0x1); // tentative.

    uint256 public totalProtocolFees;

    address private immutable iRBT; // raise box token
    IERC20 iRBTInstance;

    // errors:

    error RaiseBox_getProject_InvalidProjectId();
    error RaiseBox_RaiseEnded(bytes32);

    error RaiseBoxStorage_updateStorage_wrongCaller();

    // events:

    event RaiseBox_RaisePassed(uint256);

    event StorageUpdatedWithProjectCreationDetails(bytes32);

    // test errors:
    error RaiseBox_updateStorage_NotRaiseBoxContract();
    error InvalidContract();
    error RaiseBox_updateStorage_NotAValidProjectID();

    // projectID (Keccak hash) to projectInfo
    mapping(bytes32 => ProjectInfo) public projectIDToProject;

    // list of projects created on raisebox
    bytes32[] public s_raiseBoxProjectIDs;

    // would be CA of raisebox - project creation contract
    address public raiseBoxCreationContractAddress;
    address public raiseBoxContributionContractAddress;

    // constructor
    // address iRBT_
    constructor() Ownable(msg.sender) ERC20("token", "tokenname") {
        raiseBoxOwner = owner(); // this sets proposal as owner/deployer of crowdfund contract

        // RAISE_BOX_TOKEN =  add faucet contract address here so testers with RAISE_BOX_TOKENs can interact with crowdfund

        // iRBT = iRBT_;
        iRBTInstance = IERC20(iRBT);

        // change before deployment
        protocol = payable(address(0x1));

        // raiseBoxCreationContractAddress = projectCreationContract;
    }

    // function getIDs() external {
    //     s_raiseBoxProjectIDs;
    // }

    function setProjectCreationContractAddress(address contractAddressToSet) external onlyOwner {
        require(raiseBoxCreationContractAddress == address(0), "project creation contract already set");

        raiseBoxCreationContractAddress = contractAddressToSet;
    }

    function setContributionContractAddress(address contractAddressToSet) external onlyOwner {
        require(raiseBoxContributionContractAddress == address(0), "contribution contract already set");

        raiseBoxContributionContractAddress = contractAddressToSet;
    }

    function getProtocol() public view returns (address payable) {
        return (protocol);
    }

    function getMinimumContribution() public view returns (uint256) {
        return MINIMUM_CONTRIBUTION;
    }

    function getProject(bytes32 id) public returns (ProjectInfo memory projectInfo) {
        if (!projectIDToProject[id].projectExists) {
            revert RaiseBox_getProject_InvalidProjectId();
        }
        require(projectIDToProject[id].projectExists != false, "Project does not exist");
        projectInfo = projectIDToProject[id];
    }

    function getAmountToRaise(bytes32 projectId) external view returns (uint256) {
        require(projectIDToProject[projectId].amountToRaise != 0, "amount to raise cannot be 0");
        return projectIDToProject[projectId].amountToRaise;
    }

    function getAmountRaisedByProject(bytes32 projectId_) external returns (uint256) {
        return projectIDToProject[projectId_].amountRaisedByProject;
    }

    function getProtocolFeeAddress() external view returns (address) {
        return protocolFeeAddress;
    }

    // function getProjectMapping(
    //     bytes32 projectID
    // ) external returns (ProjectInfo memory) {
    //     return projectIDToProject[projectID];
    // }

    function getProjectInfo(bytes32 projectID)
        external
        returns (string memory, address, string memory, uint256, uint256, bytes32, bool, uint256, uint256, uint256)
    {
        // get from storage
        ProjectInfo storage projectInfo;
        projectInfo = projectIDToProject[projectID];
        return (
            projectInfo.projectName,
            projectInfo.projectOwner,
            projectInfo.valueProposition,
            projectInfo.amountToRaise,
            projectInfo.duration,
            projectInfo.projectID,
            projectInfo.projectExists,
            projectInfo.timeCreated,
            projectInfo.amountRaisedByProject,
            projectInfo.proposalsHosted
        );
    }

    function getProjectExist(bytes32 projectID) external view returns (bool) {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectID];

        if (projectInfo.projectExists) {
            return true;
        } else {
            return false;
        }
    }

    // function updateProjectInfo(
    //     bytes32 _projectID,
    //     string memory _projectName,
    //     address _projectOwner,
    //     string memory _valueProposition,
    //     uint256 _amountToRaise,
    //     uint256 _duration,
    //     bool _exist,
    //     uint256 _wenProjectCreated,
    //     uint256 _amountRaisedByProject,
    //     uint256 _noOfProposalsHosted
    // ) public {
    //     // get project from storage:
    //     ProjectInfo storage projectInfo;

    //     projectInfo = projectIDToProject[_projectID];

    //     projectInfo.projectName = _projectName;
    //     projectInfo.projectID = _projectID;
    //     projectInfo.projectOwner = _projectOwner;
    //     projectInfo.valueProposition = _valueProposition;
    //     projectInfo.amountToRaise = _amountToRaise;
    //     projectInfo.duration = _duration;
    //     projectInfo.projectExists = _exist;
    //     projectInfo.timeCreated = _wenProjectCreated;
    //     projectInfo.amountRaisedByProject = _amountRaisedByProject;
    //     projectInfo.proposalsHosted = _noOfProposalsHosted;
    // }

    function updateAmountRaisedByProject(bytes32 projectID, uint256 amount) internal returns (uint256 amountRaised) {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectID];

        projectInfo.amountRaisedByProject += amount;

        projectInfo.amountRaisedByProject;
    }

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
    ) external {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectId];

        for (uint256 i = 0; i < s_raiseBoxProjectIDs.length; i++) {
            if (s_raiseBoxProjectIDs[i] != projectId) {
                revert RaiseBox_updateStorage_NotAValidProjectID();
            }
        }

        if (msg.sender == raiseBoxCreationContractAddress) {
            updateProjectCreationInStorage(
                projectId,
                _projectName,
                _projectOwner,
                _valueProposition,
                _amountToRaise,
                _duration,
                _exist,
                _wenProjectCreated,
                _numberOfProjectsCreatedByProjectOwner
            );
        } else if (msg.sender == raiseBoxContributionContractAddress) {
            updateAmountRaisedByProject(projectId, _amountRaisedByProject);
        } else {
            // this calls must always come from a raisebox related contract
            // each of the raisebox contract is allowed access to specific internal functions
            revert RaiseBox_updateStorage_NotRaiseBoxContract();
        }
    }

    function getProjectCreator(bytes32 projectId) external view returns (address) {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectId];

        return projectInfo.projectOwner;
    }

    function updateProjectCreationInStorage(
        bytes32 projectId,
        string memory projectName,
        address projectOwner,
        string memory valueProposition,
        uint256 amountToRaise,
        uint256 duration,
        bool exist,
        uint256 timeCreated,
        uint256 numberOfProjectsCreatedByProjectOwner
    ) internal {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectId];

        //    require (!projectInfo.projectExists, "project with that id already exist");

        projectInfo.projectName = projectName;
        projectInfo.projectID = projectId;
        projectInfo.projectOwner = projectOwner;
        projectInfo.valueProposition = valueProposition;
        projectInfo.amountToRaise = amountToRaise;
        projectInfo.duration = duration;
        projectInfo.projectExists = exist;
        projectInfo.timeCreated = timeCreated;
        projectInfo.numberOfProjectsCreatedByProjectOwner = numberOfProjectsCreatedByProjectOwner;

        emit StorageUpdatedWithProjectCreationDetails(projectId);
    }

    function getOwner() external view returns (address) {
        return Ownable.owner();
    }
}
