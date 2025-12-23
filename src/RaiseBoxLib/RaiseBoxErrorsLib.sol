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



    /// @notice errors thrown during raise creation on raisebox
    error RaiseCreation_createRaise_RaiseAlreadyExist();
    error RaiseBoxCreation_createRaise_InvalidRaiseDuration();
    error RaiseBoxCreation_createRaise_CannotRaiseZeroFunds();
    error RaiseBoxCreation_createRaise_RaiseCreationCooldown();
    error RaiseBoxCreation_createRaise_HasAlreadyCreatedRaise(address creator);

    error RaiseBoxContribution_RaiseFailed();
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

    // contribution related errors:
    error RaiseBoxContribution_ValueSentMismatch();
    error RaiseBoxContribution_ContributeMoreEth(uint256);
    error RaiseBoxContribution_ZeroAmount();
    error RaiseBoxContribution_ContributionFailed();
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