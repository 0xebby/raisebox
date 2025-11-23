// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RaiseBox} from "../src/RaiseBoxProjectCreation.sol";

/**
 * @title RaiseBoxCore is the central contract of this protocol
 * @author 0xebby
 * @notice it holds the major storage that all other contracts read and update (authorized updates***)
 * @dev use it's associated interface to get exposed external functions and structs
 */
contract RaiseBoxCore is IRaiseBoxCore, ERC20, Ownable {
    using SafeERC20 for IERC20;


    // total projects on raisebox
    uint256 private raiseBoxProjectCounter;

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

    // projectID (Keccak hash) to projectInfo
    mapping(bytes32 => ProjectInfo) public projectIDToProject;

    // list of projects created on raisebox
    bytes32[] public s_raiseBoxProjectIDs;

    mapping(bytes32 => bool) private IDexists;

    // would be CA of raisebox - project creation contract
    address public raiseBoxCreationContractAddress;
    address public raiseBoxContributionContractAddress;
    address public raiseBoxProposalContractAddress;

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

    function setProjectCreationContractAddress(address contractAddressToSet) external onlyOwner {
        if (contractAddressToSet == address(0)) {
            revert RaiseBoxCore_setProjectCreation_InvalidContract();
        }
        if (raiseBoxCreationContractAddress != address(0)) {
            revert RaiseBoxCore_setProjectCreation_ContractAlreadySet();
        }

        raiseBoxCreationContractAddress = contractAddressToSet;

        emit RaiseBoxCore_ProjectCreationContractSet(raiseBoxCreationContractAddress);
    }

    function setContributionContractAddress(address contractAddressToSet) external onlyOwner {

        if (contractAddressToSet == address(0)) {
            revert RaiseBoxCore_setRaiseContribution_InvalidContract();
        }

        require(raiseBoxContributionContractAddress == address(0), "contribution contract already set");

        raiseBoxContributionContractAddress = contractAddressToSet;
    }

    function setProposalContractAddress(address contractAddressToSet) external onlyOwner {
        require(raiseBoxProposalContractAddress == address(0), "proposal contract already set");

        raiseBoxProposalContractAddress = contractAddressToSet;
    }



    function updateIDsStorage(bytes32 projectId) internal {
        IDexists[projectId] = true;

        emit RaiseBoxCore_IDsStorageSuccessfullyUpdated(IDexists[projectId], projectId);
    }

    /**
     * @notice incrementProjectCount
     * @notice tracks and increases total number of projects on protocol by 1
     * @dev only a project creation event can increment the projectCreationCount
     * @dev only calls from `RaiseBoxProjectCreation.sol` can pass
     */
    function incrementProjectCount() external returns (uint256) {
        if (msg.sender != raiseBoxCreationContractAddress) {
            revert RaiseBoxCore_getRaiseBoxProjectCount_CallNotFromProjectCreation();
        } else {
            return raiseBoxProjectCounter++;
        }
    }

    function updateAmountRaisedByProject(bytes32 projectID, uint256 amount) internal returns (uint256 amountRaised) {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectID];

        projectInfo.amountRaisedByProject += amount;

        projectInfo.amountRaisedByProject;
    }

    function updateProposalsHostedByProject(bytes32 projectId) internal {

        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectId];

        projectInfo.proposalsHosted += 1;
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
            revert RaiseBox_updateStorage_CallNotFromRaiseBoxProjectCreationContract();
        }
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

    function updateAmountRaisedInStorage(bytes32 projectId, uint256 amountRaised) external {
        if (msg.sender == raiseBoxContributionContractAddress) {
            updateAmountRaisedByProject(projectId, amountRaised);
        } else {
            revert RaiseBox_updateStorage_CallNotFromRaiseBoxProjectCreationContract();
        }
    }

    function updateProposalsHostedInStorage(bytes32 projectId) external {
        if (msg.sender == raiseBoxProposalContractAddress) {
            updateProposalsHostedByProject(projectId);
        } else {
            revert NotProposalContract();
        }
    }

    // getters:

    function getIDsFromStorage() external returns (bytes32 id) {
        for (uint256 i = 0; i < s_raiseBoxProjectIDs.length; i++) {
            return s_raiseBoxProjectIDs[i];
        }
    }

    function getProtocol() public view returns (address payable) {
        if (protocol == address(0)) {
            revert RaiseBoxCore_getProtocol_RaiseBoxProtocolUnset();
        }
        return (protocol);
    }

    function getMinimumContribution() public view returns (uint256) {
        return MINIMUM_CONTRIBUTION;
    }

    function getProject(bytes32 projectId) public returns (ProjectInfo memory projectInfo) {
        if (!this.doesProjectExist(projectId)) {
            revert RaiseBox_getProject_InvalidProjectId();
        }
        projectInfo = projectIDToProject[projectId];
    }

    function getAmountToRaise(bytes32 projectId) external view returns (uint256) {
        if (!this.doesProjectExist(projectId)) {
            revert RaiseBox_getProject_InvalidProjectId();
        }
        return projectIDToProject[projectId].amountToRaise;
    }

    function getAmountRaisedByProject(bytes32 projectId) external returns (uint256) {
        if (!this.doesProjectExist(projectId)) {
            revert RaiseBox_getProject_InvalidProjectId();
        }
        return projectIDToProject[projectId].amountRaisedByProject;
    }

    function getProtocolFeeAddress() external view returns (address) {
        return protocolFeeAddress;
    }

    function getProjectCount() external returns (uint256) {
        return raiseBoxProjectCounter;
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

    function doesProjectExist(bytes32 projectID) external view returns (bool) {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectID];

        if (projectInfo.projectExists == true) {
            return true;
        } else {
            return false;
        }
    }

    function getProjectCreator(bytes32 projectId) external view returns (address) {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectId];

        return projectInfo.projectOwner;
    }

    function getOwner() external view returns (address) {
        return Ownable.owner();
    }
}
