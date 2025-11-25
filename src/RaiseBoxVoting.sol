// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IRaiseBoxVoting} from "../src/interfaces/IRaiseBoxVoting.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {IRaiseBoxProposal} from "../src/interfaces/IRaiseBoxProposal.sol";
import "../lib/forge-std/src/Test.sol";


contract RaiseBoxVoting is IRaiseBoxVoting {

    IRaiseBoxCore public immutable raiseBoxCore; // the central contract that holds main storage of raisebox
    IRaiseBoxContribution public immutable raiseBoxContribution; // contribution contract

    IRaiseBoxProposal public raiseBoxProposal; // proposal contract
    address public owner;

    mapping(bytes32 => mapping(uint256 => mapping(address => bool))) public hasVotedOnProposal; // projectId => proposalId => voter => hasVoted

    mapping (address => mapping(bytes32 => mapping(uint256 => address))) public hasDelegatedVote; // from => projectId => proposalId => to

    mapping (bytes32 => mapping(uint256 => uint256)) public votesForProposal; // projectId => proposalId => votesFor

    mapping (bytes32 => mapping(uint256 => bool)) public votingEnded; // projectId => proposalId => votingEnded

    mapping(bytes32 => mapping(uint256 => uint256)) public votingStartTime;

    uint256 public constant VOTING_DURATION = 7 days;

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

    constructor(address raiseBoxCoreAddress, address raiseBoxContributionAddress) {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
        raiseBoxContribution = IRaiseBoxContribution(raiseBoxContributionAddress);
        owner = msg.sender;
    }

    /// @notice Set the RaiseBoxProposal contract address (callable by deployer)
    function setProposalContract(address proposalContract) external {
        require(msg.sender == owner, "Only owner");
        raiseBoxProposal = IRaiseBoxProposal(proposalContract);
    }

    modifier canVote(bytes32 projectId, address user, uint256 proposalId) {

        // ascertain msg.sender has contributed to project
        bool hasContributedToProject = raiseBoxContribution.getHasContributed(projectId, user);

        if (!hasContributedToProject) {
            revert RaiseBoxVoting_UserNotContributor(projectId, user);
        }

        if (votingEnded[projectId][proposalId]) {
            revert RaiseBoxVoting_VotingEnded(projectId, proposalId);
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
            revert RaiseBoxVoting_VotingEnded(projectId, proposalId);
        }

        if (hasVotedOnProposal[projectId][proposalId][user]) {
            revert RaiseBoxVoting_AlreadyVoted(proposalId);
        }
        _;
    }


    function vote(bytes32 projectId, uint256 proposalId, bool side, address voter) external canVote(projectId, voter, proposalId) {

        // effects:
        hasVotedOnProposal[projectId][proposalId][voter] = true;

        if (side) {
            votesForProposal[projectId][proposalId] += 1;
        }

        emit Voted(voter, projectId, proposalId, side);

    }

    function setVotingStartTime(bytes32 projectId, uint256 proposalId, uint256 startTime) external {
        // only the proposal contract should be able to set voting start times
        if (msg.sender != address(raiseBoxProposal)) {
            revert("Only proposal contract");
        }
        votingStartTime[projectId][proposalId] = startTime;
    }

    function delegateVote(bytes32 projectId, uint256 proposalId, address from, address to) external canVote(projectId, from, proposalId) canVote(projectId, to, proposalId) {

        if (to == from) {
            revert RaiseBoxVoting_CannotDelegateToSelf();
        }


        emit VoteDelegated(from, to);


    }

    function tallyVotes(bytes32 projectId, uint256 proposalId) external returns (uint256 forVotes, uint256 againstVotes) {
        uint256 totalProposalVotes = this.getTotalProposalVotes(projectId, proposalId); 


        return (forVotes, againstVotes);

        


        emit VotesTallied(projectId, proposalId, totalProposalVotes);

        

    }

    function _isValidProposal(bytes32 projectId, uint256 proposalId) internal returns (bool) {
        // get proposalCount
        uint256 propCount = raiseBoxProposal.getProposalCount(projectId);

        // get proposalDetails
        IRaiseBoxProposal.MileStoneProposalDetails memory propDetails = raiseBoxProposal.getProposalDetails(projectId, proposalId);

        if (propDetails.proposalId <= propCount) {
            return true;
        } 
    }
    

    function getTotalProposalVotes(bytes32 projectId, uint256 proposalId) external  returns (uint256) {
        // checks:
        bool validProposal = _isValidProposal(projectId, proposalId);

        if (validProposal) {
             return votesForProposal[projectId][proposalId];
        }

       
    }

    



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

}
