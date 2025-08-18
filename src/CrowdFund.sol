// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title CrowdFund - Decentralized crowdfunding contract
/// @author devhat
/// @notice This contract allows users to contribute ETH to a project, collects protocol fees, and enables withdrawals for project owner and protocol.
/// @dev Designed for EVM-compatible blockchains. Uses custom errors for gas efficiency.

contract CrowdFund is Ownable {
    // ----------------------------------------------------------------------- state variables -------------------------------------------------------------------------  //

    // State variables

    

    // protocol related state variables:
    address private protocol; //0x3989F40a2b256004A2866Ab0805859d30605Ca4a;
    address public protocolFeeAddress = address(0x1); // tentative.

    // contributors/users related state variables:
    mapping(address => uint256) public contributorsToAmountContributed;
    address[] private contributors;
    uint256 public totalAmountContributed;

    // voting related state variables: also contributor related
    uint256 public totalProtocolFees;
    uint256 private voteCastedForYes;
    uint256 private voteCastedForNo;
    uint256 private totalVotesCastedByContributors;

    // crownfund campaign related state variables
    mapping(address => ProjectCrownFundCampaignInfo[]) public crownFundCampaignByProject;
    mapping(address => uint256) public lastCampaignTimeByProject;
    ProjectCrownFundCampaignInfo[] public campaigns;
    mapping(address => uint256) public campaignCounterByProject;

    // proposal related state variables
    // to get funding drips from contributions, projects have to host proposals after every milestone achieved
    // only 10% of overall funds contributed at time of hosting proposal is released per time
    uint256 public lastProposalTime;
    MileStoneProposalDetails[] public proposals;
    mapping(address => uint256) public lastProposalTimeByProject;
    mapping(address => MileStoneProposalDetails[]) public proposalByProject;
    mapping(address => uint256) public proposalCounterByProject;
    uint256 public proposalCounter;
    uint256 public blockTimeOfLastProposal; // track all proposals made and update +30 days for each call to host proposal

    // CONSTANTS

    // ----------------------------------------------------------------------- constants -------------------------------------------------------------------------  //

    // proposal constants
    uint256 public constant INTERVAL_BETWEEN_PROPOSALS = 30 days; // DAYS == 36 proposals/year
    uint256 private constant PROTOCOL_FEE = 5; // 5%
    uint256 public constant MINIMUM_CONTRIBUTION = 0.01 ether; // 1e16
    uint256 public constant MAX_PERCENTAGE = 100;
    uint256 private constant APPROVAL_PERCENTAGE = 51; // 51% of contributors vote required for a proposal to pass and  10% funds released

    // ----------------------------------------------------------------------- structs -------------------------------------------------------------------------  //

    // structs
    //milestone struct to track proposals based on milestone reached
    struct MileStoneProposalDetails {
        // different milestones: mvp ready, testnet ready, distribution site ready,
        uint256 lastProposalTime;
        string description;
        string achievement;
        uint256 proposalId;
    }

    // campaign struct to track campaign hosted by project
    struct ProjectCrownFundCampaignInfo {
        string projectName;
        address projectOwner;
        string projectProblemStatement;
        uint256 amountToRaise;
        uint256 projectCampaignId;
        uint256 duration;
    }

    // ----------------------------------------------------------------------- enums -------------------------------------------------------------------------  //

    // enums

    // voting state enum
    enum VotingState {
        VOTING_LIVE,
        CALCULATING_RESULTS,
        VOTING_ENDED,
        WINNER_DECLARED
    }

    // contribution state enum
    enum ContributionState {
        CONTRIBUTION_LIVE,
        CONTRIBUTION_ENDED,
        WITHDRAWING_PROTOCOL_FEES
    }

    // ----------------------------------------------------------------------- errors -------------------------------------------------------------------------  //

    // Errors:

    // contribution related errors:
    error CrowdFund_ContributeMoreEth();
    error CrowdFund_NoContributionMade();
    error CrowdFund_ContributionFailed();
    error CrowdFund_InvalidContributionAmount();

    // protocol fees related errors:
    error CrowdFund_NoFeesToWithdraw();
    error CrowdFund_FeesWithdrawalFailed();
    error CrowdFund_OnlyProtocolCanWithdrawFees();

    // protocol campaign escrow related errors:
    error CrowdFund_ProtocolAddressCannotBeZeroAddress();

    //project related errors:
    error CrowdFund_OnlyProjectOwnerCanWithdrawFunds();
    error CrowdFund_OnlyProjectOwnerCanCall();

    // proposal voting related errors
    error CrowdFund_NoVoteCasted();

    // ----------------------------------------------------------------------- events -------------------------------------------------------------------------  //

    // events emitted:

    // contribution related events:
    event Contributed(address indexed user, uint256 amount);

    // protocol fees related events:
    event ProtocolFeesWithdrawn(address indexed protocol, uint256 fees);

    // project related events:
    event FundsWithdrawn(address indexed projectOwner, uint256 funds);

    // proposal related events:
    event NewProposalHosted(
        address indexed projectOwner,
        uint256 proposalId,
        string proposalDescription,
        string proposalAchievement,
        uint256 timestamp,
        uint256 numberOfProposalsHosted
    );
    event ProposalPassed();

    // ----------------------------------------------------------------------- constructor -------------------------------------------------------------------------  //

    // constructor
    constructor() Ownable(msg.sender) {
        protocol = owner(); // this sets proposal as owner/deployer of crowdfund contract
    }

    // ----------------------------------------------------------------------- modifiers -------------------------------------------------------------------------  //

    // modifiers:

    // this modifier ensures that only users that have contributed to a raise return true and can vote on proposals

    // contributors related modifiers:
    modifier onlyContributors() {
        require(
            contributorsToAmountContributed[msg.sender] > 0,
            "User is not a contributor: Contribute to enter"
        );
        _;
    }

    // protocol related modifiers:
    // only protocol functions
    modifier onlyProtocol() {
        if (msg.sender != protocolFeeAddress) {
            revert CrowdFund_OnlyProtocolCanWithdrawFees();
        }

        _;
    }

    // ----------------------------------------------------------------------- functions -------------------------------------------------------------------------  //

    function createCrownFundCampaign(
        address projectOwner, uint256 durationOfRaise, uint256 targetAmount
    ) public returns (uint256 crowdFundId) {
        // this simply updates the projectcrowdfundcampaigninfo struct variable, updates affected states and emits event if successful or reverts if conditions fail
        // returns a unique crowdfund id which can be used to track, monitor a campaign.
        require(
            projectOwner != address(0),
            "zero address cannot host campaign"
        );

        return crowdFundId;

        /**
         * struct ProjectCrownFundCampaignInfo {
        string projectName;
        address projectOwner;
        string projectProblemStatement;
        uint256 amountToRaise;
        
    }
         */
    }

    function updateProtocolOwner(address newProtocolOwner) external onlyOwner {
        require(
            newProtocolOwner != address(0),
            "new protocol owner cannot be zero address"
        );
        newProtocolOwner = protocol;
    } // needed for testing - should be removed.

    function calculateProtocolFees(
        uint256 _contribution
    ) internal pure returns (uint256) {
        if (_contribution == 0) {
            revert CrowdFund_NoContributionMade();
        }
        return (PROTOCOL_FEE * _contribution) / MAX_PERCENTAGE; // returns in ether
    }

    // Contribute ETH to the project
    /// @notice Contribute ETH to the project
    /// @dev Send ETH with this function. Protocol fee is deducted to be sent to protocol address.
    /// @param amount The amount of ETH to contribute (should match msg.value)
    /// @notice funds are kept in escrow by the protocol pending release to project

    function contribute(uint256 amount) public payable {
        // Checks
        if (amount < MINIMUM_CONTRIBUTION) {
            revert CrowdFund_ContributeMoreEth();
        }

        if (contributorsToAmountContributed[msg.sender] == 0) {
            contributors.push(msg.sender);
        }

        uint256 protocolFee = calculateProtocolFees(amount);
        uint256 actualAmountContributed = (amount - protocolFee);

        // Effects

        totalProtocolFees += protocolFee;

        // Interactions
        (bool success, ) = protocol.call{value: actualAmountContributed}(""); // funds sent to protocol for safekeeping pending release to project
        if (!success) {
            revert CrowdFund_ContributionFailed();
        }

        totalAmountContributed += actualAmountContributed; // check if this updates properly...
        contributorsToAmountContributed[msg.sender] += amount;

        emit Contributed(msg.sender, amount);
    }

    // approve Vote for milestone approval and funds withdrawal
    /// @notice protocol counts votes and approves milestone based on highest vote received for or against proposal
    /// @dev Only callable by protocol

    function approveMilestoneProposal() external onlyProtocol {
        VotingState votingState;
        require(votingState != VotingState.VOTING_LIVE, "voting has not ended");
    }


    function calculateVotePercentage()
        internal
        returns (uint256 yesPercentage, uint256 noPercentage)
    {
        if (totalVotesCastedByContributors == 0) {
            revert CrowdFund_NoVoteCasted();
        }
        yesPercentage = ((voteCastedForYes / totalVotesCastedByContributors) /
            100);
        noPercentage = ((voteCastedForNo / totalVotesCastedByContributors) /
            100);
        VotingState votingState = VotingState.VOTING_ENDED;

        return (yesPercentage, noPercentage);
    }


    // Vote for milestone approval and funds withdrawal
    /// @notice contributors vote for milestone approval and protocol releases x% of funds to project if proposal is approved
    /// @dev Only callable by a contributor

    function voteForProposal() public onlyContributors {
        VotingState votingState = VotingState.VOTING_LIVE;
    }

    // function to host a proposal by project:

    function hostProposal(
        string memory _description,
        string memory _achievement,
        address project
    ) public {
        require(
            block.timestamp >=
                lastProposalTimeByProject[msg.sender] +
                    INTERVAL_BETWEEN_PROPOSALS,
            "cannot host another proposal yet."
        );

        require(
            bytes(_description).length > 0,
            "description cannot be empty string"
        );
        require(
            bytes(_achievement).length > 0,
            "achievement cannot be empty string"
        );

        require(project != address(0), "project owner cannot be zero address");
        require(
            msg.sender == project,
            "only project owner can host proposal"
        );

        MileStoneProposalDetails
            memory milestoneProposal = MileStoneProposalDetails({
                lastProposalTime: block.timestamp,
                description: _description,
                achievement: _achievement,
                proposalId: proposalCounterByProject[msg.sender]
            });

        proposals.push(milestoneProposal);
        lastProposalTimeByProject[msg.sender] = block.timestamp;
        proposalCounterByProject[msg.sender] += 1;
        blockTimeOfLastProposal = lastProposalTimeByProject[msg.sender] + 30 days;
        // numberOfProposalsHosted += 1;

        emit NewProposalHosted(
            msg.sender,
            milestoneProposal.proposalId,
            _description,
            _achievement,
            block.timestamp,
            proposalCounterByProject[msg.sender]
        );
    }

    // Withdraw accumulated protocol fees
    /// @notice Withdraw accumulated protocol fees to the protocol address
    /// @dev Only callable by protocol address

    function withdrawProtocolFees() external onlyProtocol {
        if (totalProtocolFees == 0) {
            revert CrowdFund_NoFeesToWithdraw();
        }
        if (address(protocolFeeAddress) == address(0)) {
            revert CrowdFund_ProtocolAddressCannotBeZeroAddress();
        }

        totalProtocolFees = 0; // Reset before transfer to prevent reentrancy

        // Interactions
        (bool success, ) = protocolFeeAddress.call{value: totalProtocolFees}(
            ""
        ); // this should be sent to protocolFees address - will implement
        if (!success) {
            revert CrowdFund_FeesWithdrawalFailed();
        }

        emit ProtocolFeesWithdrawn(protocol, totalProtocolFees);
    }

    // Allow contract to receive ETH
    /// @notice Allow contract to receive ETH directly
    receive() external payable {}

    // notes of task for commit message:
    // 1. added getter functions
    // 2. added getter function tests
    // 3. tested contribute function

    // if target is not reached within the alloted time then contributors should be refunded their contributions
    // but should protocol should keep fees?

    function withdrawFundsRaised(
        uint256 amountToWithdraw
    ) external onlyProtocol {
        // this function implements withdrawal of raised funds by the projectOwner
        // only a project owner can call this function
        // emit FundsWithdrawn(projectOwner, amountToWithdraw);
    }

    // getter functions

    function getContributors() public view returns (address[] memory) {
        return contributors;
    }

    function getAmountContributedByContributor(
        address _contributor
    ) public view returns (uint256) {
        return contributorsToAmountContributed[_contributor];
    }

    function getProtocolFee(
        uint256 amountToContribute
    ) public view returns (uint256) {
        return calculateProtocolFees(amountToContribute); // updated the implementation for this
    }

    function getTotalAmountContributed() public view returns (uint256) {
        return totalAmountContributed;
    }

    function getTotalProtocolFees() public view returns (uint256) {
        return totalProtocolFees;
    }

    function getProposals(
        address __projectOwner
    ) public view returns (MileStoneProposalDetails[] memory) {
        return proposalByProject[__projectOwner];
    }

    function getProtocol() public view returns (address) {
        return protocol;
    }

    function getMilestoneProposalDetails(
        address _project
    ) public view returns (MileStoneProposalDetails[] memory) {
        return proposals;
    }
}
