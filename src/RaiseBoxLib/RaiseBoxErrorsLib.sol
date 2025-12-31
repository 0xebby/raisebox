// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title RaiseBoxErrorsLib
/// @author 0xebby
/// @custom:contact tech.codemojo@gmail.com
/// @notice Library exposing custom errors.

library RaiseBoxErrorsLib {

    /// @notice thrown when zero address is passed or used as caller
    error RaiseBox_ZeroAddressNotAllowed();

    /// @notice thrown when an unwhitelisted `address` tries to create a raise on raisebox
    error RaiseBoxRaiseCreation_OwnerNotWhiteListed();

    /// @notice thrown when unauthorized `caller` calls `updateRaiseState`
    /// @param caller address of the unauthorized `caller`
    error RaiseBoxCore_UnAuthorizedCallerCannotUpdateRaiseState(address caller);

    /// @notice thrown when an invalid `proposalId` is passed
    /// @param proposalId the invalid proposalId passed
    error RaiseBoxProposal_isValidProposal_ProposalDoesNotExist(uint256 proposalId);

    /// @notice thrown when an invalid `raiseId` is passed to `canHostProposal` modifier
    /// @param raiseId the invalid `id` passed
    error RaiseBoxProposal_canHostProposal_InvalidRaiseId(bytes32 raiseId);

    /// @notice thrown when unauthorized caller tries to call the endRaise function
    /// @param caller `address` of the unauthorized caller
    error RaiseBoxCore_UnauthorizedRaiseEnder(address caller);

    /// @notice thrown when the legth of project description text is `0` less or greater than allowed length
    error RaiseBoxProposal_hostProposal_InvalidDescLength();

    /// @notice thrown when the legth of project milestone text is `0` less or greater than allowed length
    error RaiseBoxProposal_hostProposal_InvalidMilestoneLength();

    /// @notice thrown when an unauthorized caller tries to update proposalInfo
    error RaiseBoxProposal_updateProposalInfo_Unauthorized();

    /// @notice thrown when voting is attempted for a raise not in PROPOSAL state
    error RaiseBoxVoting_RaiseNotInVotingState();
    
    /// @notice thrown if duration for project during raise creation is less than or above allowed
    error RaiseBoxCreation_createRaise_InvalidProjectDuration();

    /// @notice thrwon if project tries to raise `$0`
    error RaiseBoxCreation_createRaise_CannotRaiseZeroFunds();

    /// @notice thrwon if raise creator tries to create another raise while there's one already live for same creator
    error RaiseBoxCreation_createRaise_RaiseCreationCooldown();

    /// @notice thrwon when raise is not in proposalState during proposal hosting
    error RaiseBoxProposal_RaiseNotInProposalState();

    /// @notice thrown when contribution to a failed raise is attempted
    /// @param raiseId attempted raiseId
    error RaiseBoxContribution_RaiseFailed(bytes32 raiseId);

    /// @notice thrown when contribution to an ended raise is attempted
    /// @param raiseId attempted raiseId
    error RaiseBoxContribution_RaiseEnded(bytes32 raiseId);

    /// @notice thrown when trying to host a proposal for a failed raise
    /// @param raiseId id of the failed raise
    error RaiseBox_RaiseFailed(bytes32 raiseId);

    /// @notice thrown creator attempts to host a proposal for a raise that has ended
    /// @param raiseId `raiseId` of the ended raise
    error RaiseBoxProposal_hostProposal_RaiseEnded(bytes32 raiseId);

    /// @notice thrown when an authorized `address` calls `updateRaiseInfo`
    error RaiseBoxCore_updateRaiseInfo_UnAuthorizedCaller();

    /// @notice thrown when attempting to contribute to a passed raise
    /// @param raiseId `id` of the passed raise
    /// @param raiseTarget raise target of the raise
    /// @param totContributions total amount contributed to the passed raise
    error RaiseBoxContribution_contribute_RaiseAlreadyPassed(
        bytes32 raiseId, 
        uint256 raiseTarget, 
        uint256 totContributions
        );

    /// @notice thrown when zero address is set for raiseCreation contract
    error RaiseBoxCore_setRaiseCreationContract_ZeroAddress();

    /// @notice thrown when raiseCreationContract has already been set
    error RaiseBoxCore_setRaiseCreation_ContractAlreadySet();

    /// @notice thrown when a non contract address is passed to `_isContract` function
    error RaiseBoxCore_isContract_NotAContractAddress(address CA);

    /// @notice thrown when zero address is set for raiseContribution contract
    error RaiseBoxCore_setContributionContract_ZeroAddress();

    /// @notice thrown when raiseContributionContract has already been set
    error RaiseBoxCore_setRaiseContributionContract_ContractAlreadySet();

    /// @notice thrown when zero address is set for raiseProposal contract
     error RaiseBoxCore_setProposalContract_ZeroAddress();

    /// @notice thrown when raiseProposalContract has already been set
    error RaiseBoxCore_setProposalContract_ContractAlreadySet();

    /// @notice thrown when zero address is set for dripHandler contract
     error RaiseBoxCore_setDripHandlerContract_ZeroAddress();

    /// @notice thrown when dripHandlerContract has already been set
    error RaiseBoxCore_setDripHandlerContract_ContractAlreadySet();

    /// @notice thrown when zero address is set for voting contract
    error RaiseBoxCore_setVotingContract_ZeroAddress();

    /// @notice thrown when voting has already been set
    error RaiseBoxCore_setVotingContract_ContractAlreadySet();
    
    /// @notice thrown when contributions are made with unsupoorted token(s)
    error RaiseBoxCore_NotSupportedToken();

    /// @notice thrown if `address` passed is already on whitelist
    /// @param founder `address` already whitelisted
    error RaiseBoxCore_AlreadyWhiteListed(
        address founder
    );

    /// @notice thrown if raise does not exist in storage
    error RaiseBoxCore_doesRaiseExist_RaiseDoesNotExist();

    /// @notice thrown on vote redelegation attempt
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

    /// @notice thrown when raise creator tries to contribute to self
    error RaiseBoxContribution_SelfContributionForbidden();

    /// @notice thrown when `address` tries to delegate vote in a raise they've not contributed to
    /// @param raiseId `id` of raise
    error RaiseBoxVoting_canDelegate_NotAContributor(bytes32 raiseId);

    /// @notice thrown when contribution is made to a non-exitent raise, either `0` not raisebox issued
    error RaiseBoxContribution_InvalidRaiseId();
    
    /// @notice thrown if protocol address has not been set
    error RaiseBoxCore_getProtocol_RaiseBoxProtocolUnset();

}