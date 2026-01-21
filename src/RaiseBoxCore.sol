// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


// imports
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {IRaiseBoxProposal} from "src/interfaces/IRaiseBoxProposal.sol";
import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";
import {IRaiseBoxCreation} from "src/interfaces/IRaiseBoxCreation.sol";
import "../lib/forge-std/src/Test.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";


/**
 * @title RaiseBoxCore is the central contract of this protocol
 * @author 0xebby
 * @dev The core-most contract.
 * @notice it holds the major storage that all other contracts read and update (authorized updates***)
 * @dev use it's associated interface to get exposed external functions and structs
 */
contract RaiseBoxCore is IRaiseBoxCore, ERC20, Ownable, AutomationCompatibleInterface  {

    // State variables

    address private immutable iRBT;

    IERC20 iRBTInstance;

    address public raiseBoxContribution;

    address public raiseBoxProposal; 

    address public raiseBoxDripHandler; 

    address public raiseBoxVoting; 

    address public raiseBoxRaiseCreation; 

    // MINIMUM_CONTRIBUTION = 0.1 ether; // 1e17 // or dollar eq
    uint256 public constant MINIMUM_CONTRIBUTION = 0.1 ether;

    // percent of the amount raised by the project that goes to protocol
    uint256 private constant PROTOCOL_FEE = 15; // 1.5%

    uint256 public constant RAISE_DURATION = 5 weeks; // 1month and 1 week

    uint public constant MAX_CON_FAILED_PROPOSALS = 3;

    uint public constant MAX_FAILED_PROPOSALS = 5;

    bytes32[] public raiseIds;

    // roles
    bytes32 public constant RAISE_CREATION_CONTRACT = keccak256("RAISEBOX_RAISE_CREATION");
    bytes32 public constant CONTRIBUTION_CONTRACT = keccak256("RAISEBOX_CONTRIBUTION");
    bytes32 public constant PROPOSAL_CONTRACT = keccak256("RAISEBOX_PROPOSAL");
    bytes32 public constant VOTING_CONTRACT = keccak256("RAISEBOX_VOTING");
    bytes32 public constant DRIP_HANDLER = keccak256("RAISEBOX_DRIPPER");

    address payable public protocol;

    address private raiseBoxOwner;

    address public protocolFeeAddress = address(0x1); // tentative.

    uint256 public totalProtocolFees;

    // raiseId (Keccak hash) to raiseInfo
    mapping(bytes32 => RaiseInfo) public raiseInfo;

    // role-based authorization (bytes32 role => (caller => allowed))
    mapping(bytes32 => mapping(address => bool)) public authorizedCallers;

    address[] public whiteListedVerifiedFounders;

    mapping (address => bool) private verifiedFounders;


    mapping(bytes32 => bool) raiseExists;

    mapping(bytes32 => RaiseState) raiseState;

    mapping(bytes32 => uint256) amountRaisedByProject;


    // new constants: for testing purpose

    uint256 public constant CREATION_DELAY = 12 hours; // 12 hours after creation

    uint256 constant CONTRIBUTION_PERIOD = 30 minutes; // 2 weeks // 30 minutes for testing

    uint256 constant DELEGATION_RESEARCH_DELAY = 2 days; // 48 hours

    // constructor:
    constructor() Ownable(msg.sender) ERC20("token", "tokenname") {
        raiseBoxOwner = msg.sender; 

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
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseCreationContract_ZeroAddress();
        }

        if (raiseBoxRaiseCreation != address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseCreation_ContractAlreadySet();
        }

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_isContract_NotAContractAddress(contractAddressToSet);
        }

        raiseBoxRaiseCreation = contractAddressToSet;

        // grantRole(RAISE_CREATION_CONTRACT, contractAddressToSet);
        authorizedCallers[RAISE_CREATION_CONTRACT][contractAddressToSet] = true; // SHOULD EMIT A ROLE GRANTED EVENT -- FORTHCOMING/ EBBY

        emit RaiseBoxEventsLib.RaiseBoxCore_RaiseCreationContractSet(contractAddressToSet);
    }

    function setContributionContract(address contractAddressToSet) external onlyOwner {
        if (contractAddressToSet == address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setContributionContract_ZeroAddress();
        }

        if (raiseBoxContribution != address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setRaiseContributionContract_ContractAlreadySet();
        }

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_isContract_NotAContractAddress(contractAddressToSet);
        }

        raiseBoxContribution = contractAddressToSet;

        // grantRole(CONTRIBUTION_CONTRACT, contractAddressToSet);
        authorizedCallers[CONTRIBUTION_CONTRACT][contractAddressToSet] = true;

        emit RaiseBoxEventsLib.ContributionContractSet(contractAddressToSet);
    }

    function setProposalContract(address contractAddressToSet) external onlyOwner {
        if (contractAddressToSet == address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setProposalContract_ZeroAddress();
        }

        if (raiseBoxProposal != address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setProposalContract_ContractAlreadySet();
        }

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_isContract_NotAContractAddress(contractAddressToSet);
        }

        raiseBoxProposal = contractAddressToSet;

        // grantRole(PROPOSAL_CONTRACT, contractAddressToSet);
        authorizedCallers[PROPOSAL_CONTRACT][contractAddressToSet] = true;

        emit RaiseBoxEventsLib.ProposalContractSet(contractAddressToSet);
    }

    function setDripHandlerContract(address contractAddressToSet) external onlyOwner {

        if (contractAddressToSet == address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setDripHandlerContract_ZeroAddress();
        }

        if (raiseBoxDripHandler != address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setDripHandlerContract_ContractAlreadySet();
        }

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_isContract_NotAContractAddress(contractAddressToSet);
        }

        raiseBoxDripHandler = contractAddressToSet;

        // grantRole(PROPOSAL_CONTRACT, contractAddressToSet);
        authorizedCallers[DRIP_HANDLER][contractAddressToSet] = true;

        emit RaiseBoxEventsLib.DripperContractSet(contractAddressToSet);
    }

    function setVotingContract(address contractAddressToSet) external onlyOwner {

        if (contractAddressToSet == address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setVotingContract_ZeroAddress();
        }

        if (raiseBoxVoting != address(0)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_setVotingContract_ContractAlreadySet();
        }

        if (!_isContract(contractAddressToSet)) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_isContract_NotAContractAddress(contractAddressToSet);
        }

        raiseBoxVoting = contractAddressToSet;

        // grantRole(VOTING_CONTRACT, contractAddressToSet);
        authorizedCallers[VOTING_CONTRACT][contractAddressToSet] = true;

        emit RaiseBoxEventsLib.VotingContractSet(contractAddressToSet);
    }

    // function updateRaiseInfoWithCreationHash(bytes32 creationHash) {

    // }




     function updateRaiseInfo(
        ProjectInfo calldata projectInfo_,
        uint256 raiseCreatedAt_,
        uint256 amountRaisedByProject_,
        bool doesRaiseExist_,
        bytes32 raiseId_,
        address raiseOwner_,
        uint256 yesVotes_,
        uint256 noVotes_,
        uint256 proposalId_
    ) external {

        /// @dev this calls must always come from a raisebox related contract
        /// each of the raisebox contract is allowed access to specific internal functions

        if (
            authorizedCallers[RAISE_CREATION_CONTRACT][msg.sender] && proposalId_ == 0
            ) {
            _updateRaiseCreation(
                projectInfo_,
                raiseId_,
                raiseCreatedAt_,
                doesRaiseExist_,
                raiseOwner_
            );
        } else if (
            authorizedCallers[CONTRIBUTION_CONTRACT][msg.sender] && amountRaisedByProject_ > 0
            ) {
            _updateContributions(raiseId_, amountRaisedByProject_);
            
        } else if (
            authorizedCallers[PROPOSAL_CONTRACT][msg.sender] && proposalId_ >= 0
            ) {
            _updateRaiseProposalInfo(raiseId_);
           
        } else if (
            authorizedCallers[VOTING_CONTRACT][msg.sender] && yesVotes_ >= 0 && noVotes_ >= 0
            ) {
            _updateVotingInfo(raiseId_, yesVotes_, noVotes_, proposalId_);
        } 
        
        else {  revert RaiseBoxErrorsLib.RaiseBoxCore_updateRaiseInfo_UnAuthorizedCaller(); // call is not from any raiseBox related contract}
        }

    }


    function endRaise(bytes32 raiseId_) external {

        if (
            authorizedCallers[CONTRIBUTION_CONTRACT][msg.sender] ||
            authorizedCallers[VOTING_CONTRACT][msg.sender]
        ) {

        RaiseInfo storage _raiseInfo;

        _raiseInfo = raiseInfo[raiseId_];

        // raise already ended maybe by chainlink upkeep, calling x2 waste gas
        if (_raiseInfo.raiseState == RaiseState.FAILED) return;

        _raiseInfo.raiseState = IRaiseBoxCore.RaiseState.FAILED;

        } else {
            revert RaiseBoxErrorsLib.RaiseBoxCore_UnauthorizedRaiseEnder(msg.sender);
        }

        emit RaiseBoxEventsLib.RaiseBoxCore_endRaise_RaiseEnded(raiseId_, block.timestamp);
    }


    function _updateContributions(bytes32 raiseId_, uint256 amount_) internal {
        RaiseInfo storage raiseInfo_;

        raiseInfo_ = raiseInfo[raiseId_];

        raiseInfo_.raiseContributionInfo.amountRaisedByProject += amount_;

        raiseInfo_.raiseState = _updateRaiseState(RaiseState.PROPOSAL, raiseId_);

        emit RaiseBoxEventsLib.RaiseContributionInfoUpdated(raiseId_, amount_);
    }

    function _updateRaiseProposalInfo(bytes32 raiseId_) internal {
        RaiseInfo storage _raiseInfo;

        _raiseInfo = raiseInfo[raiseId_];

        _raiseInfo.raiseProposalInfo.proposalsHostedByProject += 1;

        // sets raise state to VOTING, allowing voting on proposals to happen
        _raiseInfo.raiseState = _updateRaiseState(RaiseState.DELEGATING, raiseId_);

        emit RaiseBoxEventsLib.RaiseProposalInfoUpdated();
       
    }

    function _updateVotingInfo(
        bytes32 raiseId, 
        uint256 forVotes_, 
        uint256 againstVotes_, 
        uint256 proposalId_
        ) internal {

        // get raise info from storage
        RaiseInfo storage raiseInfo_ = raiseInfo[raiseId];

        // initial state 
        RaiseState oldRaiseState = raiseInfo_.raiseState;

        if (raiseInfo_.raiseState == RaiseState.VOTING) {

            // happy branch for when voting passes
            if (forVotes_ > againstVotes_) {

                // set raise state to DRIPPING:
                raiseInfo_.raiseState = RaiseState.DRIPPING;

                emit RaiseBoxEventsLib.RaiseBoxCore_updateState_RaiseStateUpdated(oldRaiseState, raiseInfo_.raiseState);

                raiseInfo_.raiseProposalInfo.lastProposalFailed = false;
                // return;
                
            } else {

                // for when voting does not pass

                // reset raise state back to proposal state
                raiseInfo_.raiseState = RaiseState.PROPOSAL;

                emit RaiseBoxEventsLib.RaiseBoxCore_updateState_RaiseStateUpdated(oldRaiseState, raiseInfo_.raiseState);

                // update nonConFailedProposals, doesn't depend on the previous proposal failing
                raiseInfo_.raiseProposalInfo.nonConFailedProposals++;

                // handle edge case where proposalId_ is 0 since valid proposalIds start from 1.*
                if (proposalId_ == 1) {
                    raiseInfo_.raiseProposalInfo.conFailedProposals++;
                    // raiseInfo_.raiseProposalInfo.lastProposalFailed = true;
                    // return;
                }

                // for consecutive proposal failures
                if (raiseInfo_.raiseProposalInfo.lastProposalFailed) {
                    raiseInfo_.raiseProposalInfo.conFailedProposals++;
                }


                // update lastProposalFailed in storage
                raiseInfo_.raiseProposalInfo.lastProposalFailed = true;
                
            }

        }

        // failure thresholds: whichever triggers first -> FAIL the raise
        if (
            raiseInfo_.raiseProposalInfo.conFailedProposals >= MAX_CON_FAILED_PROPOSALS
            
            ) {
            raiseInfo_.raiseState = RaiseState.FAILED;

            emit RaiseBoxEventsLib.RaiseBoxCore_updateState_RaiseStateUpdated(oldRaiseState, raiseInfo_.raiseState);

            emit RaiseBoxEventsLib.RaiseBox_ExceededMaxConFailedProposals(3);
            emit RaiseBoxEventsLib.RaiseBox_RaiseFailed(raiseId);
            return;

        } else if (raiseInfo_.raiseProposalInfo.nonConFailedProposals >= MAX_FAILED_PROPOSALS) {
            raiseInfo_.raiseState = RaiseState.FAILED;

            emit RaiseBoxEventsLib.RaiseBoxCore_updateState_RaiseStateUpdated(oldRaiseState, raiseInfo_.raiseState);

            emit RaiseBoxEventsLib.RaiseBox_ExceededMaxFailedProposals(5);
            emit RaiseBoxEventsLib.RaiseBox_RaiseFailed(raiseId);
            return;
        }


    emit RaiseBoxEventsLib.RaiseVotingInfoUpdated(oldRaiseState, raiseInfo_.raiseState);
       
}


    function _updateRaiseCreation(
        ProjectInfo calldata _projectInfo,
        bytes32 raiseId_,
        uint256 _createdAt,
        bool _requireRaiseExist,
        address raiseOwner_
        
    ) internal {
        RaiseInfo storage _raiseInfo;

        _raiseInfo = raiseInfo[raiseId_];

        /// @dev creation info update:
        _raiseInfo.raiseCreationInfo.projectInfo = _projectInfo;
        _raiseInfo.raiseCreationInfo.raiseId = raiseId_;
        _raiseInfo.raiseCreationInfo.doesRaiseExist = _requireRaiseExist;
        _raiseInfo.raiseCreationInfo.raiseCreatedAt = _createdAt;
        _raiseInfo.raiseCreationInfo.raiseOwner = raiseOwner_;

        // raise deadline update:
        _raiseInfo.raiseDuration = RAISE_DURATION;

        /// @dev raise state update: INACTIVE ---> ACTIVE
        /// opens raise to contributions, only then can raisers contribute
        /// @dev add a creation delay to delay transition from active to contribution
        
        if (_raiseInfo.raiseState == RaiseState.INACTIVE) {
            _raiseInfo.raiseState = _updateRaiseState(RaiseState.ACTIVE, raiseId_);
        }

        emit RaiseBoxEventsLib.RaiseCreationInfoUpdated(raiseId_);
    }

    // state mutating internal functions for raise state transitions:
    // will all be called via the syncRaiseState external function

    function syncRaiseState(bytes32 raiseId_) external {
        _syncRaiseState(raiseId_);
    }

    function _syncRaiseState(bytes32 raiseId_) internal {

        _requireRaiseExist(raiseId_);

         RaiseInfo storage _raiseInfo = raiseInfo[raiseId_];

// if raise does not exist or already terminal, do nothing

        // RaiseInfo storage _raiseInfo = raiseInfo[raiseId_];

        if (_raiseInfo.raiseState == RaiseState.ACTIVE) {
            _fromActiveToContribution(raiseId_);
        }

        if (
            _raiseInfo.raiseState == RaiseState.CONTRIBUTION &&
            block.timestamp > (_raiseInfo.raiseCreationInfo.raiseCreatedAt + RAISE_DURATION) &&
            _raiseInfo.raiseContributionInfo.amountRaisedByProject < _raiseInfo.raiseCreationInfo.projectInfo.raiseTarget
            
            ) {
            _failedRaise(raiseId_);
        }

        if (_raiseInfo.raiseState == RaiseState.DELEGATING) {
            _fromDelegationToVoting(raiseId_);
        } 

        if (_raiseInfo.raiseState == RaiseState.DRIPPING) {
            _fromDrippingToProposal(raiseId_);
        }
    }

    function _fromActiveToContribution(bytes32 raiseId_) internal {

        RaiseInfo storage _raiseInfo = raiseInfo[raiseId_];

        // current state to update from
        RaiseState oldRaiseState = raiseInfo[raiseId_].raiseState;

        if (
            block.timestamp >= (CREATION_DELAY + _raiseInfo.raiseCreationInfo.raiseCreatedAt) && 
            _raiseInfo.raiseState == RaiseState.ACTIVE
            ) {
            _raiseInfo.raiseState = RaiseState.CONTRIBUTION;
        }

        emit RaiseBoxEventsLib.RaiseBoxCore_updateState_RaiseStateUpdated(oldRaiseState, _raiseInfo.raiseState);
    }

    function _failedRaise(bytes32 raiseId_) internal {
        // move state from contribution to failed since target not met
        RaiseInfo storage _raiseInfo = raiseInfo[raiseId_];

        // current state to update from
        RaiseState oldRaiseState = _raiseInfo.raiseState;

        if ( _raiseInfo.raiseState == RaiseState.FAILED) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_RaiseAlreadyFailed(raiseId_);
        }

        _raiseInfo.raiseState = RaiseState.FAILED;

        emit RaiseBoxEventsLib.RaiseBoxCore_updateState_RaiseStateUpdated(oldRaiseState, _raiseInfo.raiseState);

        emit RaiseBoxEventsLib.RaiseBoxCore_failRaise_RaiseFailed(raiseId_, block.timestamp);
    }

    function _fromDelegationToVoting(bytes32 raiseId_) internal {
        RaiseInfo storage raiseInfo_ = raiseInfo[raiseId_];

        if (raiseInfo_.raiseState != RaiseState.DELEGATING) return;

        if (
            block.timestamp <
            raiseInfo_.raiseProposalInfo.lastProposalTime + DELEGATION_RESEARCH_DELAY
        ) {
            return;
        }

        RaiseState oldState = raiseInfo_.raiseState;
        raiseInfo_.raiseState = RaiseState.VOTING;

        emit RaiseBoxEventsLib.RaiseBoxCore_updateState_RaiseStateUpdated(
        oldState,
        RaiseState.VOTING
        );
}


    function _fromDrippingToProposal(bytes32 raiseId_) internal {
        RaiseInfo storage _raiseInfo = raiseInfo[raiseId_];

        // current state to update from
        RaiseState oldRaiseState = raiseInfo[raiseId_].raiseState;

        if (!_raiseInfo.raiseProposalInfo.lastProposalFailed && _raiseInfo.raiseProposalInfo.lastProposalTime <= block.timestamp) {
            // means it passed and hence was dripped
            _raiseInfo.raiseState = RaiseState.PROPOSAL;
        }
    }

    // function _fromPassedToEnded() internal {
    //     // this transitions raise state from passed (a state where raise passed) to ended(a state where all funds have been dripped)

    //     RaiseInfo storage _raiseInfo = raiseInfo[raiseId_];

    //     // current state to update from
    //     RaiseState oldRaiseState = raiseInfo[raiseId_].raiseState;

    //     if ()
    // }





    function _updateRaiseState(RaiseState newRaiseState, bytes32 raiseId) internal returns(RaiseState) {

        // current state to update from
        RaiseState oldRaiseState = raiseInfo[raiseId].raiseState;
        RaiseState state = oldRaiseState;

        if (
            authorizedCallers[PROPOSAL_CONTRACT][msg.sender] || 
            authorizedCallers[RAISE_CREATION_CONTRACT][msg.sender] || 
            authorizedCallers[CONTRIBUTION_CONTRACT][msg.sender] || 
            authorizedCallers[VOTING_CONTRACT][msg.sender] 
            ) {
            state = newRaiseState;
        } else {
            revert RaiseBoxErrorsLib.RaiseBoxCore_UnAuthorizedCallerCannotUpdateRaiseState(msg.sender); 
            }

        emit RaiseBoxEventsLib.RaiseBoxCore_updateState_RaiseStateUpdated(oldRaiseState, newRaiseState);

        return newRaiseState;

    }

     /**
     * @notice method to check if a raise exists, returns true if raise is found in storage
     * @param raiseId id of the raise to check if exist
     * @dev internal but exposed by it's external counterpart `doesRaiseExist` which simply calls this
     */
     function _requireRaiseExist(bytes32 raiseId) internal view {
        if (!raiseInfo[raiseId].raiseCreationInfo.doesRaiseExist) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_doesRaiseExist_RaiseDoesNotExist();
        }
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


    function _getRaiseInfo(bytes32 raiseId) internal view returns (RaiseInfo memory) {
            _requireRaiseExist(raiseId);
            return raiseInfo[raiseId];
    }

    // getters:

    function getRaiseState(bytes32 raiseId) external view returns (RaiseState) {
        _requireRaiseExist(raiseId); 
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

    function getMinimumContribution() public pure returns (uint256) {
        return MINIMUM_CONTRIBUTION;
    }

    function getRaiseInfo(bytes32 raiseId) external view returns (RaiseInfo memory) {
       return _getRaiseInfo(raiseId);
    }

    function getAmountToRaise(bytes32 raiseId) external view returns (uint256) {
            _requireRaiseExist(raiseId);
            return raiseInfo[raiseId].raiseCreationInfo.projectInfo.raiseTarget;
        
    }

    function getAmtRaisedByProject(bytes32 raiseId) external view returns (uint256) {
            _requireRaiseExist(raiseId);
            return raiseInfo[raiseId].raiseContributionInfo.amountRaisedByProject;
        
    }

    function getProtocolFeeAddress() external view returns (address) {
        return protocolFeeAddress;
    }

    function getAcceptedToken() external view returns (address) {
        return address(iRBTInstance);
    }

    function doesRaiseExist(bytes32 raiseId_) external view {
       _requireRaiseExist(raiseId_);
    }

    function getRaiseCreatedAt(bytes32 raiseId_) external view returns (uint256) {
            _requireRaiseExist(raiseId_);
            raiseInfo[raiseId_].raiseCreationInfo.raiseCreatedAt;
    }

    function getRaiseCreator(bytes32 raiseId_) external view returns (address) {
            _requireRaiseExist(raiseId_);
            return raiseInfo[raiseId_].raiseCreationInfo.raiseOwner;
    }

    function getRaiseBoxOwner() external view returns (address) {
        return raiseBoxOwner;
    }

    function isRaiseCreator(address raiseCreator, bytes32 raiseId_) external view returns (bool) {
        _requireRaiseExist(raiseId_);
         return raiseInfo[raiseId_].raiseCreationInfo.raiseOwner == raiseCreator;
    }

    function isAuthorizedCaller(bytes32 role, address caller) external view returns (bool) {
        return authorizedCallers[role][caller];
    }

    function getRaiseDeadline(bytes32 raiseId_) external view returns (uint256) {
        _requireRaiseExist(raiseId_);
        return (RAISE_DURATION + raiseInfo[raiseId_].raiseCreationInfo.raiseCreatedAt);
    }

    function getProposalsHosted(bytes32 raiseId_) external view returns(uint256) {
            _requireRaiseExist(raiseId_);
            return raiseInfo[raiseId_].raiseProposalInfo.proposalsHostedByProject;
    }

    function getDelegationAndResearchDelay() external view returns (uint256) {
        return DELEGATION_RESEARCH_DELAY;
    }

     function getLastProposalTime(bytes32 raiseId_) external view returns (uint256) {
        return raiseInfo[raiseId_].raiseProposalInfo.lastProposalTime;
     }


    ///// new:

    function addRaiseId(bytes32 id_) external {
        if (!authorizedCallers[RAISE_CREATION_CONTRACT][msg.sender]) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_addRaiseId_UnauthorizedCaller(msg.sender);
        }
         raiseIds.push(id_);
    }

    function _getRaiseIds() internal view returns (bytes32[] memory) {
        return raiseIds;
    }

    function getRaiseIds() external view returns (bytes32[] memory) {
        return _getRaiseIds();
    }


     function _endRaise(bytes32 raiseId_) internal {
        RaiseInfo storage _raiseInfo;

        _raiseInfo = raiseInfo[raiseId_];

        if ( _raiseInfo.raiseState == IRaiseBoxCore.RaiseState.FAILED) {
            revert RaiseBoxErrorsLib.RaiseBoxCore_RaiseAlreadyEnded(raiseId_);
        }

        _raiseInfo.raiseState = IRaiseBoxCore.RaiseState.FAILED;

        emit RaiseBoxEventsLib.RaiseBoxCore_endRaise_RaiseEnded(raiseId_, block.timestamp);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        // upkeep
        // bytes32[] memory ids = _getRaiseIds();
        bytes32[] memory tempIds = new bytes32[](raiseIds.length);
        uint256 count = 0;

        for (uint256 i = 0; i < raiseIds.length; i++) {
            bytes32 raiseId = raiseIds[i];

            RaiseInfo storage raiseInfo_ = raiseInfo[raiseId];

            uint256 deadline = raiseInfo_.raiseCreationInfo.raiseCreatedAt + RAISE_DURATION;

            // only include raises that are active and past deadline

            // get amount raised:
           uint256 raisedAmount = raiseInfo_.raiseContributionInfo.amountRaisedByProject;

           // get raise target:
           uint256 raiseTarget = raiseInfo_.raiseCreationInfo.projectInfo.raiseTarget;

            if (
                block.timestamp > (5 minutes)
                ) {
                tempIds[count] = raiseId;
                count++;
            }

        }

        if (count > 0) {
            // means there are raises that have passed deadline and need upkeep
            upkeepNeeded = true;

            // prepare performData with the relevant raiseIds
            bytes32[] memory raisesToPerformUpkeepOn = new bytes32[](count);
            for (uint256 j = 0; j < count; j++) {
                raisesToPerformUpkeepOn[j] = tempIds[j];
            }
            performData = abi.encode(raisesToPerformUpkeepOn);
        } else {
            upkeepNeeded = false;
            performData = "";
        }
        
       
    }

    function performUpkeep(bytes calldata performData) external override {
        // performupkeep, end raises that have passed deadline
       if (performData.length == 0) return; // no data to process and perform upkeep on

       bytes32[] memory idsToEnd = abi.decode(performData, (bytes32[]));

       for (uint256 i = 0; i < idsToEnd.length; i++) {
            _syncRaiseState(idsToEnd[i]);
       }

    }

}

