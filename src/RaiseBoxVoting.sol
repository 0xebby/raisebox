// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import "../lib/forge-std/src/Test.sol";
import {IRaiseBoxDripHandler} from "src/interfaces/IRaiseBoxDripHandler.sol";

contract RaiseBoxVoting is IRaiseBoxVoting {
    IRaiseBoxCore public immutable raiseBoxCore; // the central contract that holds main storage of raisebox
    IRaiseBoxContribution public immutable raiseBoxContribution; // contribution contract

    IRaiseBoxProposal public immutable raiseBoxProposal; // proposal contract

    IRaiseBoxDripHandler public immutable raiseBoxDripHandler; // drip contract

    address public owner;

   

    constructor(address raiseBoxCoreAddress, address raiseBoxContributionAddress, address raiseBoxProposalAddress, address raiseBoxDripHandlerAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
        raiseBoxContribution = IRaiseBoxContribution(raiseBoxContributionAddress);
        raiseBoxProposal = IRaiseBoxProposal(raiseBoxProposalAddress);
        raiseBoxDripHandler = IRaiseBoxDripHandler(raiseBoxDripHandlerAddress);
        owner = msg.sender;
    }

    // address public raiseBoxContribution = raiseBoxCore.getContributionContract();
    // address public raiseBoxProposal = raiseBoxCore.getProposalContract();
    // address public raiseBoxDripHandler = raiseBoxCore.getDripHandlerContract();

    // /// @notice Set the RaiseBoxProposal contract address (callable by deployer)
    // function setProposalContract(address proposalContract) external {
    //     require(msg.sender == owner, "Only owner");
    //     raiseBoxProposal = IRaiseBoxProposal(proposalContract);
    // }

    modifier canVote(bytes32 projectId, address user, uint256 proposalId) {
        // ascertain msg.sender has contributed to project
        bool hasContributedToProject = raiseBoxContribution.getHasContributed(projectId, user);

        // if (msg.sender == raiseBoxCore.getRaiseCreator(projectId)) {
        //     revert RaiseBoxVoting_RaiseCreator(msg.sender);
        // } -- cannot even vote since owner cannot contribute -- ebby

        if (!hasContributedToProject) {
            revert RaiseBoxVoting_NotContributor(projectId, user);
        }

        if (votingEnded[projectId][proposalId]) {
            revert RaiseBoxVoting_VotingEnded(projectId, proposalId);
        }

        if (hasDelegatedForProposal[user][projectId][proposalId]) {
            revert RaiseBoxVoting_AlreadyDelegatedVote(user);
        }

        uint256 _start = votingStartTime[projectId][proposalId];

        // voting must have been scheduled (start set) before voting commences
        if (_start == 0) {
            revert RaiseBoxVoting_VotingNotStarted(projectId, proposalId);
        }

        // voting not yet started (start is in future)
        if (block.timestamp < _start) {
            revert RaiseBoxVoting_VotingNotStarted(projectId, proposalId);
        }

        // if voting elapsed, mark ended and revert
        if (block.timestamp >= _start + VOTING_DURATION) {
            votingEnded[projectId][proposalId] = true;
            _tallyVotes(projectId, proposalId);

            revert RaiseBoxVoting_VotingEnded(projectId, proposalId);
        }

        if (hasVotedOnProposal[projectId][proposalId][user]) {
            revert RaiseBoxVoting_AlreadyVoted(proposalId, user);
        }
        _;
    }

    // special ownerOnly function that triggers vote end incase no voting attempt is made  after voting duration elapsed, this has to happen to trigger vote tallying and eventual funds drip

    function triggerVoteTally(bytes32 projectId, uint256 proposalId) external {
        if (msg.sender != raiseBoxCore.getRaiseCreator(projectId)) { revert RaiseBoxVoting_NotRaiseOwner(msg.sender);}

        uint256 _start = votingStartTime[projectId][proposalId];

        if (votingEnded[projectId][proposalId]) { revert RaiseBoxVoting_VotingEnded(projectId , proposalId); }

        // if voting elapsed, mark ended and emit events:
        if (block.timestamp >= _start + VOTING_DURATION) {
            votingEnded[projectId][proposalId] = true;
            _tallyVotes(projectId, proposalId);
        } else {
            revert RaiseBoxVoting_VotingNotEnded();
        }

        emit RaiseBoxVoting_VoteTallyTriggered(msg.sender, proposalId, block.timestamp);
        emit RaiseBoxVoting_VotingEndedSucessfully();

    }

    // function endVoting(bytes32 projectId, uint256 proposalId) external {
    //     votingEnded[projectId][proposalId] = true;
    // }

    function vote(bytes32 projectId, uint256 proposalId, bool side, address voter)
        external
        canVote(projectId, voter, proposalId)
    {

            if (delegatee[voter][projectId][proposalId]) {

            if (side) {
                votesForProposal[projectId][proposalId] += (delegatedVotes[voter][projectId][proposalId] + 1); // votes delegated to voter plus his vote
            } else {
                votesAgainstProposal[projectId][proposalId] += (delegatedVotes[voter][projectId][proposalId] + 1);
            }
        } else {
            if (side) {
                votesForProposal[projectId][proposalId] += 1;
            } else {
                votesAgainstProposal[projectId][proposalId] += 1;
            }
        }

        hasVotedOnProposal[projectId][proposalId][voter] = true;

        emit Voted(voter, projectId, proposalId, side);
    }

    /**
     * @notice Set voting start time for a proposal (calls restircted to proposal contract)
     *     @dev sets the start time for voting on a specific proposal within a project.
     *     @param projectId unique id of a project.
     *     @param proposalId unique id of a proposal within the project.
     *     @param startTime voting start time.
     *     @dev emits VotingStartTimeSet to mark success.
     *
     *
     */
    function setVotingStartTime(bytes32 projectId, uint256 proposalId, uint256 startTime) external {

        // only the proposal contract should be able to set voting start times
        if (msg.sender != address(raiseBoxProposal)) {
            revert("Only proposal contract");
        }
        votingStartTime[projectId][proposalId] = startTime;

        emit VotingStartTimeSet(projectId, proposalId, startTime);
    }



    function delegateVote(bytes32 projectId, uint256 proposalId, address from, address to) external 
    /**
     * canVote(projectId, from, proposalId) canVote(projectId, to, proposalId)
     */
    {
        if (to == from) {
            revert RaiseBoxVoting_CannotDelegateToSelf();
        }

        if (to == address(0)) {
            revert RaiseBoxVoting_DelegationToZeroAddress(address(0));
        }

        if (hasDelegatedForProposal[from][projectId][proposalId]) {
            revert RaiseBoxVoting_CannotDelegateTwice();
        }

        if (hasVotedOnProposal[projectId][proposalId][from] || hasVotedOnProposal[projectId][proposalId][to]) {
            revert RaiseBoxVoting_CannotDelegateAfterVoting(proposalId, from);
        }

        // record delegation
        delegatedVoteTo[from][projectId][proposalId] = to;
        // add voting right to 'to' address

        delegatedVotes[to][projectId][proposalId] += 1;
        hasDelegatedForProposal[from][projectId][proposalId] = true;
        delegatee[to][projectId][proposalId] = true;

        emit VoteDelegated(from, to);
    }



    function _tallyVotes(bytes32 projectId, uint256 proposalId)
        internal
        returns (uint256 forVotes, uint256 againstVotes)
    {
        (uint256 forVotes, uint256 againstVotes, uint256 totalVotes) = this.getProposalVotes(projectId, proposalId);

        if (forVotes > againstVotes) {
            // delegate call to dripHandler
            raiseBoxDripHandler.dripFundsForProposal(projectId, proposalId);
        } else {
            revert RaiseBoxVoting_ProposalFailed();
        }

        // if for is greater than against, proposal passed and % of funds will be dripped

        emit VotesTallied(projectId, proposalId, forVotes, againstVotes, totalVotes);

        return (forVotes, againstVotes);
    }

    function _isValidProposal(bytes32 projectId, uint256 proposalId) internal returns (bool) {
        // get proposalCount
        uint256 propCount = raiseBoxProposal.getProposalCount(projectId);

        // get proposalDetails
        IRaiseBoxProposal.MileStoneProposalDetails memory propDetails =
            raiseBoxProposal.getProposalDetails(projectId, proposalId);

        if (propDetails.proposalId <= propCount) {
            return true;
        }
    }

    /**
     * @notice Get votes for, against, and total votes for a proposal
     *     @param projectId unique id of a project.
     *     @param proposalId unique id of a proposal within the project.
     *     @return forVotes total in favor.
     *     @return againstVotes total against.
     *     @return totalVotes aggregate (for + against).
     *
     */
    function getProposalVotes(bytes32 projectId, uint256 proposalId)
        external
        returns (uint256 forVotes, uint256 againstVotes, uint256 totalVotes)
    {
        // checks:
        bool validProposal = _isValidProposal(projectId, proposalId);

        forVotes = votesForProposal[projectId][proposalId];
        againstVotes = votesAgainstProposal[projectId][proposalId];
        totalVotes = forVotes + againstVotes;

        if (validProposal) return (forVotes, againstVotes, totalVotes);
    }

    function getVoteStartTime(bytes32 projectId, uint256 proposalId) external view returns (uint256 voteStartTime) { return votingStartTime[projectId][proposalId]; }

    function hasVotedForProposal(address contributor, bytes32 projectId, uint256 proposalId)
        external
        view
        returns (bool)
    {
        return hasVotedOnProposal[projectId][proposalId][contributor];
    }



    // state variables:

    
    mapping(bytes32 => mapping(uint256 => mapping(address => bool))) public hasVotedOnProposal; // projectId => proposalId => voter => hasVoted

    mapping(address => mapping(bytes32 => mapping(uint256 => address))) public delegatedVoteTo; // from => projectId => proposalId => to

    mapping(bytes32 => mapping(uint256 => uint256)) public votesForProposal; // projectId => proposalId => votesFor

    mapping(bytes32 => mapping(uint256 => uint256)) public votesAgainstProposal; // projectId => proposalId => votesAgainst

    mapping(bytes32 => mapping(uint256 => bool)) public votingEnded; // projectId => proposalId => votingEnded

    mapping(bytes32 => mapping(uint256 => uint256)) public votingStartTime;

    uint256 public constant VOTING_DURATION = 7 days;

    mapping(address => mapping(bytes32 => mapping(uint256 => uint256))) public delegatedVotes; // address => number of delegated votes received

    mapping(address => bool) public delegated;

    // delegated votes tracker scoped to proposal:
    mapping(address => mapping(bytes32 => mapping(uint256 => bool))) public hasDelegatedForProposal; // address => projectId => proposalId => hasDelegated

    mapping(address => mapping(bytes32 => mapping(uint256 => bool))) public delegatee;

    // get number of votes casted by individual voter
    // function getVotesCasted(address user, bytes32 projectId, uint256 proposalId) external returns (uint256 votesCasted) {

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
    // 13. only one level of delegation allowed?
    // i.e A delegates to B, B cannot delegate to C- a delegated vote cannot be re-delegated
    // 14. each contributor gets one vote per proposal regardless of amount contributed
    // 15. voting sides: yes/no (for/against)
    // 16. votes are public, anyone can see how many votes each side has at any time but actual voters(address) are private using zk-SNARKS (to be implemented in future versions)
    // 17. voting power cannot be transferred or sold?
    // 18. only one proposal can be active at a time per project - this is alreay enforced in RaiseBoxProposal contract
    // 19. project owner cannot vote on own proposals
    // 20. if a user has delegated their vote, they cannot vote directly on that proposal - obviously, they lose voting rights once they delegate
    // 21. voting cannot commence until proposal is hosted - to be enforced in RaiseBoxProposal contract
    // 22. voting results are final once tallied - no re-votes or re-tallies allowed
    // 23. in case of a tie, proposal is considered rejected
}
