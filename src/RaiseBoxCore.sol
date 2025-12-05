// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {IRaiseBoxProposal} from "src/interfaces/IRaiseBoxProposal.sol";
import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";
import {IRaiseBoxCreation} from "src/interfaces/IRaiseBoxCreation.sol";



/**
 * @title RaiseBoxCore is the central contract of this protocol
 * @author 0xebby
 * @notice it holds the major storage that all other contracts read and update (authorized updates***)
 * @dev use it's associated interface to get exposed external functions and structs
 */
contract RaiseBoxCore is IRaiseBoxCore, ERC20, Ownable {
    address private immutable iRBT; // raise box token

    IERC20 iRBTInstance;

    using SafeERC20 for IERC20;


    // contracts references via interfaces:
    address public raiseBoxContribution; // contribution contract

    // IRaiseBoxContribution raiseBoxContribution;

    address public raiseBoxProposal; // proposal contract

    address public raiseBoxDripHandler; // drip contract

    address public raiseBoxVoting; // voting contract

    address public raiseBoxRaiseCreation; // raise creation contract

    // total projects on raisebox
    uint256 private raiseBoxRaiseCounter;

    // MINIMUM_CONTRIBUTION = 0.01 ether; // 1e16
    uint256 public constant MINIMUM_CONTRIBUTION = 0.01 ether;

    // percent of the amount raised by the project that goes to protocol
    uint256 private constant PROTOCOL_FEE = 2; // 2%

    // protocol address - raisebox
    address payable public protocol;

    // protocol related state variables:
    address private raiseBoxOwner; //0x3989F40a2b256004A2866Ab0805859d30605Ca4a;

    address public protocolFeeAddress = address(0x1); // tentative.

    uint256 public totalProtocolFees;

    // projectID (Keccak hash) to projectInfo
    mapping(bytes32 => ProjectInfo) public projectIDToProject;


    // role-based authorization (bytes32 role => (caller => allowed))
    mapping(bytes32 => mapping(address => bool)) public authorizedCallers;

    bytes32 public constant RAISE_CREATOR = keccak256("RAISEBOX_RAISE_CREATION");
    bytes32 public constant CONTRIBUTOR = keccak256("RAISEBOX_CONTRIBUTION");
    bytes32 public constant PROPOSAL_HOST = keccak256("RAISEBOX_PROPOSAL");
    bytes32 public constant VOTER = keccak256("RAISEBOX_VOTING");
    bytes32 public constant DRIPPER = keccak256("RAISEBOX_DRIPPER");

    // constructor:
    constructor() Ownable(msg.sender) ERC20("token", "tokenname") {
        raiseBoxOwner = msg.sender; // this sets proposal as owner/deployer of crowdfund contract

        // iRBT = iRBT_;
        iRBTInstance = IERC20(iRBT);

        // change before deployment
        protocol = payable(address(0x1));
    }

    /**
     * @dev Returns true if `account` is a contract.
     * NOTE: It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract. Among other
     * things, `_isContract` will return false for the following types of addresses:
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     */
    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    // set and grant roles to the various raisebox related contracts:


    function setRaiseCreationContract(address contractAddressToSet) external onlyOwner {
        if (contractAddressToSet == address(0)) {
            revert RaiseBoxCore_setRaiseCreation_InvalidCA();
        }
        if (raiseBoxRaiseCreation != address(0)) {
            revert RaiseBoxCore_setRaiseCreation_ContractAlreadySet();
        }

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxCore_setRaiseCreation_InvalidCA();
        }

        raiseBoxRaiseCreation = contractAddressToSet;

        // grantRole(RAISE_CREATOR, contractAddressToSet);
        authorizedCallers[RAISE_CREATOR][contractAddressToSet] = true;

        emit RaiseBoxCore_RaiseCreationContractSet(contractAddressToSet);
    }

    function setContributionContract(address contractAddressToSet) external onlyOwner {
        if (contractAddressToSet == address(0)) {
            revert RaiseBoxCore_setRaiseContribution_InvalidContract();
        }

        if (raiseBoxContribution != address(0)) {
            revert RaiseBoxCore_setRaiseContribution_ContractAlreadySet();
        }

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxCore_setRaiseContribution_InvalidContract();
        }

        raiseBoxContribution = contractAddressToSet;

        // grantRole(CONTRIBUTOR, contractAddressToSet);
        authorizedCallers[CONTRIBUTOR][contractAddressToSet] = true;

        emit ContributionContractSet(contractAddressToSet);
    }



    function setProposalContract(address contractAddressToSet) external onlyOwner {
        require(address(raiseBoxProposal) == address(0), "proposal contract already set");

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxCore_setRaiseCreation_InvalidCA();
        }

        raiseBoxProposal = contractAddressToSet;

        // grantRole(PROPOSAL_HOST, contractAddressToSet);
        authorizedCallers[PROPOSAL_HOST][contractAddressToSet] = true;

        emit ProposalContractSet(contractAddressToSet);
    }



    function setDripHandlerContract(address contractAddressToSet) external onlyOwner {
        require(address(raiseBoxDripHandler) == address(0), "dripper contract already set");

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxCore_setDripHandler_InvalidContract();
        }

        raiseBoxDripHandler = contractAddressToSet;

        // grantRole(PROPOSAL_HOST, contractAddressToSet);
        authorizedCallers[DRIPPER][contractAddressToSet] = true;

        emit DripperContractSet(contractAddressToSet);
    }

    function setVotingContract(address contractAddressToSet) external onlyOwner {
        require(address(raiseBoxVoting) == address(0), "voting contract already set");

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxCore_setRaiseCreation_InvalidCA();
        }

        raiseBoxVoting = contractAddressToSet;

        // grantRole(VOTER, contractAddressToSet);
        authorizedCallers[VOTER][contractAddressToSet] = true;

        emit VotingContractSet(contractAddressToSet);
    }

    /**
     * @notice incrementRaiseCount
     * @notice tracks and increases total number of projects on protocol by 1
     * @dev only a project creation event can increment the projectCreationCount
     * @dev only calls from `RaiseBoxCreation.sol` can pass
     */
    function incrementRaiseCount() external {
        if (!authorizedCallers[RAISE_CREATOR][msg.sender]) {
            revert RaiseBoxCore_NotAuthorized();
        }
        raiseBoxRaiseCounter++;
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

        if (authorizedCallers[RAISE_CREATOR][msg.sender]) {
            updateRaiseCreationStorage(
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
        } else if (authorizedCallers[CONTRIBUTOR][msg.sender]) {
            updateAmountRaisedByProject(projectId, _amountRaisedByProject);
        } else {
            // this calls must always come from a raisebox related contract
            // each of the raisebox contract is allowed access to specific internal functions
            revert RaiseBoxCore_UnAuthorizedCaller();
        }
    }

    function updateRaiseCreationStorage(
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

        emit RaiseCreationDetailsUpdated(projectId);
    }

    function updateAmountRaisedInStorage(bytes32 projectId, uint256 amountRaised) external {
        if (!authorizedCallers[CONTRIBUTOR][msg.sender]) {
            revert RaiseBoxCore_NotAuthorized();
        }
        updateAmountRaisedByProject(projectId, amountRaised);

        emit AmountRaisedUpdateSuccessful();
    }

    function updateNumOfProposals(bytes32 projectId) external {
        if (!authorizedCallers[PROPOSAL_HOST][msg.sender]) {
            revert RaiseBoxCore_NotAuthorized();
        }
        updateProposalsHostedByProject(projectId);

        emit RaiseHostedProposalsUpdated();
    }

    // getters:

    function getProtocol() public view returns (address payable) {
        if (protocol == address(0)) {
            revert RaiseBoxCore_getProtocol_RaiseBoxProtocolUnset();
        }
        return (protocol);
    }

    // // ---- Role management (owner-only) ----
    // function grantRole(bytes32 role, address account) public override {
    //     require(account != address(0), "invalid account");
    //     require(_isContract(account), "account not a contract");
    //     authorizedCallers[role][account] = true;
    //     _grantRole(role, account);
    // }

    // function revokeRole(bytes32 role, address account) public override {
    //     require(account != address(0), "invalid account");
    //     authorizedCallers[role][account] = false;
    //     _revokeRole(role, account);

    // }

    function getMinimumContribution() public view returns (uint256) {
        return MINIMUM_CONTRIBUTION;
    }

    function getProject(bytes32 projectId) external view returns (ProjectInfo memory projectInfo) {
        if (!this.doesProjectExist(projectId)) {
            revert RaiseBoxCore_getProject_InvalidProjectId();
        }
        projectInfo = projectIDToProject[projectId];
    }

    function getAmountToRaise(bytes32 projectId) external view returns (uint256) {
        return this.getProject(projectId).amountToRaise;
    }

    function getAmtRaisedByProject(bytes32 projectId) external returns (uint256) {
        return this.getProject(projectId).amountRaisedByProject;
    }

    function getProtocolFeeAddress() external view returns (address) {
        return protocolFeeAddress;
    }

    function getRaiseCount() external returns (uint256) {
        return raiseBoxRaiseCounter;
    }

    function getAcceptedToken() external view returns (address) {
        return iRBT;
    }

    /**
     * @dev allows owner to set accepted token address
     *   @param newTokenAddress the address of the new accepted token
     *     @notice only tokens set here can be used for contributions
     *     @notice raiseBoxFaucet contract (deployed) already exists and drips RBT for testing/testnet use
     */
    function setAcceptedToken(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "invalid address");
        if (!_isContract(newTokenAddress)) revert RaiseBoxCore_NotSupportedToken();

        iRBTInstance = IERC20(newTokenAddress);

        emit RaiseBoxCore_AcceptedTokenSet(newTokenAddress);
    }

    function getProjectInfo(bytes32 projectID)
        external
        returns (
            string memory,
            address,
            string memory,
            uint256,
            uint256,
            bytes32,
            bool,
            uint256,
            uint256,
            uint256,
            uint256
        )
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
            projectInfo.proposalsHosted,
            projectInfo.numberOfProjectsCreatedByProjectOwner
        );
    }

    function doesProjectExist(bytes32 projectID) external view returns (bool) {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectID];

        if (projectInfo.projectExists) {
            return true;
        }
    }

    function getRaiseCreator(bytes32 projectId) external view returns (address) {
        ProjectInfo storage projectInfo;

        projectInfo = projectIDToProject[projectId];

        return projectInfo.projectOwner;
    }

    function getRaiseBoxOwner() external view returns (address) {
        return raiseBoxOwner;
    }

    // get all the set contracts from above:

    function getRaiseCreationContract() external view returns (address) {
        return (raiseBoxRaiseCreation);
    }

    function getContributionContract() external view returns (address) {
        return address(raiseBoxContribution);
    }

    function getProposalContract() external view returns (address) {
        return raiseBoxProposal;
    }

    function getDripHandlerContract() external view returns (address) {
        return raiseBoxDripHandler;
    }

    function getVotingContract() external view returns (address) {
        return raiseBoxVoting;
    }

    function isAuthorizedCaller(bytes32 role, address caller) external returns (bool) {
        return authorizedCallers[role][caller];
    }


}
