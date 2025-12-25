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

    struct ProposalInfo {
        uint256 proposalId;
        uint256 proposalsHosted;
        uint256 conFailedProposals;
        uint256 nonConFailedProposals;
    }

    struct _RaiseInfo {
        ProjectInfo projectInfo;
        uint256 raiseDuration;
        uint256 raiseCreationTime;
        uint256 amountRaisedByProject;
        uint256 projectRaiseCount;
        uint256 proposalsHosted;
        uint256 conFailedProposals;
        uint256 nonConFailedProposals;
        RaiseState raiseState;
        ProposalState proposalState;
        bool raiseExists;
        bytes32 raiseId;
    }

    enum RaiseState{
        INACTIVE, // raise not created yet, default state
        CONTRIBUTION, // raise has been created
        PROPOSAL, // raise passed but still active
        FAILED, // raise failed and becomes inactive again
        VOTING, // raise in proposal hosting state, active, passed, in_proposal
        ENDED, // raise started and then was ended successfully, either: all proposals passed and drips were successful or 60 weeks elapsed
        REFUNDING // raise failed either by 3 consecutive failed proposals or 5 non consecutive failed proposals, raise failed by amtToRaise > amtRaised after raiseDuration
    } //[0,1,2,3,4, 5]

    enum ProposalState{
        ACTIVE,
        PASSED,
        FAILED
    } //[0,1]

    // function incrementConFaildProposals(bytes32 raiseId) external;


    function isVerifiedAndWhiteListed(address founder) external view returns(bool verified);

    function getRaiseCount() external returns (uint256);

    function getProtocol() external returns (address payable);

    function getMinimumContribution() external view returns (uint256);

    function getAmtRaisedByProject(bytes32 projectId_) external returns (uint256);

    function getProtocolFeeAddress() external view returns (address);

    function getRaiseCreator(bytes32 raiseId) external view returns (address);

    function getAmountToRaise(bytes32 raiseId) external returns (uint256);

    function getRaiseState(bytes32 raiseId) external view returns(RaiseState) ;

    function doesRaiseExist(bytes32 raiseId) external view returns (bool);

    function getRaiseBoxOwner() external view returns (address);

    function getAcceptedToken() external view returns (address);

    function isRaiseCreator(address raiseCreator, bytes32 raiseId) external view returns (bool);

    function getRaiseInfo(bytes32 raiseId) external view returns (_RaiseInfo memory);

    function getRaiseDuration() external view returns (uint256);


  function updateRaiseInfo(
        ProjectInfo calldata _projectInfo,
        uint256 _raiseDuration,
        uint256 _raiseCreationTime,
        uint256 _amountRaisedByProject,
        uint256 _numOfProposalsHosted,
        uint256 _projectRaiseCount,
        bool _raiseExists,
        bytes32 _raiseId
    ) external;

  
}
