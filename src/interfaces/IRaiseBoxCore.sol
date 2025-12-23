// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRaiseBoxCore {

    struct ProjectInfo {
        address projectOwner;
        string projectName;
        string valueProposition;
        uint256 raiseTarget;
        uint256 projectDuration;
    }

    struct _RaiseInfo {
        ProjectInfo projectInfo;
        uint256 raiseDuration;
        uint256 raiseCreationTime;
        uint256 amountRaisedByProject;
        uint256 projectRaiseCount;
        uint256 proposalsHosted;
        RaiseState raiseState;
        bool raiseExists;
        bytes32 raiseId;
    }

    enum RaiseState{
        INACTIVE, // raise not created yet, default state
        CONTRIBUTION, // raise has been created
        PROPOSAL, // raise passed but still active
        FAILED, // raise failed and becomes inactive again
        VOTING // raise in proposal hosting state, active, passed, in_proposal
    } //[0,1,2,3,4]

    enum ProposalState{
        PASSED,
        FAILED
    } //[0,1]


    function isVerifiedAndWhiteListed(address founder) external view returns(bool verified);

    // raiseBoxCore methods:

    function getRaiseCount() external returns (uint256);

    function getProtocol() external returns (address payable);

    function getMinimumContribution() external view returns (uint256);

    function getAmtRaisedByProject(bytes32 projectId_) external returns (uint256);

    function getProtocolFeeAddress() external view returns (address);

    function getProject(bytes32 raiseId) external view returns (_RaiseInfo memory);

    function getRaiseCreator(bytes32 raiseId) external view returns (address);

    function getAmountToRaise(bytes32 raiseId) external returns (uint256);

    function getRaiseState(bytes32 raiseId) external view returns(RaiseState) ;

    function doesRaiseExist(bytes32 raiseId) external view returns (bool);

    function getRaiseBoxOwner() external view returns (address);

    function getAcceptedToken() external view returns (address);

    // contribution methods:

    // proposal methods;

    // voting methods:

    // expose all the contract addresses using the getters;


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
    ) external;

    function isRaiseCreator(address raiseCreator) external view returns (bool);

    function getRaiseInfo(bytes32 raiseId) external view returns (_RaiseInfo memory);

    function getRaiseDuration() external view returns (uint256);
}
