// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title RaiseBoxErrorsLib
/// @author 0xebby
/// @custom:contact tech.codemojo@gmail.com
/// @notice Library exposing error messages.

library RaiseBoxErrorsLib {

    /// @notice error thrown when zero address is passed or used as caller
    error ZeroAddress();

    /// @notice error thrown when adding new owner to whitelist
    error RaiseBoxRaiseCreation_OwnerNotWhiteListed();

    /// @notice error thrown when unauthorized caller makes a function call
    /// @param caller the unauthorized caller
    error UnAuthorizedCaller(address caller);

    // proposals errors
    error RaiseBoxProposal_isValidProposal_ProposalDoesNotExist(uint256 proposalId);
    error RaiseBoxProposal_hostProposal_InvalidRaiseId(bytes32 raiseId);

    // thrown when unauthorized caller tries to end raise
    error RaiseBoxCore_UnauthorizedRaiseEnder(address caller);

    error RaiseBoxProposal_hostProposal_InvalidDescLength();

    error RaiseBoxProposal_hostProposal_InvalidMilestoneLength();

    // thrown when an unauthorized caller tries to update proposalInfo
    error RaiseBoxProposal_updateProposalInfo_Unauthorized();

    // thrown when voting is attempted for a raise not in PROPOSAL state
    error RaiseBoxVoting_RaiseNotInProposalState();



    /// @notice errors thrown during raise creation on raisebox
    error RaiseCreation_createRaise_RaiseAlreadyExist();
    error RaiseBoxCreation_createRaise_InvalidProjectDuration();
    error RaiseBoxCreation_createRaise_CannotRaiseZeroFunds();
    error RaiseBoxCreation_createRaise_RaiseCreationCooldown();
    error RaiseBoxCreation_createRaise_HasAlreadyCreatedRaise(address creator);
    error RaiseBoxProposal_hostProposal_NotInProposalState();

    error RaiseBoxContribution_RaiseFailed(bytes32 raiseId);
    error RaiseBox_RaiseFailed(bytes32 raiseId);
    error RaiseBoxCore_getProject_InvalidProjectId();
    error RaiseBoxCore_NotAuthorized();
    error RaiseBox_RaiseEnded(bytes32 raiseId);
    error RaiseBoxCore_UnAuthorizedCaller();
    error RaiseBox_RaiseAlreadyPassed(bytes32 raiseId, uint256 amtToRaise, uint256 totContributions);

    error RaiseBoxCore_setRaiseCreation_InvalidCA();
    error RaiseBoxCore_setRaiseCreation_ContractAlreadySet();
    error RaiseBoxCore_setRaiseContribution_ContractAlreadySet();
    error RaiseBoxCore_setRaiseContribution_InvalidContract();
    error RaiseBoxCore_NotSupportedToken();
    error RaiseBoxCore_setDripHandler_InvalidContract();
    error RaiseBoxCore_AlreadyWhiteListed(
        address founder
    );
    error RaiseBoxCore_doesRaiseExist_RaiseDoesNotExist();
    error RaiseBoxCore_isRaiseCreator_NotRaiseCreator(address raiseCreator);
    error RaiseBoxVoting_CannotReDelegate();
    error RaiseBoxVoting_CannotDelegateAfterVotingBegins();
    error RaiseBoxDripHandler_dripFunds_DripAlreadyExecutedForProposal(bytes32 raiseId, uint256 proposalId);
    error RaiseBoxVoting_ProposalDoesNotExist(uint256 proposalId);

    // contribution related errors:
    error RaiseBoxContribution_ValueSentMismatch();
    error RaiseBoxContribution_ContributeMoreEth(uint256);
    error RaiseBoxContribution_ZeroAmount();
    error RaiseBoxContribution_contribute_ContributionFailed();
    error RaiseBoxContribution_InvalidProject();
    error RaiseBoxContribution_RaiseBoxProtocolUnset();
    error RaiseContribution_ContributionEnded(uint256);
    error RaiseBoxContribution_contribute_AboveMaxAllowed(uint256, string);
    error RaiseBoxContribution_getMaxContributionAllowedForProject_CannotBeZero();
    error RaiseBoxContribution_SelfContribution();
    error RaiseBoxContribution_NotAContributor(bytes32 raiseId);
    error RaiseBoxContribution_InvalidRaiseId();


    
    error RaiseBoxCore_getProtocol_RaiseBoxProtocolUnset();

}