// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import "../lib/forge-std/src/Test.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";
import{RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";

contract RaiseBoxVoting is IRaiseBoxVoting {
    IRaiseBoxCore public immutable raiseBoxCore; 

    IRaiseBoxContribution public immutable raiseBoxContribution; 

    IRaiseBoxProposal public immutable raiseBoxProposal; 

    IRaiseBoxDripHandler public immutable raiseBoxDripHandler; 

    address public owner;

    //** ------------------------------------------------------------------ **//
    //                        CONSTRUCTOR                                     //
    //** ------------------------------------------------------------------ **//

    constructor(
        address raiseBoxCoreAddress,
        address raiseBoxContributionAddress,
        address raiseBoxProposalAddress,
        address raiseBoxDripHandlerAddress
    ) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
        raiseBoxContribution = IRaiseBoxContribution(raiseBoxContributionAddress);
        raiseBoxProposal = IRaiseBoxProposal(raiseBoxProposalAddress);
        raiseBoxDripHandler = IRaiseBoxDripHandler(raiseBoxDripHandlerAddress);
        owner = msg.sender;
    }

    //** ------------------------------------------------------------------ **//
    //                        MODIFIERS                                       //
    //** ------------------------------------------------------------------ **//

    modifier canVote(bytes32 raiseId_, address user_, uint256 proposalId_) {

        uint256 _start = _voteStartTime(raiseId_, proposalId_);
        // voting must have been scheduled (start set) before voting commences
        if (_start == 0 || block.timestamp < _start) {
            revert RaiseBoxVoting_VotingNotStarted(raiseId_, proposalId_);
        }

        // this allows any attempt to vote after voting deadline to trigger funds dripper
        if (s_votingEnded[raiseId_][proposalId_] || block.timestamp > (_start + VOTING_DURATION)) {
            revert RaiseBoxVoting_VotingAlreadyEnded(raiseId_, proposalId_);
        }

        raiseBoxProposal.isValidProposal(raiseId_, proposalId_);

        // checks if proposal is live for raise
        
        if (raiseBoxCore.getRaiseState(raiseId_) != IRaiseBoxCore.RaiseState.VOTING) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_RaiseNotInVotingState();
        }

        if (raiseBoxProposal.getProposalState(raiseId_, proposalId_) != IRaiseBoxProposal.ProposalState.ACTIVE) {
            revert RaiseBoxVoting_ProposalNotLive();
        }

        // ascertain msg.sender has contributed to project
        bool hasContributedToProject = raiseBoxContribution.hasUserContributed(raiseId_, user_);

        if (!hasContributedToProject) {
            revert RaiseBoxVoting_NotContributor(raiseId_, user_);
        }

        if (s_hasDelegatedForProposal[user_][raiseId_][proposalId_]) {
            revert RaiseBoxVoting_AlreadyDelegatedVote(user_);
        }

        if (s_hasVotedOnProposal[raiseId_][proposalId_][user_]) {
            revert RaiseBoxVoting_AlreadyVoted(proposalId_, user_);
        }

        _;
    }

    modifier canDelegate(bytes32 raiseId_, uint256 proposalId_, address from_, address to_) {
        bool fromIsContributor = raiseBoxContribution.hasUserContributed(raiseId_, from_);
        bool toIsContributor = raiseBoxContribution.hasUserContributed(raiseId_, to_);

        if (!fromIsContributor || !toIsContributor) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_canDelegate_NotAContributor(raiseId_);
        }

        if (to_ == from_) {
            revert RaiseBoxVoting_CannotDelegateToSelf();
        }

        if (s_hasVotedOnProposal[raiseId_][proposalId_][from_] || s_hasVotedOnProposal[raiseId_][proposalId_][to_]) {
            revert RaiseBoxVoting_CannotDelegateAfterVoting(proposalId_, from_);
        }

        if (block.timestamp >= _voteStartTime(raiseId_, proposalId_)) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_CannotDelegateAfterVotingBegins();
        }

        if (s_delegatedVotes[from_][raiseId_][proposalId_] > 0 ) {
            revert RaiseBoxErrorsLib.RaiseBoxVoting_CannotReDelegate();
        } // fixed redelegation after being delegated votes -- ebby

        if (s_hasDelegatedForProposal[from_][raiseId_][proposalId_]) {
            revert RaiseBoxVoting_CannotDelegateTwice();
        } 
        _;
    }

    modifier onlyRaiseCreator(bytes32 raiseId) {
        if (msg.sender != raiseBoxCore.getRaiseCreator(raiseId)) revert RaiseBoxVoting_NotRaiseOwner(msg.sender);

        _;

    }

    //** ------------------------------------------------------------------ **//
    //                        EXTERNAL FUNCTIONS                              //
    //** ------------------------------------------------------------------ **//

    /// @notice special ownerOnly function that triggers vote end incase no voting    attempt is made after voting duration elapsed
    /// @notice this has to happen to trigger vote tallying and eventual funds drip
    /// @notice any attempt to end just after voting duration exceeds will fail
    /// @dev ends voting if voting hasn't already been ended by another call
    /// @dev can only end if voting duration has been exceeded by atleast 12 hours
    function triggerVoteTally(bytes32 raiseId_, uint256 proposalId_) external onlyRaiseCreator(raiseId_) {

        uint256 _start = s_votingStartTime[raiseId_][proposalId_];

        if (s_votingEnded[raiseId_][proposalId_]) revert RaiseBoxVoting_VotingAlreadyEnded(raiseId_, proposalId_);

        // if voting duration elapsed, mark ended and emit events:
        if (block.timestamp >= (_start + VOTING_DURATION)) {
            _tallyVotes(raiseId_, proposalId_);
            _endVoting(raiseId_, proposalId_);
            emit RaiseBoxVoting_VoteTallyTriggered(msg.sender, proposalId_, block.timestamp);
        } else {
            revert RaiseBoxVoting_VotingNotEnded();
        }

    }

    /// @notice function to cast votes on an hosted proposal
    /// @dev only raise contributors can call `vote` successfully
    /// @param raiseId_ id of the raise where the proposal is hosted
    /// @param proposalId_ id of the proposal to vote for
    /// @param support_ direction of vote, either `for` or `against`
    function vote(bytes32 raiseId_, uint256 proposalId_, bool support_)
        external
        canVote(raiseId_, msg.sender, proposalId_)
    {
        if (s_delegatee[msg.sender][raiseId_][proposalId_]) {

            if (support_) {

                s_votesForProposal[raiseId_][proposalId_] += (s_delegatedVotes[msg.sender][raiseId_][proposalId_] + 1); // votes delegated to voter plus his vote

            } else {

                votesAgainstProposal[raiseId_][proposalId_] += (s_delegatedVotes[msg.sender][raiseId_][proposalId_] + 1);
            }

        } else {

            if (support_) {

                s_votesForProposal[raiseId_][proposalId_] += 1;

            } else {

                votesAgainstProposal[raiseId_][proposalId_] += 1;
            }

        }

        s_hasVotedOnProposal[raiseId_][proposalId_][msg.sender] = true;

        emit Voted(msg.sender, raiseId_, proposalId_, support_);
    }

    /**
    /// @notice Set voting start time for a proposal, only prop contract can call
    /// @dev sets the start time for voting on a specific proposal within a project.
    /// @dev only the proposal contract should be able to set voting start times
    /// @param raiseId_ unique id of a project.
    /// @param proposalId_ unique id of a proposal within the project.
    /// @param startTime_ voting start time.
    /// @dev emits VotingStartTimeSet to mark success.
    **/
    function setVotingStartTime(bytes32 raiseId_, uint256 proposalId_, uint256 startTime_) external {

        raiseBoxProposal.isValidProposal(raiseId_, proposalId_);
        
        if (msg.sender != address(raiseBoxProposal)) {
            revert("Only proposal contract can set voting start time.");
        }
        s_votingStartTime[raiseId_][proposalId_] = startTime_;

        emit VotingStartTimeSet(raiseId_, proposalId_, startTime_);
    }

    function delegateVote(bytes32 raiseId_, uint256 proposalId_, address from_, address to_)
        external
        canDelegate(raiseId_, proposalId_, from_, to_)
    {
        
        // record delegation
        s_delegatedVoteTo[from_][raiseId_][proposalId_] = to_;
        // add voting right to 'to' address

        s_delegatedVotes[to_][raiseId_][proposalId_] += 1;
        s_hasDelegatedForProposal[from_][raiseId_][proposalId_] = true;
        s_delegatee[to_][raiseId_][proposalId_] = true;

        emit VoteDelegated(from_, to_);
    }

    //** ------------------------------------------------------------------ **//
    //                        STATE VARIABLES                                 //
    //** ------------------------------------------------------------------ **//

    mapping(bytes32 => mapping(uint256 => mapping(address => bool))) public s_hasVotedOnProposal;

    mapping(address => mapping(bytes32 => mapping(uint256 => address))) public s_delegatedVoteTo;

    mapping(bytes32 => mapping(uint256 => uint256)) public s_votesForProposal;

    mapping(bytes32 => mapping(uint256 => uint256)) public votesAgainstProposal; 

    mapping(bytes32 => mapping(uint256 => bool)) public s_votingEnded; 

    mapping(bytes32 => mapping(uint256 => uint256)) public s_votingStartTime;

    uint256 public constant VOTING_DURATION = 7 days;

    mapping(address => mapping(bytes32 => mapping(uint256 => uint256))) public s_delegatedVotes;

    mapping(address => bool) public delegated;

    // delegated votes tracker scoped to proposal:
    mapping(address => mapping(bytes32 => mapping(uint256 => bool))) public s_hasDelegatedForProposal;

    mapping(address => mapping(bytes32 => mapping(uint256 => bool))) public s_delegatee;

    mapping(bytes32 => uint256) public s_raiseFailedProposals;


    //** ------------------------------------------------------------------ **//
    //                        GETTER FUNCTIONS                                //
    //** ------------------------------------------------------------------ **//

    function getProposalVotes(bytes32 raiseId_, uint256 proposalId_) external view returns (uint256, uint256, uint256) {
        return _getProposalVotes(raiseId_, proposalId_);
    }

    /**
     * @notice Get votes for, against, and total votes for a proposal
     *     @param raiseId unique id of a project.
     *     @param proposalId unique id of a proposal within the project.
     *     @return forVotes total in favor.
     *     @return againstVotes total against.
     *     @return totalVotes aggregate (for + against).
     *
     */
    function _getProposalVotes(bytes32 raiseId, uint256 proposalId) internal view returns (uint256, uint256, uint256) {
        // checks:
        bool validProposal = raiseBoxProposal.isValidProposal(raiseId, proposalId);

        uint256 forVotes = s_votesForProposal[raiseId][proposalId];
        uint256 againstVotes = votesAgainstProposal[raiseId][proposalId];
        uint256 totalVotes = (forVotes + againstVotes);

        if (validProposal) {
            return (forVotes, againstVotes, totalVotes);
        } 
    }

    function getAbsenteeVoters(bytes32 raiseId, uint256 proposalId) external view returns (uint256) {
        uint256 totalContributors = raiseBoxContribution.getTotalContributors(raiseId);
        (,, uint256 totalVotes) = _getProposalVotes(raiseId, proposalId);

        return (totalContributors - totalVotes);
    }

    function getVotingStartTime(bytes32 raiseId, uint256 proposalId) external view returns (uint256 voteStartTime) {
        return _voteStartTime(raiseId, proposalId);
    }

    function _voteStartTime(bytes32 raiseId, uint256 proposalId) internal view returns(uint256 voteStartTime) {
        raiseBoxProposal.isValidProposal(raiseId, proposalId);
        return s_votingStartTime[raiseId][proposalId];
    }

    function hasVotedForProposal(address contributor, bytes32 raiseId, uint256 proposalId)
        external
        view
        returns (bool)
    {
        return s_hasVotedOnProposal[raiseId][proposalId][contributor];
    }



    //** ------------------------------------------------------------------ **//
    //                        INTERNAL FUNCTIONS                              //
    //** ------------------------------------------------------------------ **//

    function _tallyVotes(bytes32 raiseId, uint256 proposalId) internal returns (uint256, uint256) {
        (uint256 forVotes, uint256 againstVotes, uint256 totalVotes) = _getProposalVotes(raiseId, proposalId);

        bool quorumReached = _isQuorumReached(
            raiseId,
            proposalId,
            forVotes,
            againstVotes
        );


        // if for is greater than against, proposal passed and % of funds will be dripped
        if (forVotes > againstVotes) {

            raiseBoxProposal.updateProposalInfo(raiseId, proposalId);

            emit RaiseBoxEventsLib.RaiseBoxVoting_tallyVotes_ProposalPassed(
                proposalId,
                forVotes,
                againstVotes,
                totalVotes,
                block.timestamp
            );

            // delegate call to dripHandler since proposal has passed
            raiseBoxDripHandler.dripFundsForProposal(raiseId, proposalId);
        } else {

            raiseBoxProposal.updateProposalInfo(raiseId, proposalId);

            emit RaiseBoxEventsLib.RaiseBoxVoting_tallyVotes_ProposalFailed(
                proposalId,
                forVotes,
                againstVotes,
                totalVotes,
                block.timestamp
            );

            s_raiseFailedProposals[raiseId]++;
            // revert RaiseBoxVoting_ProposalFailed();
        }

        emit VotesTallied(raiseId, proposalId, forVotes, againstVotes, totalVotes);

        return (forVotes, againstVotes);

    }

    function getFailedProposalsCount(bytes32 raiseId) external view returns (uint256) {
        return s_raiseFailedProposals[raiseId];
    }

    /// @dev sets voting ended for a given proposalId
    function _endVoting(bytes32 raiseId_, uint256 proposalId_) internal {

        s_votingEnded[raiseId_][proposalId_] = true;

        IRaiseBoxCore.RaiseInfo memory raiseInfo = raiseBoxCore.getRaiseInfo(raiseId_);

        (uint forVotes_, uint againstVotes_, ) = _getProposalVotes(raiseId_, proposalId_);

        raiseBoxCore.updateRaiseInfo(
        raiseInfo.raiseCreationInfo.projectInfo,
        raiseInfo.raiseCreationInfo.raiseCreatedAt,
        raiseInfo.raiseContributionInfo.amountRaisedByProject,
        raiseInfo.raiseCreationInfo.doesRaiseExist,
        raiseId_,
        raiseInfo.raiseCreationInfo.raiseOwner,
        forVotes_,
        againstVotes_,
        proposalId_
        );

        raiseBoxProposal.updateProposalState(
            raiseId_, 
            proposalId_, 
            IRaiseBoxProposal.ProposalState.INACTIVE
            );

       emit RaiseBoxEventsLib.RaiseBoxVoting_endVoting_VotingEndedSucessfully(block.timestamp);
    }




    // get number of votes casted by individual voter
    // function getVotesCasted(address user, bytes32 raiseId, uint256 proposalId) external returns (uint256 votesCasted) {

    //     return votesCasted;
    // }

    // to get funding drips from contributions, projects have to host proposals after every milestone achieved

    // max funds drip at anytime should be 25%
    // funds drip on very first proposal after raise is capped at 10%
    // 25% funds drip can only be dripped twice throughout project lifecycle
    // 25% fund drip cannot happen consecutively:
    // i.e after receiving a 25% fund drip, project cannot receive another 25%
    // in the very next drip
    // after first 25% fund drip, drips are capped at 15% untill a drip after the last 25% drip
    // drips %: in multiples of 5 up to 100
    // only 10% of overall funds contributed at time of hosting proposal is released per time

    // // 5, 10, 15, 20, 25 % fund drips only allowed
    // // fund drip logic to be implemented in RaiseBoxCore contract
    // // if proposalCount <= 1 => 10% fund drip
    // // if proposalCount == 2 => 25% fund drip
    // // if proposalCount > 2 && last fund drip != 25% => 25% fund drip
    // // if proposalCount > 2 && last fund drip == 25% => 15% fund drip
    // // else => 10% fund drip

    // criterias for voting:
    // 1. has contributed to project
    // 2. voting duration not exceeded
    // 3. has not voted before on proposal
    // 4. cannot delegate to self
    // 5. can only delegate once per proposal
    // 6. delegate must have contributed to project
    // 7. votes can only be tallied after voting duration has ended
    // 8. only project owner can tally votes
    // 9. can tally votes once voting duration + 5 minutes buffer(not for voting) elapsed
    // 10. cannot vote once either voting duration elapsed, everyone has voted including delegates, or voting has been ended manually by project owner
    // 11. votes can only be delegated before voting duration elapses
    // 12. once votes are tallied, voting is ended for that proposal
    // 13. only one level of delegation allowed -- ensured
    // i.e A delegates to B, B cannot delegate to C- a delegated vote cannot be re-delegated
    // 14. each contributor gets one vote per proposal regardless of amount contributed
    // 15. voting sides: yes/no (for/against)
    // 16. votes are public, anyone can see how many votes each support has at any time but actual voters(address) are private using zk-SNARKS (to be implemented in future versions)
    // 17. voting power cannot be transferred or sold?
    // 18. only one proposal can be active at a time per project - this is already enforced in RaiseBoxProposal contract
    // 19. project owner cannot vote on own proposals
    // 20. if a user has delegated their vote, they cannot vote directly on that proposal - obviously, they lose voting rights once they delegate
    // 21. voting cannot commence until proposal is hosted - to be enforced in RaiseBoxProposal contract
    // 22. voting results are final once tallied - no re-votes or re-tallies allowed
    // 23. in case of a tie, proposal is considered rejected
    // todo: implement quorum - 67% of votes should be casted for a proposal before it's declared successful and quorom is reached, otherwise, proposal fails

    /// if forvotes/totalvotes * 100 >= 67 the quoromhas been achieved and proposal passes

    uint256 immutable QUORUM = 67; // 67%

    uint256 constant PARTICIPATION_QUORUM = 25; // 25% of contributors
    uint256 constant APPROVAL_THRESHOLD = 67;   // 67% approval

    function _isParticipationQuorumReached(
    uint256 totalVotes,
    uint256 totalContributors
    ) internal pure returns (bool) {
        if (totalContributors == 0) return false;

        return (100 * totalVotes) >= (PARTICIPATION_QUORUM * totalContributors);
    }


    function _isApprovalThresholdReached(
    uint256 forVotes,
    uint256 totalVotes
    ) internal pure returns (bool) {
        if (totalVotes == 0) return false;

        return (100 * forVotes) >= (APPROVAL_THRESHOLD * totalVotes);
    }

    function _isProposalApproved(
    uint256 forVotes,
    uint256 againstVotes,
    uint256 totalContributors
    ) internal pure returns (bool) {
    uint256 totalVotes = forVotes + againstVotes;

        return
        _isParticipationQuorumReached(totalVotes, totalContributors) &&
        _isApprovalThresholdReached(forVotes, totalVotes);
    }





    function _isQuorumReached(bytes32 raiseId_, uint256 proposalId_, uint256 forVotes_, uint256 againstVotes_) internal returns (bool) {

        // sanitize inputs
        raiseBoxProposal.isValidProposal(raiseId_, proposalId_);

        // 100f >= 67t
        if ((100 * forVotes_) >= (QUORUM * (forVotes_ + againstVotes_))) {
            return true;
            // quorum is reached
            // pass proposal
        } else { return false; }

    }
}
