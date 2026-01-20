// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRaiseBoxCore {
    struct ProjectInfo {
        string projectName;
        string valueProposition;
        uint256 raiseTarget;
        uint256 projectDuration;
    }

    struct RaiseProposalInfo {
        uint256 proposalsHostedByProject;
        uint256 conFailedProposals;
        uint256 currentConFailed;
        uint256 nonConFailedProposals;
        uint256 lastProposalId;
        bool lastProposalFailed;
    }

    struct RaiseContributionInfo {
        uint256 amountRaisedByProject;
    }

    struct RaiseCreationInfo {
        ProjectInfo projectInfo;
        bytes32 raiseId;
        uint256 raiseCreatedAt;
        bool doesRaiseExist;
        address raiseOwner;
    }

    struct RaiseInfo {
        RaiseCreationInfo raiseCreationInfo;
        RaiseContributionInfo raiseContributionInfo;
        RaiseProposalInfo proposalInfo;
        uint256 raiseDuration; // this is a constant, consider removing
        RaiseState raiseState;
    }

    /// @dev the different states that a raise on raisebox can be in
    enum RaiseState{

        // raise not created yet, default state
        INACTIVE,

        // raise just created before contribution begins
        ACTIVE,

        // raise has been created and contribution is activated
        CONTRIBUTION,

        // raise passed, i.e raise target was reached before raise duration elapsed
        PROPOSAL,

        // just after proposal has been hosted, allows for votes deleation and milestone claims verifications
        DELEGATING,

        //  state where contributors can vote on proposal 
        VOTING,

        // after a successful favorable vote, funds are dripped to raise creator in this state
        DRIPPING,

        PASSED,

        // raise failed either by 3 consecutive failed proposals or 5 non consecutive failed proposals, 
        // raise failed by amtToRaise > amtRaised after raiseDuration
        REFUNDING,

        // state of a raise that either did not meet target or violated the allowed failed proposals limits as stated above
        FAILED,

        // raise state for raises that have ended successfully, 
        // either: all proposals passed and drips were successful or 60 weeks elapsed
        ENDED
    } 


    // function incrementConFailedProposals(bytes32 raiseId) external;


    function isVerifiedAndWhiteListed(address founder) external view returns(bool verified);

    function getProtocol() external returns (address payable);

    function getMinimumContribution() external view returns (uint256);

    function getAmtRaisedByProject(bytes32 projectId_) external view returns (uint256);

    function getProtocolFeeAddress() external view returns (address);

    function getRaiseCreator(bytes32 raiseId) external view returns (address);

    function getAmountToRaise(bytes32 raiseId) external returns (uint256);

    function getRaiseState(bytes32 raiseId) external view returns(RaiseState) ;

    function doesRaiseExist(bytes32 raiseId) external view;

    function getRaiseBoxOwner() external view returns (address);

    function getAcceptedToken() external view returns (address);

    function isRaiseCreator(address raiseCreator, bytes32 raiseId) external view returns (bool);

    function getRaiseCreatedAt(bytes32 raiseId_) external view returns (uint256);

    function getRaiseInfo(bytes32 raiseId) external view returns (RaiseInfo memory);

    function getRaiseDeadline(bytes32 raiseId_) external view returns (uint256);
    
    function getProposalsHosted(bytes32 raiseId) external view returns(uint256);

    // function getRaiseProposalsInfo(bytes32 raiseId) external returns (RaiseProposalInfo memory);

    function updateRaiseInfo(
        ProjectInfo calldata _projectInfo,
        uint256 _raiseCreatedAt,
        uint256 _amountRaisedByProject,
        bool _requireRaiseExist,
        bytes32 _raiseId,
        address _raiseOwner,
        uint256 _forVotes,
        uint256 _againstVotes,
        uint256 _proposalId
    ) external;

    function endRaise(bytes32 raiseId_) external;

    function addRaiseId(bytes32 id_) external;

    function getRaiseIds() external view returns (bytes32[] memory);


    // tasks:
    // ensure drip percent passed by raise creator during hosting of proposal is used in the internal _determineDripPercent function in RaiseBoxDripHandler contract
    // setup raisebox to work with the raisebox faucet ERC20 token
    // contributions, refunds and drips should be done with the token
    // ensure token swap is 1 token : $1 for simplicity and swap mechanism uses uniswap
    // ensure all errors/events across raisebox are form the errors/events libraries
    // set up raise creator prior verification using polygon privadoId -- ensure the creator has the zk proof from thrid party verifier before adding to raisebox whitelist for raise creation
    // setup protocol fee calculation and withdrawal mechanism 
    // protocol fee is 1.5% of total amount raised by project on successful completion of raise
    // implement erc-4337 gassless contribution via account abstraction using a paymaster

  
}
