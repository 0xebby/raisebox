// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../lib/forge-std/src/Test.sol";
import {RaiseBoxCreation} from "../src/RaiseBoxRaiseCreation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RaiseBoxContribution} from "../src/RaiseBoxContribution.sol";
import {RaiseBoxProposal} from "../src/RaiseBoxProposal.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {RaiseBoxVoting} from "../src/RaiseBoxVoting.sol";
import {RaiseBoxDripHandler} from "src/RaiseBoxDripHandler.sol";
import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxProposal} from "src/interfaces/IRaiseBoxProposal.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MockToken} from "src/mock/MockToken.sol";


contract TestsHelpers is Test {
    // main contract that holds general storage
    RaiseBoxCore raiseBoxCore;

    // project creation contract
    RaiseBoxCreation raiseBoxRaiseCreationContract;

    // contribution contract
    RaiseBoxContribution raiseBoxContributionContract;

    // proposal contract
    RaiseBoxProposal raiseBoxProposalContract;

    // voting contract
    RaiseBoxVoting raiseBoxVoting;

    // drip handler:
    RaiseBoxDripHandler raiseBoxDripHandler;

    // faucet contract address
    // address faucetToken = 0xB15D5A9DCcCCcb3Caf55360D89610834A72Cf6b3;

    MockToken raiseBoxToken;

    uint256 public constant INITIAL_SUPPLY = 100_000;
    

    // raisebox testOwner == deployer
    address testOwner;

    // make dummy addresses for test
    address alice = makeAddr("alice");
    address joe = makeAddr("joe");
    address ben = makeAddr("ben");
    address max = makeAddr("max");
    address uche = makeAddr("uche");
    address sam = makeAddr("sam");
    address mark = makeAddr("mark");
    address sally = makeAddr("sally");
    address ebby = makeAddr("ebby");
    address vitalik = makeAddr("vitalik");

    address gowagr = makeAddr("gowagr");
    address polymarket = makeAddr("polymarket");
    address base = makeAddr("base");
    address trump = makeAddr("trump");
    address elon = makeAddr("elon");
    address magiceden = makeAddr("magiceden");
    address tether = makeAddr("tether");
    address openseas = makeAddr("openseas");
    address ethereum = makeAddr("ethereum");
    address arbitrum = makeAddr("arbitrum");
    address carl = makeAddr("carl");
    address zeroAddress = address(0);
    address whale = makeAddr("whale");
    address latecomer;
    address raiseCreator = makeAddr("raiseCreator");

    /// contributors for endToEndRaiseTest
    address contributor1 = makeAddr("contributor 1");

    address contributor2 = makeAddr("contributor 2");

    address contributor3 = makeAddr("contributor 3");

    address contributor4 = makeAddr("contributor 4");

    address contributor5 = makeAddr("contributor 5");

    address creator = makeAddr("creator");

    
    /// @notice raise targets for small, medium and large:
    uint256 RAISE_TARGET_SMALL = 10 ether;
    uint256 RAISE_TARGET_MEDIUM = 100 ether;
    uint256 RAISE_TARGET_LARGE = 1000 ether;

    /// @notice raise duration for small, medium and large:
    uint256 RAISE_DURATION_SMALL = 30 weeks;
    uint256 RAISE_DURATION_MEDIUM = 50 weeks;
    uint256 RAISE_DURATION_LARGE = 60 weeks;

    // raise ids:
    bytes32 raiseIdSmall;
    bytes32 raiseIdMedium;
    bytes32 raiseIdLarge;

    // get  would be ca of raisebox - project creation contract

    using Strings for uint256;

    address raiseBoxOwner;

    function setUp() public {
        vm.startPrank(address(this)); 

        // raiseBoxToken: token used for interaction alongside eth:
        raiseBoxToken  = new MockToken(INITIAL_SUPPLY);

        // deploy the main contract that holds general storage
        raiseBoxCore = new RaiseBoxCore();

        raiseBoxOwner = raiseBoxCore.getRaiseBoxOwner();

        // setter.setRaiseBoxCore(address())

        raiseBoxRaiseCreationContract = new RaiseBoxCreation(address(raiseBoxCore));

        raiseBoxCore.setRaiseCreationContract(address(raiseBoxRaiseCreationContract));

        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore));

        raiseBoxCore.setProposalContract(address(raiseBoxProposalContract));

        raiseBoxDripHandler =
            new RaiseBoxDripHandler(address(raiseBoxCore), address(raiseBoxProposalContract), address(0));

        raiseBoxCore.setDripHandlerContract(address(raiseBoxDripHandler));

        raiseBoxContributionContract = new RaiseBoxContribution(address(raiseBoxCore), address(raiseBoxDripHandler));

        raiseBoxCore.setContributionContract(address(raiseBoxContributionContract));

        raiseBoxVoting = new RaiseBoxVoting(
            address(raiseBoxCore),
            address(raiseBoxContributionContract),
            address(raiseBoxProposalContract),
            address(raiseBoxDripHandler)
        );

        raiseBoxCore.setVotingContract(address(raiseBoxVoting));

        raiseBoxProposalContract.setVotingContract(address(raiseBoxVoting));
        // let proposal contract know the drip handler so it can read dripped totals
        raiseBoxProposalContract.setDripHandlerContract(address(raiseBoxDripHandler));

        raiseBoxDripHandler.setVoting(address(raiseBoxVoting));
        raiseBoxDripHandler.setContribution(address(raiseBoxContributionContract));

        vm.stopPrank();

        testOwner = address(this);
        vm.deal(testOwner, 500 ether);
        vm.deal(alice, 100 ether);
        vm.deal(joe, 100 ether);
        vm.deal(ben, 100 ether);
        vm.deal(max, 100 ether);
        vm.deal(uche, 100 ether);
        vm.deal(sam, 100 ether);
        vm.deal(mark, 100 ether);
        vm.deal(sally, 100 ether);
        vm.deal(ebby, 100 ether);
        vm.deal(vitalik, 100 ether);
        vm.deal(carl, 100 ether);

        // voters
        vm.deal(arbitrum, 100 ether);
        vm.deal(openseas, 100 ether);
        vm.deal(magiceden, 100 ether);
        vm.deal(base, 100 ether);
        vm.deal(ethereum, 100 ether);
        vm.deal(tether, 100 ether);
        vm.deal(elon, 100 ether);
        vm.deal(trump, 100 ether);
        vm.deal(gowagr, 100 ether);
        vm.deal(polymarket, 100 ether);
        vm.deal(whale, 50_000 ether);
        vm.deal(latecomer, 300 ether);

        /// fund contributors for endToEndRaise
        vm.deal(contributor1, 100 ether);

        vm.deal(contributor2, 100 ether);

        vm.deal(contributor3, 100 ether);

        vm.deal(contributor4, 100 ether);

        vm.deal(contributor5, 100 ether);

        // Set token after all contracts are deployed
        // vm.startPrank(owner);
        raiseBoxCore.setAcceptedToken(address(raiseBoxToken));
        // vm.stopPrank();
        
        raiseBoxCore.verifyAndAddToWhitelist(testOwner);

        // whitelist 2 users to serve as raiseCreators:
        raiseBoxCore.verifyAndAddToWhitelist(ebby);
        raiseBoxCore.verifyAndAddToWhitelist(vitalik);
        raiseBoxCore.verifyAndAddToWhitelist(ben);
        raiseBoxCore.verifyAndAddToWhitelist(arbitrum);
        // whitelist raiseCreator:
        raiseBoxCore.verifyAndAddToWhitelist(raiseCreator);

        raiseBoxCore.verifyAndAddToWhitelist(uche);
        raiseBoxCore.verifyAndAddToWhitelist(max);
        raiseBoxCore.verifyAndAddToWhitelist(sally);
        raiseBoxCore.verifyAndAddToWhitelist(carl);
        raiseBoxCore.verifyAndAddToWhitelist(creator);

        // warp time
        advanceBlockTime(10 days);

    /// @notice project info for small, mediumand large project:
    /// small:
    IRaiseBoxCore.ProjectInfo memory projectInfoSmall = IRaiseBoxCore.ProjectInfo({
            projectName: "small project",
            valueProposition: "small project value proposition",
            raiseTarget: RAISE_TARGET_SMALL,
            projectDuration: RAISE_DURATION_SMALL
        });

    /// medium:
    IRaiseBoxCore.ProjectInfo memory projectInfoMedium = IRaiseBoxCore.ProjectInfo({
            projectName: "medium project",
            valueProposition: "medium project value proposition",
            raiseTarget: RAISE_TARGET_MEDIUM,
            projectDuration: RAISE_DURATION_MEDIUM
        });

    /// large:
    IRaiseBoxCore.ProjectInfo memory projectInfoLarge = IRaiseBoxCore.ProjectInfo({
            projectName: "large project",
            valueProposition: "large project value proposition",
            raiseTarget: RAISE_TARGET_LARGE,
            projectDuration: RAISE_DURATION_LARGE
        });

    /// @notice create raises with the targets above:
    /// @notice ebby, vitalik and ben have been whitelisted in setup
    vm.startPrank(ebby);
        raiseIdSmall = raiseBoxRaiseCreationContract.createNewRaise(
        projectInfoSmall
        );
    vm.stopPrank();

    vm.startPrank(vitalik);
    raiseIdMedium = raiseBoxRaiseCreationContract.createNewRaise(
        projectInfoMedium
    );
    vm.stopPrank();

    vm.startPrank(ben);
    raiseIdLarge = raiseBoxRaiseCreationContract.createNewRaise(
        projectInfoLarge
    );

 }

    /**
     * @dev Helper function to simulate time passing since testing environment doesn't work as expected
     * @param raiseDuration_ amount of time to advanced, could be in days, hours, minutes or seconds. default is seconds*
     */
    function advanceBlockTime(uint256 raiseDuration_) internal {
        vm.warp(block.timestamp + raiseDuration_);
        emit RaiseBoxEventsLib.BlockTimeAdvancedBy(raiseDuration_);
    }

    function contributeToTestProject() public returns (bytes32 projectId) {
        vm.startPrank(ben);
        projectId = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
            projectName:"sentient",
            valueProposition:"agi",
            raiseTarget:20 ether,
            projectDuration:60 weeks
        })
        );
        vm.stopPrank();

        address[20] memory contributors = [
            ebby, sally, uche, 
            max, mark, alice, 
            joe, testOwner, sam, 
            vitalik, arbitrum, ethereum, 
            polymarket, elon, trump, 
            tether, base, magiceden, 
            gowagr, openseas
            ];

        for (uint256 i = 0; i < contributors.length; i++) {
            vm.startPrank(contributors[i]);
            raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, projectId);
            vm.stopPrank();
        }

        return projectId;
    }

    function _hostProposalAndCompleteVotingFlow(
        bytes32 raiseId,
        address proposer,
        address nonContributor,
        string memory description,
        string memory milestone,
        uint256 dripPercent
    ) internal returns (uint256 proposalId) {
        return _hostProposalAndCompleteVotingFlow(
            raiseId,
            proposer,
            nonContributor,
            description,
            milestone,
            dripPercent,
            false
        );
    }

    function _hostProposalAndCompleteVotingFlow(
        bytes32 raiseId,
        address proposer,
        address nonContributor,
        string memory description,
        string memory milestone,
        uint256 dripPercent,
        bool shouldPass
    ) internal returns (uint256 proposalId) {
        vm.startPrank(nonContributor);
        vm.expectRevert();
        raiseBoxProposalContract.hostProposal(
            raiseId,
            IRaiseBoxProposal.MilestoneInfo({
                description: description,
                milestone: milestone,
                dripPercent: uint8(dripPercent)
            })
        );
        vm.stopPrank();

        if (raiseBoxProposalContract.getProposalCount(raiseId) > 0) {
            advanceBlockTime(4 weeks);
            raiseBoxCore.syncRaiseState(raiseId);
        }

        uint256 proposalCountBefore = raiseBoxProposalContract.getProposalCount(raiseId);

        vm.startPrank(proposer);
        proposalId = raiseBoxProposalContract.hostProposal(
            raiseId,
            IRaiseBoxProposal.MilestoneInfo({
                description: description,
                milestone: milestone,
                dripPercent: uint8(dripPercent)
            })
        );
        vm.stopPrank();

        assertEq(
            uint256(raiseBoxCore.getRaiseState(raiseId)),
            uint256(IRaiseBoxCore.RaiseState.DELEGATING),
            "raise state has to change from 2 (PROPOSAL) to 3 (DELEGATING)"
        );

        assertEq(
            uint256(raiseBoxProposalContract.getProposalState(raiseId, proposalId)),
            uint256(IRaiseBoxProposal.ProposalState.ACTIVE),
            "proposal state should be ACTIVE (1) after hosting"
        );

        IRaiseBoxProposal.ProposalInfo memory proposalInfo = raiseBoxProposalContract.getProposalInfo(raiseId, proposalId);
        assertEq(
            proposalInfo.milestoneInfo.description,
            description,
            "proposal description incorrect"
        );
        assertEq(
            proposalInfo.milestoneInfo.milestone,
            milestone,
            "proposal milestone incorrect"
        );
        assertEq(
            proposalInfo.milestoneInfo.dripPercent,
            dripPercent,
            "proposal drip percent incorrect"
        );

        assertEq(
            raiseBoxProposalContract.getProposalCount(raiseId),
            proposalCountBefore + 1,
            "proposal count should increase by 1 after hosting a new proposal"
        );

        uint256 lastProposalTime = raiseBoxProposalContract.getLastProposalTime(raiseId);
        assertTrue(
            lastProposalTime >= block.timestamp - 5 minutes,
            "last proposal time should be recent"
        );

        vm.startPrank(nonContributor);
        vm.expectRevert(
            abi.encodeWithSelector(
                RaiseBoxErrorsLib.RaiseBoxVoting_canDelegate_NotAContributor.selector,
                raiseId
            )
        );
        raiseBoxVoting.delegateVote(raiseId, proposalId, nonContributor, contributor5);
        vm.stopPrank();

        vm.expectEmit(true, true, false, false);
        emit RaiseBoxEventsLib.VoteDelegated(contributor1, contributor5);
        vm.startPrank(contributor1);
        raiseBoxVoting.delegateVote(raiseId, proposalId, contributor1, contributor5);
        vm.stopPrank();

        vm.expectEmit(true, true, false, false);
        emit RaiseBoxEventsLib.VoteDelegated(contributor2, contributor5);
        vm.startPrank(contributor2);
        raiseBoxVoting.delegateVote(raiseId, proposalId, contributor2, contributor5);
        vm.stopPrank();

        vm.startPrank(contributor1);
        vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxVoting_CannotDelegateTwice.selector);
        raiseBoxVoting.delegateVote(raiseId, proposalId, contributor1, contributor5);
        vm.stopPrank();

        vm.startPrank(contributor1);
        vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxVoting_CannotDelegateToSelf.selector);
        raiseBoxVoting.delegateVote(raiseId, proposalId, contributor1, contributor1);
        vm.stopPrank();

        vm.startPrank(contributor1);
        vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxVoting_CanOnlyDelegateOwnVote.selector);
        raiseBoxVoting.delegateVote(raiseId, proposalId, contributor2, contributor5);
        vm.stopPrank();

        vm.startPrank(contributor5);
        vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxVoting_CannotReDelegate.selector);
        raiseBoxVoting.delegateVote(raiseId, proposalId, contributor5, contributor1);
        vm.stopPrank();

        vm.startPrank(contributor3);
        vm.expectRevert();
        raiseBoxVoting.delegateVote(raiseId, proposalId, contributor3, contributor1);
        vm.stopPrank();

        vm.startPrank(contributor1);
        vm.expectRevert(
            abi.encodeWithSelector(
                RaiseBoxErrorsLib.RaiseBoxVoting_VotingNotStarted.selector,
                raiseId,
                proposalId
            )
        );
        raiseBoxVoting.vote(raiseId, proposalId, true);
        vm.stopPrank();

        advanceBlockTime(2 days);
        raiseBoxCore.syncRaiseState(raiseId);

        vm.startPrank(nonContributor);
        vm.expectRevert(
            abi.encodeWithSelector(
                RaiseBoxErrorsLib.RaiseBoxVoting_NotContributor.selector,
                raiseId,
                nonContributor
            )
        );
        raiseBoxVoting.vote(raiseId, proposalId, false);
        vm.stopPrank();

        vm.startPrank(nonContributor);
        vm.expectRevert(
            abi.encodeWithSelector(
                RaiseBoxErrorsLib.RaiseBoxProposal_isValidProposal_ProposalDoesNotExist.selector,
                90
            )
        );
        raiseBoxVoting.vote(raiseId, 90, false);
        vm.stopPrank();

        if (shouldPass) {
            vm.expectEmit(true, true, true, false);
            emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(contributor5, raiseId, proposalId, true);
            vm.startPrank(contributor5);
            raiseBoxVoting.vote(raiseId, proposalId, true);
            vm.stopPrank();

            vm.expectEmit(true, true, true, false);
            emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(contributor3, raiseId, proposalId, true);
            vm.startPrank(contributor3);
            raiseBoxVoting.vote(raiseId, proposalId, true);
            vm.stopPrank();

            vm.expectEmit(true, true, true, false);
            emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(contributor4, raiseId, proposalId, true);
            vm.startPrank(contributor4);
            raiseBoxVoting.vote(raiseId, proposalId, true);
            vm.stopPrank();

            (uint256 forVotes, uint256 againstVotes) = raiseBoxVoting.getProposalVotes(raiseId, proposalId);
            assertEq(
                (forVotes + againstVotes),
                5,
                "total votes for proposal should be 5 (3 + 1 + 1)"
            );
            assertEq(
                forVotes,
                5,
                "for votes should be 5 when all participants vote in favor"
            );
            assertEq(
                againstVotes,
                0,
                "against votes should be 0 when all participants vote in favor"
            );
        } else {
            vm.expectEmit(true, true, true, false);
            emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(contributor5, raiseId, proposalId, false);
            vm.startPrank(contributor5);
            raiseBoxVoting.vote(raiseId, proposalId, false);
            vm.stopPrank();

            vm.expectEmit(true, true, true, false);
            emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(contributor3, raiseId, proposalId, true);
            vm.startPrank(contributor3);
            raiseBoxVoting.vote(raiseId, proposalId, true);
            vm.stopPrank();

            vm.expectEmit(true, true, true, false);
            emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(contributor4, raiseId, proposalId, true);
            vm.startPrank(contributor4);
            raiseBoxVoting.vote(raiseId, proposalId, true);
            vm.stopPrank();

            (uint256 forVotes, uint256 againstVotes) = raiseBoxVoting.getProposalVotes(raiseId, proposalId);
            assertEq(
                (forVotes + againstVotes),
                5,
                "total votes for proposal should be 5 (3 + 1 + 1)"
            );
            assertEq(
                forVotes,
                2,
                "for votes should be 2 (1 from contributor3 and 1 from contributor4)"
            );
            assertEq(
                againstVotes,
                3,
                "against votes should be 3 (3 from contributor5, self + 2 delegated from contributor1 and contributor2)"
            );
        }

        vm.startPrank(contributor1);
        vm.expectRevert(
            abi.encodeWithSelector(
                RaiseBoxErrorsLib.RaiseBoxVoting_AlreadyDelegatedVote.selector,
                contributor1
            )
        );
        raiseBoxVoting.vote(raiseId, proposalId, true);
        vm.stopPrank();

        advanceBlockTime(7 days);

        vm.expectEmit(true, true, false, false);
        emit RaiseBoxEventsLib.RaiseBoxVoting_VoteTallyTriggered(proposer, proposalId, block.timestamp);
        vm.startPrank(proposer);
        raiseBoxVoting.triggerVoteTally(raiseId, proposalId);
        vm.stopPrank();

        vm.startPrank(proposer);
        vm.expectRevert(
            abi.encodeWithSelector(
                RaiseBoxErrorsLib.RaiseBoxVoting_VotingAlreadyEnded.selector,
                raiseId,
                proposalId
            )
        );
        raiseBoxVoting.triggerVoteTally(raiseId, proposalId);
        vm.stopPrank();

        if (shouldPass) {
            assertEq(
                uint256(raiseBoxCore.getRaiseState(raiseId)),
                uint256(IRaiseBoxCore.RaiseState.DRIPPING),
                "raise state has to change to DRIPPING after a successful vote"
            );

            assertEq(
                uint256(raiseBoxProposalContract.getProposalState(raiseId, proposalId)),
                uint256(IRaiseBoxProposal.ProposalState.PASSED),
                "proposal state should be PASSED (2) when voting passes"
            );
        } else {
            assertEq(
                uint256(raiseBoxCore.getRaiseState(raiseId)),
                uint256(IRaiseBoxCore.RaiseState.PROPOSAL),
                "raise state has to change from 3 (VOTING) back to 2 (PROPOSAL) after vote tally"
            );

            assertEq(
                uint256(raiseBoxProposalContract.getProposalState(raiseId, proposalId)),
                uint256(IRaiseBoxProposal.ProposalState.FAILED),
                "proposal state should be FAILED (3) since againstVotes > forVotes"
            );

            vm.startPrank(contributor5);
            vm.expectRevert(
                abi.encodeWithSelector(
                    RaiseBoxErrorsLib.RaiseBoxVoting_VotingAlreadyEnded.selector,
                    raiseId,
                    proposalId
                )
            );
            raiseBoxVoting.vote(raiseId, proposalId, false);
            vm.stopPrank();
        }

        return proposalId;
    }

    function _hostSuccessfulProposalsUntilDripped(
        bytes32 raiseId,
        address proposer,
        address nonContributor,
        uint8[] memory dripPercents,
        string memory descriptionPrefix
    ) internal returns (uint256[] memory proposalIds) {
        uint256 totalRaised = raiseBoxCore.getAmtRaisedByProject(raiseId);
        uint256 totalDripped = raiseBoxDripHandler.totalEthDrippedForProject(raiseId) + raiseBoxDripHandler.totalErc20DrippedForProject(raiseId);
        uint256 protocolFee = totalRaised / 100;
        uint256 expectedNetRaised = totalRaised > protocolFee ? totalRaised - protocolFee : 0;

        proposalIds = new uint256[](dripPercents.length);

        for (uint256 i = 0; i < dripPercents.length; i++) {
            if (totalDripped >= expectedNetRaised) {
                break;
            }

            if (i > 0) {
                advanceBlockTime(4 weeks);
                raiseBoxCore.syncRaiseState(raiseId);
            }

            string memory description = string.concat(descriptionPrefix, " #", vm.toString(i + 1));
            string memory milestone = string.concat("milestone ", vm.toString(i + 1));
            proposalIds[i] = _hostProposalAndCompleteVotingFlow(
                raiseId,
                proposer,
                nonContributor,
                description,
                milestone,
                dripPercents[i],
                true
            );

            totalDripped = raiseBoxDripHandler.totalEthDrippedForProject(raiseId) + raiseBoxDripHandler.totalErc20DrippedForProject(raiseId);
        }

        return proposalIds;
    }

    function hostAndVoteOnProposals(
        bytes32 raiseId_
        ) public {

         address[5] memory voters = [
            ebby, sally, uche, 
            max, mark
            ];
        
          address[4] memory voters2 = [
            ben, openseas, carl, 
            base
            ];

          address[3] memory voters3 = [
            tether, magiceden, gowagr
            ];

        IRaiseBoxProposal.MilestoneInfo[12] memory milestoneInfo = [

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the first proposal for raisebox v3",
            milestone: "testnet website for mvp ready",
            dripPercent: 10
            }),

            // first proposal drip cannot be greater than 10%, now enabled -- ebby
            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the first proposal for raisebox v3",
            milestone: "testnet for beta testing is ready and live",
            dripPercent: 10
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the second proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 25
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the third proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 20
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the 5 proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 20
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the 6 proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 25
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the 7 proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 15
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the 8 proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 10
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the 9 proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 10
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the 10 proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 20
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the 11 proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 10
            }),

            IRaiseBoxProposal.MilestoneInfo({
            description: "this is the 12 proposal for raisebox v3",
            milestone: "beta mainnet is live for live testing",
            dripPercent: 15
            })

        ];

            
        for (uint a = 1; a < milestoneInfo.length; a++) {
            (bool upkeepNeeded, bytes memory performData) = raiseBoxCore.checkUpkeep("");
            raiseBoxCore.performUpkeep(performData);
            vm.prank(arbitrum);
            raiseBoxProposalContract.hostProposal(raiseId_, milestoneInfo[a]);

            // simulate delay before voting begins - 48 hours
            advanceBlockTime(2 days);
            raiseBoxCore.syncRaiseState(raiseId_);

            // proposals in this branch will fail since `againstVotes` > `ForVotes`
            if ( 
                a == 2 ||
                a == 4 ||
                a == 5 ||
                a == 6 ||
                a == 9 ||
                a == 10
                 ) {
                for (uint w = 0; w < voters2.length; w++) {
                vm.prank(voters2[w]);
                raiseBoxVoting.vote(raiseId_, a, true);
            }

                for (uint e = 0; e < voters3.length; e++) {
                vm.prank(voters3[e]);
                raiseBoxVoting.vote(raiseId_, a, true);
            }

            } else { // proposals in this else branch will pass `F > A`

                for (uint j = 0; j < voters.length; j++) {
                vm.startPrank(voters[j]);
                if (j == 1 || j % 2 == 0) {
                    raiseBoxVoting.vote(raiseId_, a, true);
                } else {
                    raiseBoxVoting.vote(raiseId_, a, false);
                }
                vm.stopPrank();
                }
            }
           

            // simulate delay for voting to happen, voting duration ==> 7 days
            advanceBlockTime(7 days);
            vm.prank(arbitrum);
            raiseBoxVoting.triggerVoteTally(raiseId_, a);

            // simulate delay before a new proposal can be hosted ==> 4 weeks
            advanceBlockTime(3 weeks);
            }

            
        
    }
}
