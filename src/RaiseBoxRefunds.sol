// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev contract to handle funds refund to contributors in cases where:
/// @dev raise fails
/// @dev max number of failed proposls is exceeded
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";
import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";


contract RaiseBoxRefunds {
    IRaiseBoxCore public immutable raiseBoxCore;
    IRaiseBoxDripHandler public immutable raiseBoxDripHandler;

    constructor(address raiseBoxCoreAddress, address raiseBoxDripHandlerAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
        raiseBoxDripHandler = IRaiseBoxDripHandler(raiseBoxDripHandlerAddress);
    }

    // mapping to track if a raise has been refunded
    mapping(bytes32 => mapping(address =>bool)) public refundedContributions;
   

    /// @dev function to process refunds for a failed raise
    /// @dev in a real implementation, this would interact with the RaiseBoxCore contract
    /// @dev and handle the actual transfer of funds back to contributors
    function refundContribution(bytes32 raiseId) external {
        // check if the raise has already been refunded
        if (refundedContributions[raiseId][msg.sender]) {
            revert("Raise has already been refunded");
        }

        // logic to calculate total amount to refund
        uint256 totalRefundAmount = 0; // placeholder for actual calculation

        // logic to process refunds to contributors
        // ...

        // mark the raise as refunded
        refundedContributions[raiseId][msg.sender] = true;

        // emit event
        emit RaiseBoxEventsLib.rb_refundContribution_ContributionRefunded(raiseId, totalRefundAmount);
    }

}