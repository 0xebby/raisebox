// version
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


// imports
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";
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


// contract
/**
 * @title RaiseBoxCore is the central contract of this protocol
 * @author 0xebby
 * @dev The core-most contract.
 * @notice it holds the major storage that all other contracts read and update (authorized updates***)
 * @dev use it's associated interface to get exposed external functions and structs
 */
contract RaiseBoxCore is IRaiseBoxCore, ERC20, Ownable {

    // type declaration
    using SafeERC20 for IERC20;



    // State variables
    address private immutable iRBT; // raise box token

    IERC20 iRBTInstance;

    address public raiseBoxContribution; // contribution contract

    address public raiseBoxProposal; // proposal contract

    address public raiseBoxDripHandler; // drip contract

    address public raiseBoxVoting; // voting contract

    address public raiseBoxRaiseCreation; // raise creation contract

    // total projects on raisebox
    uint256 private raiseBoxRaiseCounter;

    // MINIMUM_CONTRIBUTION = 0.1 ether; // 1e17
    uint256 public constant MINIMUM_CONTRIBUTION = 0.1 ether;

    // percent of the amount raised by the project that goes to protocol
    uint256 private constant PROTOCOL_FEE = 15; // 1.5%
    uint256 public constant RAISE_DURATION = 5 weeks; // 1month and 1 week

    // roles
    bytes32 public constant RAISE_CREATION_CONTRACT = keccak256("RAISEBOX_RAISE_CREATION");
    bytes32 public constant CONTRIBUTION_CONTRACT = keccak256("RAISEBOX_CONTRIBUTION");
    bytes32 public constant PROPOSAL_CONTRACT = keccak256("RAISEBOX_PROPOSAL");
    bytes32 public constant VOTING_CONTRACT = keccak256("RAISEBOX_VOTING");
    bytes32 public constant DRIP_HANDLER = keccak256("RAISEBOX_DRIPPER");

    // protocol address - raisebox
    address payable public protocol;

    address private raiseBoxOwner;

    address public protocolFeeAddress = address(0x1); // tentative.

    uint256 public totalProtocolFees;

    // raiseId (Keccak hash) to raiseInfo
    mapping(bytes32 => _RaiseInfo) public raiseInfo;

    // role-based authorization (bytes32 role => (caller => allowed))
    mapping(bytes32 => mapping(address => bool)) public authorizedCallers;

    address[] public whiteListedVerifiedFounders;

    mapping (address => bool) private verifiedFounders;


    mapping(bytes32 => bool) raiseExists;
    mapping(bytes32 => RaiseState) raiseState;
    mapping(bytes32 => uint256) amountRaisedByProject;


    // constructor:
    constructor() Ownable(msg.sender) ERC20("token", "tokenname") {
        raiseBoxOwner = msg.sender; // this sets proposal as owner/deployer of crowdfund contract

        // iRBT = iRBT_;
        iRBTInstance = IERC20(iRBT);

        // change before deployment
        protocol = payable(address(0x1));
    }


    function verifyAndAddToWhitelist(address founder) external onlyOwner() {
        require(founder != address(0), "zero address is forbidden");
        if (verifiedFounders[founder]) { revert RaiseBoxErrorsLib.RaiseBoxCore_AlreadyWhiteListed(founder); }
        whiteListedVerifiedFounders.push(founder);
        verifiedFounders[founder] = true;

        emit RaiseBoxEventsLib.RaiseBoxCore_FounderVerifiedAndAddedToWhiteList(founder);
    }

    // set and grant roles to the various raisebox related contracts:

    function setRaiseCreationContract(address contractAddressToSet) external onlyOwner {
        if (contractAddressToSet == address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseCreation_InvalidCA();
        }
        if (raiseBoxRaiseCreation != address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseCreation_ContractAlreadySet();
        }

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseCreation_InvalidCA();
        }

        raiseBoxRaiseCreation = contractAddressToSet;

        // grantRole(RAISE_CREATION_CONTRACT, contractAddressToSet);
        authorizedCallers[RAISE_CREATION_CONTRACT][contractAddressToSet] = true; // SHOULD EMIT A ROLE GRANTED EVENT -- FORTHCOMING/ EBBY

        emit RaiseBoxEventsLib.RaiseBoxCore_RaiseCreationContractSet(contractAddressToSet);
    }

    function setContributionContract(address contractAddressToSet) external onlyOwner {
        if (contractAddressToSet == address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseContribution_InvalidContract();
        }

        if (raiseBoxContribution != address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseContribution_ContractAlreadySet();
        }

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseContribution_InvalidContract();
        }

        raiseBoxContribution = contractAddressToSet;

        // grantRole(CONTRIBUTION_CONTRACT, contractAddressToSet);
        authorizedCallers[CONTRIBUTION_CONTRACT][contractAddressToSet] = true;

        emit RaiseBoxEventsLib.ContributionContractSet(contractAddressToSet);
    }

    function setProposalContract(address contractAddressToSet) external onlyOwner {
        require(address(raiseBoxProposal) == address(0), "proposal contract already set");

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseCreation_InvalidCA();
        }

        raiseBoxProposal = contractAddressToSet;

        // grantRole(PROPOSAL_CONTRACT, contractAddressToSet);
        authorizedCallers[PROPOSAL_CONTRACT][contractAddressToSet] = true;

        emit RaiseBoxEventsLib.ProposalContractSet(contractAddressToSet);
    }

    function setDripHandlerContract(address contractAddressToSet) external onlyOwner {
        require(address(raiseBoxDripHandler) == address(0), "DRIP_HANDLER contract already set");

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setDripHandler_InvalidContract();
        }

        raiseBoxDripHandler = contractAddressToSet;

        // grantRole(PROPOSAL_CONTRACT, contractAddressToSet);
        authorizedCallers[DRIP_HANDLER][contractAddressToSet] = true;

        emit RaiseBoxEventsLib.DripperContractSet(contractAddressToSet);
    }

    function setVotingContract(address contractAddressToSet) external onlyOwner {
        require(address(raiseBoxVoting) == address(0), "voting contract already set");

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseCreation_InvalidCA();
        }

        raiseBoxVoting = contractAddressToSet;

        // grantRole(VOTING_CONTRACT, contractAddressToSet);
        authorizedCallers[VOTING_CONTRACT][contractAddressToSet] = true;

        emit RaiseBoxEventsLib.VotingContractSet(contractAddressToSet);
    }

     function updateRaiseInfo(
        ProjectInfo calldata _projectInfo,
        uint256 _raiseDuration,
        uint256 _raiseCreationTime,
        uint256 _amountRaisedByProject,
        uint256 _numOfProposalsHosted,
        uint256 _projectRaiseCount,
        bool _raiseExists,
        bytes32 _raiseId,
        RaiseState _raiseState
    ) external {

        if (authorizedCallers[RAISE_CREATION_CONTRACT][msg.sender]) {
            _updateRaiseCreation(
                _projectInfo,
                _raiseId,
                _raiseExists,
                _raiseCreationTime,
                _projectRaiseCount,
                _raiseState
            );
        } else if (authorizedCallers[CONTRIBUTION_CONTRACT][msg.sender]) {
            _updateContributions(_raiseId, _amountRaisedByProject);
            
        } else if (authorizedCallers[PROPOSAL_CONTRACT][msg.sender]) {
            _updateProposalsHostedByProject(_raiseId);
            // this calls must always come from a raisebox related contract
            // each of the raisebox contract is allowed access to specific internal functions
           
        } else if (authorizedCallers[VOTING_CONTRACT][msg.sender]) {
            _updateVotingInfo(_raiseId);
        } 
        
        else {  revert RaiseBoxErrorsLib.RaiseBoxCore_UnAuthorizedCaller(); // call is not from any raiseBox related contract}
    }

    }

    /**
     * @dev allows owner to set accepted token address
     *   @param newTokenAddress the address of the new accepted token
     *   @notice only tokens set here can be used for contributions
     *   @notice raiseBoxFaucet contract (deployed) already exists and drips RBT for testing/testnet use
     */
    function setAcceptedToken(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "invalid address");
        if (!_isContract(newTokenAddress)) revert RaiseBoxErrorsLib.RaiseBoxCore_NotSupportedToken();

        iRBTInstance = IERC20(newTokenAddress);

        emit RaiseBoxEventsLib.RaiseBoxCore_AcceptedTokenSet(newTokenAddress);
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

    function _updateContributions(bytes32 raiseId, uint256 amount) internal {
        _RaiseInfo storage _raiseInfo;

        _raiseInfo = raiseInfo[raiseId];

        _raiseInfo.amountRaisedByProject += amount; // update

        _raiseInfo.raiseState = _updateState(RaiseState.PROPOSAL, raiseId);

        emit RaiseBoxEventsLib.RaiseContributionDetailsUpdated(raiseId, amount);
    }

    function _updateProposalsHostedByProject(bytes32 raiseId) internal {
        _RaiseInfo storage _raiseInfo;

        _raiseInfo = raiseInfo[raiseId];

        
        _raiseInfo.proposalsHosted += 1;

        _raiseInfo.raiseState = _updateState(RaiseState.VOTING, raiseId);

        //  else {
        // _raiseInfo.raiseState = _updateState(RaiseState.PROPOSAL, raiseId);
        // }

        emit RaiseBoxEventsLib.RaiseHostedProposalsUpdated();
       
    }

    function _updateVotingInfo(bytes32 raiseId) internal {
        _RaiseInfo storage _raiseInfo;

        _raiseInfo = raiseInfo[raiseId];

       _raiseInfo.raiseState = _updateState(RaiseState.PROPOSAL, raiseId);

       emit RaiseBoxEventsLib.VotingInfoUpdated();
       
    }

    function _updateState(RaiseState updateToState, bytes32 raiseId) internal returns(RaiseState) {
        RaiseState raiseState = raiseInfo[raiseId].raiseState;

        // RaiseState initialState = _raiseInfo.raiseState;

        if (authorizedCallers[PROPOSAL_CONTRACT][msg.sender] || authorizedCallers[RAISE_CREATION_CONTRACT][msg.sender] || authorizedCallers[CONTRIBUTION_CONTRACT][msg.sender] || authorizedCallers[VOTING_CONTRACT][msg.sender] ) {
            raiseState = updateToState;
        } else {revert RaiseBoxErrorsLib.UnAuthorizedCaller(msg.sender); }

        emit RaiseBoxEventsLib.RaiseBoxCore_updateState_RaiseStateUpdated(raiseInfo[raiseId].raiseState, updateToState);

        return raiseState;

    }

    function _updateRaiseCreation(
        ProjectInfo calldata _projectInfo,
        bytes32 _raiseId,
        bool _raiseExists,
        uint256 _timeCreated,
        uint256 _projectCount,
        RaiseState raiseState

    ) internal {
        _RaiseInfo storage _raiseInfo;

        _raiseInfo = raiseInfo[_raiseId];

        _raiseInfo.projectInfo = _projectInfo;
        _raiseInfo.raiseId = _raiseId;
        _raiseInfo.raiseExists = _raiseExists;
        _raiseInfo.raiseCreationTime = _timeCreated;
        _raiseInfo.projectRaiseCount = _projectCount;
        _raiseInfo.raiseDuration = RAISE_DURATION;
        _raiseInfo.raiseState = _updateState(RaiseState.CONTRIBUTION, _raiseId);
        
        emit RaiseBoxEventsLib.RaiseCreationDetailsUpdated(_raiseId);
    }

    // getters:

    function getRaiseInfo(bytes32 raiseId) external view returns (_RaiseInfo memory) {
        return raiseInfo[raiseId];
    }

    function getRaiseState(bytes32 raiseId) external view returns (RaiseState) {
        return raiseInfo[raiseId].raiseState;

    }

    function isVerifiedAndWhiteListed(address founder) external view returns(bool verified) {
        verified = verifiedFounders[founder];
        return verified;
    }

    function getProtocol() public view returns (address payable) {
        if (protocol == address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_getProtocol_RaiseBoxProtocolUnset();
        }
        return (protocol);
    }

    function getMinimumContribution() public view returns (uint256) {
        return MINIMUM_CONTRIBUTION;
    }

    function getProject(bytes32 raiseId) external view returns (_RaiseInfo memory) {
        if (!this.doesRaiseExist(raiseId)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_getProject_InvalidProjectId();
        }
        return raiseInfo[raiseId];
    }

    function getAmountToRaise(bytes32 raiseId) external view returns (uint256) {
        return this.getProject(raiseId).projectInfo.raiseTarget;
    }

    function getAmtRaisedByProject(bytes32 raiseId) external returns (uint256) {
        return this.getProject(raiseId).amountRaisedByProject;
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

    function doesRaiseExist(bytes32 raiseId) external view returns (bool) {
        _RaiseInfo memory raiseInfo = raiseInfo[raiseId];

        if (raiseInfo.raiseExists) {
            return true;
        }
    }

    function getRaiseCreator(bytes32 raiseId) external view returns (address) {
        return raiseInfo[raiseId].projectInfo.projectOwner;
    }

    function getRaiseBoxOwner() external view returns (address) {
        return raiseBoxOwner;
    }

    function isRaiseCreator(address raiseCreator, bytes32 raiseId) external view returns (bool) {
        _RaiseInfo memory raiseInfo = raiseInfo[raiseId];
        if (raiseInfo.projectInfo.projectOwner == raiseCreator) {
            return true;
        }
      }

    function isAuthorizedCaller(bytes32 role, address caller) external returns (bool) {
        return authorizedCallers[role][caller];
    }

    function getRaiseDuration() external view returns (uint256) {
        return RAISE_DURATION;
    }
}

