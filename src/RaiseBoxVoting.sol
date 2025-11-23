// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";

abstract contract RaiseBoxVoting is IRaiseBoxVoting, IRaiseBoxProjectCreation {
    // voting related state variables: also contributor related
    uint256 private voteCastedForYes;
    uint256 private voteCastedForNo;
    uint256 private totalVotesCastedByContributors;

    // // contributors related modifiers:
    // modifier onlyContributors() {
    //     require(
    //         contributorsToAmountContributed[msg.sender] > 0,
    //         "User is not a contributor: Contribute to enter"
    //     );
    //     _;
    // }

    // voting state enum
    enum VotingState {
        VOTING_LIVE,
        CALCULATING_RESULTS,
        VOTING_ENDED,
        WINNER_DECLARED
    }

    // proposal voting related errors
    error CrowdFund_NoVoteCasted();

    // Vote for milestone approval and funds withdrawal
    /// @notice contributors vote for milestone approval and protocol releases x% of funds to project if proposal is approved
    /// @dev Only callable by a contributor
    function voteForProposal() public /*onlyContributors*/ {
        VotingState votingState = VotingState.VOTING_LIVE;
    }

    function calculateVotePercentage() internal returns (uint256 yesPercentage, uint256 noPercentage) {
        if (totalVotesCastedByContributors == 0) {
            revert CrowdFund_NoVoteCasted();
        }
        yesPercentage = ((voteCastedForYes / totalVotesCastedByContributors) / 100);
        noPercentage = ((voteCastedForNo / totalVotesCastedByContributors) / 100);
        VotingState votingState = VotingState.VOTING_ENDED;

        return (yesPercentage, noPercentage);
    }
}
