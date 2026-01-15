// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev contract to handle funds refund to contributors in cases where:
/// @dev raise fails
/// @dev max number of failed proposls is exceeded
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";


contract RaiseBoxRefunds {
    // mapping to track if a raise has been refunded
    mapping(bytes32 => bool) public refundedRaises;

    // event to log refunds
   

    /// @dev function to process refunds for a failed raise
    /// @dev in a real implementation, this would interact with the RaiseBoxCore contract
    /// @dev and handle the actual transfer of funds back to contributors
    function refundContribution(bytes32 raiseId) external {
        // check if the raise has already been refunded
        if (refundedRaises[raiseId]) {
            revert("Raise has already been refunded");
        }

        // logic to calculate total amount to refund
        uint256 totalRefundAmount = 0; // placeholder for actual calculation

        // logic to process refunds to contributors
        // ...

        // mark the raise as refunded
        refundedRaises[raiseId] = true;

        // emit event
        emit RaiseBoxEventsLib.rb_refundContribution_ContributionRefunded(raiseId, totalRefundAmount);
    }

}