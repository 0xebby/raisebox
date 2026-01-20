// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "lib/forge-std/src/Test.sol";
import {TestsHelpers} from "test/TestsHelpers.sol";
import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxProposal} from "src/interfaces/IRaiseBoxProposal.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


contract RaiseBoxIntegrationTests is Test, TestsHelpers {
    using Strings for uint256;

    /// TEST SUITE 1: BASIC FUNCTIONALITY ///

    
    function test_Integration_01_SingleContributionSuccess() public {
        
        console.log("\n=== TEST 1: Single Contribution Success ===");

        uint256 contributionAmount = 1 ether;

        // intial state record
        uint256 initialBalance = uche.balance;
        uint256 initialDripBalance = address(raiseBoxDripHandler).balance;

        // contribute:
        vm.startPrank(uche);
        vm.expectEmit(true, true, true, false);
        emit RaiseBoxEventsLib.Contributed(
            uche, 
            contributionAmount, 
            raiseIdSmall,
            contributionAmount
            );
        raiseBoxContributionContract.contribute{value: contributionAmount}(contributionAmount, raiseIdSmall);
        vm.stopPrank();

        // assert:
        assertEq(
            raiseBoxContributionContract.getUserRaiseContributions(
                raiseIdSmall,
                uche
            ), 
            contributionAmount,
            "Incorrect contribution amount recorded"
            );

        assertEq(
            raiseBoxContributionContract.getTotalContributionsToRaise(raiseIdSmall), contributionAmount,
            "Incorrect total contribution"
            );

        assertEq(
            raiseBoxContributionContract.getTotalContributors(raiseIdSmall), 
            1,
            "Incorrect contributor count"
            );

        assertTrue(
            raiseBoxContributionContract.hasUserContributed(raiseIdSmall, uche),
            "user has not contributed"
        );

        assertEq(
            uche.balance, 
            initialBalance - contributionAmount,
            "contributor balance incorrect"
            );

        assertEq(
            address(raiseBoxDripHandler).balance,
            initialDripBalance + contributionAmount,
            "incorrect drip handler balance" 
            );
        console.log(address(raiseBoxDripHandler).balance);

        console.log(" single contribution successful");
    }

    function test_Integration_02_MultipleContributorsSmallRaise() public {
        console.log("\n=== TEST 2: Multiple contributors to small raise ===");

        uint256 contributionAmount = 2 ether;

        // uche contributes
        vm.startPrank(uche);
        raiseBoxContributionContract.contribute{value: contributionAmount}(contributionAmount, raiseIdSmall);
        vm.stopPrank();

        // max contributes
        vm.startPrank(max);
        raiseBoxContributionContract.contribute{value: contributionAmount}(contributionAmount, raiseIdSmall);
        vm.stopPrank();

        // sally contributes
        vm.startPrank(sally);
        raiseBoxContributionContract.contribute{value: contributionAmount}(contributionAmount, raiseIdSmall);
        vm.stopPrank();

        // arbitrum contributes
        vm.startPrank(arbitrum);
        raiseBoxContributionContract.contribute{value: contributionAmount}(contributionAmount, raiseIdSmall);
        vm.stopPrank();

        // carl contributes
        // raise passes since small raise target is 10 ether
        vm.startPrank(carl);
        vm.expectEmit(false, false, false, false);
        emit RaiseBoxEventsLib.RaiseBox_RaisePassed(
            RAISE_TARGET_SMALL, 
            raiseBoxContributionContract.getTotalContributionsToRaise(raiseIdSmall)
        );
        raiseBoxContributionContract.contribute{value: contributionAmount}(contributionAmount, raiseIdSmall);
        vm.stopPrank();

        // assert final states:
        assertEq(
            raiseBoxContributionContract.getTotalContributionsToRaise(raiseIdSmall), RAISE_TARGET_SMALL,
            "total raised should equal target since raise passed"
            );

        assertEq(
            raiseBoxContributionContract.getTotalContributors(raiseIdSmall), 
            5,
            "contributor count should be 5 since 5 users contributed to raise"
            );

        assertEq(
            uint8(raiseBoxCore.getRaiseState(raiseIdSmall)), 
            uint8(IRaiseBoxCore.RaiseState.PROPOSAL),
            "raise should be in PROPOSAL state since it passed"
            );

        console.log("Multiple contributors successfully completed raise");

    }

    function test_Integration_03_MultipleContributionsSameUserSuccessFul() public {
        console.log("\n=== TEST 3: Multiple contributions from same user suceeds ===");

        uint256 firstContribution = 0.5 ether;
        uint256 secondContribution = 1 ether;
        uint256 thirdContribution = 0.3 ether;

        vm.startPrank(uche);
        raiseBoxContributionContract.contribute{value: firstContribution}(firstContribution, raiseIdSmall);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxContributionContract.contribute{value: secondContribution}(secondContribution, raiseIdSmall);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxContributionContract.contribute{value: thirdContribution}(thirdContribution, raiseIdSmall);
        vm.stopPrank();


        uint256 expectTotalContributions = (
            firstContribution + secondContribution + thirdContribution
        );
        assertEq(
            raiseBoxContributionContract.getTotalContributionsToRaise(raiseIdSmall), expectTotalContributions,
            "total contributions made by user is incorrect"
            );

        // get uche contribution history:
        uint256[] memory contributionHistory = raiseBoxContributionContract.getContributionHistory(uche, raiseIdSmall);
        assertEq(contributionHistory.length, 3, "should have 3 entries in history array");
        assertEq(contributionHistory[0], firstContribution, "first  entry in history should be firstContribution");
        assertEq(contributionHistory[1], secondContribution, "second entry in history should be secondContribution");
        assertEq(contributionHistory[2], thirdContribution, "third  entry in history should be thirdContribution");

        // verify that contributor is only counted once:
        assertEq(
            raiseBoxContributionContract.getTotalContributors(raiseIdSmall),
            1,
            "only uche contributed to small raise"
        );

        console.log("Multiple contributions by same user tracked correctly");

    }

    /// TEST SUITE 2: VALIDATION & BOUNDARIES ///

    function test_Integration_04_RejectZeroAmountContribution() public {
        console.log("\n=== TEST 4: Reject zero amount contribution ===");

        vm.startPrank(uche);
        vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxContribution_ZeroAmount.selector);
        raiseBoxContributionContract.contribute{value: 0 ether}(0 ether, raiseIdSmall);
        vm.stopPrank();

        console.log("zero aount rejected");
    }

    function test_Integration_05_RejectValueMismatchForContribution() public {
        console.log("test 5: reject value mismatch for contribution");

        vm.startPrank(uche);
        vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxContribution_ValueSentMismatch.selector);
        raiseBoxContributionContract.contribute{value: 10 ether}(20 ether, raiseIdSmall);
        vm.stopPrank();

        console.log("value mismatch rejected");
        
    }

    function test_Integration_06_RejectBelowMinimumContribution() public {
        console.log("test 6: reject below minimum contribution allowed");

        uint minContribution = raiseBoxCore.getMinimumContribution();
        uint justBelowMinContribution = minContribution - 0.001 ether;

        vm.startPrank(uche);
        vm.expectRevert(
            abi.encodeWithSelector(
                RaiseBoxErrorsLib.RaiseBoxContribution_ContributeMoreEth.selector, minContribution)
        );
        raiseBoxContributionContract.contribute{value: justBelowMinContribution}(justBelowMinContribution, raiseIdSmall);
        vm.stopPrank();

        console.log("below minimum contribution rejected");

    }

    function test_Integration_07_RejectSelfContribution() public {
        console.log("test 7: reject self contribution -- contribution by raise creator");

        address smallRaiseCreator = ebby;

        vm.startPrank(smallRaiseCreator);
        vm.expectRevert(
                RaiseBoxErrorsLib.RaiseBoxContribution_SelfContributionForbidden.selector
        );
        raiseBoxContributionContract.contribute{value: 6 ether}(6 ether, raiseIdSmall);
        vm.stopPrank();

        console.log("self contribution rejected");
    }

    function test_Integration_08_RejectOverMaxContribution() public {

        console.log(" test 8: reject over max contribution");

        uint maxContribution = raiseBoxContributionContract.getMaxContributionAllowedForARaise(raiseIdMedium);
        uint overMax = maxContribution + 10 ether;

        string memory reason = string(
            abi.encodePacked(
                "Cannot over contribute: you can contribute only: ",
                ((maxContribution) / 1e18).toString(),
                " ether more to this project"
            )
        );

        vm.startPrank(whale);
        vm.expectRevert(
            abi.encodeWithSelector(
                RaiseBoxErrorsLib.RaiseBoxContribution_contribute_AboveMaxAllowed.selector, 
                maxContribution,
                reason
                )
        );
        raiseBoxContributionContract.contribute{value: overMax}(overMax, raiseIdMedium);
        vm.stopPrank();

    }

    /// TEST SUITE 3: STATE TRANSITIONS

    /// COMPREHENSIVE END-TO-END RAISE CYCLE TEST
    function test_Integration_50_EndToEndRaiseCycle() public {
        console.log("\n=== TEST 50: Comprehensive end-to-end raise cycle ===");

        /// create a non-contributor that will try to infiltrate and break the protocol logics at different stages:
        address nonContributor = makeAddr("non-contributor");
        vm.deal(nonContributor, 1000 ether);

        /// use raiseCreator


        /// construct projectInfo struct
        IRaiseBoxCore.ProjectInfo memory projectInfoMEDIUM = IRaiseBoxCore.ProjectInfo({
        projectName: "medium project",
        valueProposition: "medium project value proposition",
        raiseTarget: RAISE_TARGET_MEDIUM,
        projectDuration: RAISE_DURATION_MEDIUM    
        });

        /// create a raise
        vm.startPrank(raiseCreator);
        // vm.expectEmit(false, true, false, true, true, false);
        // RaiseBoxEventsLib.RaiseCreation_RaiseCreated(
        //     "medium project",
        //     raiseCreator,
        //     "medium project value proposition",
        //     RAISE_TARGET_MEDIUM,
        //     // needs raiseId,
        //     block.timestamp

        // )
        bytes32 endToEndRaiseId = raiseBoxRaiseCreationContract.createNewRaise(
            projectInfoMEDIUM
        );
        vm.stopPrank();

        /// nonContributor also tries to create a raise and fails since not whitelisted prior
        vm.startPrank(nonContributor);
        vm.expectRevert();
        raiseBoxRaiseCreationContract.createNewRaise( projectInfoMEDIUM );
        vm.stopPrank();

        /// get latest raise state:
        IRaiseBoxCore.RaiseState raiseStateAfterRaiseCreation = raiseBoxCore.getRaiseState(endToEndRaiseId);

        /// assert raise state change INACTIVE -> CONTRIBUTION
        assertEq(
            uint256(raiseStateAfterRaiseCreation), 
            uint256(IRaiseBoxCore.RaiseState.CONTRIBUTION),
            "raise state has to change from 0 (inactive) to 1 (contribution)"
            );

        /// contribution to raise:
        /// 5 contributors will contribute 20 eth each to reach raise target of 100
        /// eth

        /// each now contributes 20 ether to raise in any other and frequency:

        /// 1:
        vm.startPrank(contributor1);
        raiseBoxContributionContract.contribute{value: 20 ether}(20 ether, endToEndRaiseId);
        vm.stopPrank();

        /// 2: 10 first and 10 later
        vm.startPrank(contributor2);
        raiseBoxContributionContract.contribute{value: 10 ether}(10 ether, endToEndRaiseId);

        /// assert first contribution is recorded
        assertTrue(raiseBoxContributionContract.hasUserContributed(endToEndRaiseId, contributor2));

        /// make second contribution
        raiseBoxContributionContract.contribute{value: 10 ether}(10 ether, endToEndRaiseId);

        /// assert second contribution is also recorded
        assertEq(
            raiseBoxContributionContract.getUserRaiseContributions(endToEndRaiseId, contributor2), 
            20 ether,
            "total contributions by contributor2 should be 20 ether, (10 + 10) ether"
            );
        vm.stopPrank();

        /// 3: 
        /// contributor3 tries to over contribute at first and then corrects it
        /// make first over contribution attempt
        vm.startPrank(contributor3);
        uint maxCon = 20 ether;

        /// revert reason:
        string memory reason = string(
            abi.encodePacked(
                "Cannot over contribute: you can contribute only: ",
                ((maxCon) / 1e18).toString(),
                " ether more to this project"
            )
        );

        vm.expectRevert(
            abi.encodeWithSelector(
            RaiseBoxErrorsLib.RaiseBoxContribution_contribute_AboveMaxAllowed.selector,
            20 ether,
            reason
            )
        );
           
        raiseBoxContributionContract.contribute{value: maxCon + 1 /*just above max allowed */}(maxCon + 1, endToEndRaiseId);

        // assert first failed contribution
        /// should be false since contribution reverted
        assertFalse(raiseBoxContributionContract.hasUserContributed(endToEndRaiseId, contributor3));

        /// make the accepted contribution
        raiseBoxContributionContract.contribute{value: 20 ether}(20 ether, endToEndRaiseId);

        /// Assert the second contribution was recorded
        assertTrue(raiseBoxContributionContract.hasUserContributed(endToEndRaiseId, contributor3));

        vm.stopPrank();

        /// 4:
        /// contributor4 will first try to contribute 0, then split contributions into 4 parts (5 ether each)

        /// first contribution with zero amount
        vm.startPrank(contributor4);
        vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxContribution_ZeroAmount.selector);
        raiseBoxContributionContract.contribute{value: 0 ether}(0 ether, endToEndRaiseId);

        /// assert contribution was not recorded
        assertFalse(raiseBoxContributionContract.hasUserContributed(endToEndRaiseId, contributor4));

        /// variable to store total contributions made by contributor4
        uint totContributions4 = 0 ether; // initialy 0

        /// make the split contributions, 5 ether each
        for (uint i = 0; i <= 3; i++ ) {
            raiseBoxContributionContract.contribute{value: 5 ether}(5 ether, endToEndRaiseId);
            /// update each contribution made by contributor4
            totContributions4 += 5 ether;
        }

        /// assert contributions are correctly recorded:
        /// get contributions history for contributor4 
        uint256[] memory contributor4History = raiseBoxContributionContract.getContributionHistory(contributor4, endToEndRaiseId);

        /// assert each entry
        assertEq(contributor4History[0], 5 ether, "first contribution was 5 ether");
        assertEq(contributor4History[1], 5 ether, "second contribution was 5 ether");
        assertEq(contributor4History[2], 5 ether, "third contribution was 5 ether");
        assertEq(contributor4History[3], 5 ether, "fourth contribution was 5 ether");

        /// assert total contributions for contributor4 is recorded correctly:
        assertEq(totContributions4, 20 ether, "total contributions made by contributor4 is 20 ether");

        vm.stopPrank();

        /// 5:
        vm.startPrank(contributor5);
        raiseBoxContributionContract.contribute{value: 20 ether}(20 ether, endToEndRaiseId);
        vm.stopPrank();

        /// assert contributions for contributor5 is recorded
        assertTrue(raiseBoxContributionContract.hasUserContributed(endToEndRaiseId, contributor5));

        /// assert all contributions form 1-5 have been recorded
        assertTrue(raiseBoxContributionContract.getTotalContributionsToRaise(endToEndRaiseId) == 100 ether);

        /// raise passed, see last assert above:
        /// assert raise state change from CONTRIBUTION -> PROPOSAL
        /// get state after raise passes
        IRaiseBoxCore.RaiseState raiseStateAfterRaisePasses = raiseBoxCore.getRaiseState(endToEndRaiseId);
        assertEq(
            uint256(raiseStateAfterRaisePasses), 
            uint256(IRaiseBoxCore.RaiseState.PROPOSAL),
            "raise state has to change from 1 (CONTRIBUTION) to 2 (PROPOSAL)"
        );

    /// HOSTING OF PROPOSALS:

    /// non creator tries to host proposal for a raise:
    /// has to happen here first as any successful proposal hosting would remove
    /// raise from PROPOSAL state
    /// should fail as caller isn't the raise creator
    vm.startPrank(nonContributor);
    vm.expectRevert();
    raiseBoxProposalContract.hostProposal(
        endToEndRaiseId,
        IRaiseBoxProposal.MilestoneInfo({
        description: "First proposal for end to end raise",
        milestone:"This is the first proposal for the comprehensive end to end raise cycle test",
        dripPercent: 10
        })
    );
    vm.stopPrank();
    
    /// raiseCreator can now host proposals that contributors will then vote on:
    /// host first proposal:
    vm.startPrank(raiseCreator);
    uint proposalId1 = raiseBoxProposalContract.hostProposal(
        endToEndRaiseId,
        IRaiseBoxProposal.MilestoneInfo({
        description: "First proposal for end to end raise",
        milestone:"This is the first proposal for the comprehensive end to end raise cycle test",
        dripPercent: 10
        })
    );
    vm.stopPrank();

    /// assert raise state change from PROPOSAL -> VOTING
    assertEq(
        uint256(raiseBoxCore.getRaiseState(endToEndRaiseId)), 
        uint256(IRaiseBoxCore.RaiseState.VOTING),
        "raise state has to change from 2 (PROPOSAL) to 3 (VOTING)"
    );

    /// assert proposal state is ACTIVE:
    assertEq(
        uint256(raiseBoxProposalContract.getProposalState(endToEndRaiseId, proposalId1)), 
        uint256(IRaiseBoxProposal.ProposalState.ACTIVE),
        "proposal state should be ACTIVE (1) after hosting"
    );

    /// Assert proposal details are correct:
    IRaiseBoxProposal.ProposalInfo memory proposalInfo1 = raiseBoxProposalContract.getProposalInfo(endToEndRaiseId, proposalId1);
    assertEq(
        proposalInfo1.milestoneInfo.description,
        "First proposal for end to end raise",
        "proposal description incorrect"
    );
    assertEq(
        proposalInfo1.milestoneInfo.milestone,
        "This is the first proposal for the comprehensive end to end raise cycle test",
        "proposal milestone incorrect"
    );
    assertEq(
        proposalInfo1.milestoneInfo.dripPercent,
        10,
        "proposal drip percent incorrect"
    );

    /// assert proposal count for raise is 1
    assertEq(
        raiseBoxProposalContract.getProposalCount(endToEndRaiseId),
        1,
        "proposal count for raise should be 1 after hosting first proposal"
    );

    /// assert last proposal time is recent (within last 5 minutes)
    uint256 lastProposalTime = raiseBoxProposalContract.getLastProposalTime(endToEndRaiseId);
    assertTrue(
        lastProposalTime >= block.timestamp - 5 minutes,
        "last proposal time should be recent"
    );

    /// nonContributor tries to delegate votes and fails:
    vm.startPrank(nonContributor);
    vm.expectRevert(
        abi.encodeWithSelector(
            RaiseBoxErrorsLib.RaiseBoxVoting_canDelegate_NotAContributor.selector,
            endToEndRaiseId 
            )
    );
    raiseBoxVoting.delegateVote(endToEndRaiseId, proposalId1, nonContributor, contributor5);
    vm.stopPrank();

    /// vote on proposal 1:
    /// contributors 1-5 will vote:

    //// contributors 1 and 2 will delegate to contributor 5
    //// contributors 3 and 4 will vote directly and will side true;
    //// contributor 5 will vote directly and will side false;

    /// contributor 1 delegates to contributor 5
    vm.expectEmit(true, true, false, false);
    emit RaiseBoxEventsLib.VoteDelegated( contributor1, contributor5 );
    vm.startPrank(contributor1);
    raiseBoxVoting.delegateVote(endToEndRaiseId, proposalId1, contributor1, contributor5);
    vm.stopPrank();

    /// contributor 2 delegates to contributor 5
    vm.expectEmit(true, true, false, false);
    emit RaiseBoxEventsLib.VoteDelegated( contributor2, contributor5 );
    vm.startPrank(contributor2);
    raiseBoxVoting.delegateVote(endToEndRaiseId, proposalId1, contributor2, contributor5);
    vm.stopPrank();

    // [
    /// contributor 1 tries to delegate again and fails
    vm.startPrank(contributor1);
    vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxVoting_CannotDelegateTwice.selector);
    raiseBoxVoting.delegateVote(endToEndRaiseId, proposalId1, contributor1, contributor5);
    vm.stopPrank();

    /// contributor 1 tries to delegate to self and fails
    vm.startPrank(contributor1);
    vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxVoting_CannotDelegateToSelf.selector);
    raiseBoxVoting.delegateVote(endToEndRaiseId, proposalId1, contributor1, contributor1);
    vm.stopPrank();

    /// contributor 1 tries to delegate votes of contributor 2 and fails
    vm.startPrank(contributor1);
    vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxVoting_CanOnlyDelegateOwnVote.selector);
    raiseBoxVoting.delegateVote(endToEndRaiseId, proposalId1, contributor2, contributor5);
    vm.stopPrank();

    /// contributor 5 tries to delegate votes to contributor 1 and fails since contributor 5 has already been delegated votes
    vm.startPrank(contributor5);
    vm.expectRevert(RaiseBoxErrorsLib.RaiseBoxVoting_CannotReDelegate.selector);
    raiseBoxVoting.delegateVote(endToEndRaiseId, proposalId1, contributor5, contributor1);
    vm.stopPrank();

    /// contributor 3 tries to delegate to contributor1 and fails since contributor1 has already deleagted and is now part of the delegation graph
    vm.startPrank(contributor3);
    vm.expectRevert();
    raiseBoxVoting.delegateVote(endToEndRaiseId, proposalId1, contributor3, contributor1);
    vm.stopPrank();

    /// contributor 1 tries to vote before voting begins and fails:
    vm.startPrank(contributor1);
    vm.expectRevert(
        abi.encodeWithSelector(
            RaiseBoxErrorsLib.RaiseBoxVoting_VotingNotStarted.selector,
            endToEndRaiseId,
            proposalId1
        )
    );
    raiseBoxVoting.vote(endToEndRaiseId, proposalId1, true);
    vm.stopPrank();

    // ]

    /// adavance time so voting can begin
    /// voting starts after 2 days of proposal hosting, allows for delegation and confirming milestone completion claims
    advanceBlockTime(2 days); 

    /// nonContributor tries to vote and fails:
    vm.startPrank(nonContributor);
    vm.expectRevert(
        abi.encodeWithSelector(
            RaiseBoxErrorsLib.RaiseBoxVoting_NotContributor.selector, 
            endToEndRaiseId,
            nonContributor
            )
    );
    raiseBoxVoting.vote(endToEndRaiseId, proposalId1, false);
    vm.stopPrank();

    /// non contributor also tries to vote for a non-existent proposal
    vm.startPrank(nonContributor);
    vm.expectRevert(
        abi.encodeWithSelector(
            RaiseBoxErrorsLib.RaiseBoxProposal_isValidProposal_ProposalDoesNotExist.selector, 
            90
            )
    );
    raiseBoxVoting.vote(endToEndRaiseId, 90 /* fake proposal with id = 90 */, false);
    vm.stopPrank();

    /// voters: contributor 5: 3 votes, contributor 3: 1 vote, contributor 4: 1 vote

    /// contributor 5 votes false
    vm.expectEmit(true, true, true, false);
    emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(contributor5, endToEndRaiseId, proposalId1, false);
    vm.startPrank(contributor5);
    raiseBoxVoting.vote(endToEndRaiseId, proposalId1, false);
    vm.stopPrank();

    /// contributor 3 votes true
    vm.expectEmit(true, true, true, false);
    emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(contributor3, endToEndRaiseId, proposalId1, true);
    vm.startPrank(contributor3);
    raiseBoxVoting.vote(endToEndRaiseId, proposalId1, true);
    vm.stopPrank();

    /// contributor 4 votes true
    vm.expectEmit(true, true, true, false);
    emit RaiseBoxEventsLib.RaiseBoxVoting_vote_Voted(contributor4, endToEndRaiseId, proposalId1, true);
    vm.startPrank(contributor4);
    raiseBoxVoting.vote(endToEndRaiseId, proposalId1, true);
    vm.stopPrank();

    /// assertions:
    /// assert total proposal votes = 5
    (uint256 forVotes, uint256 againstVotes, uint256 totalVotes) = raiseBoxVoting.getProposalVotes(endToEndRaiseId, proposalId1);
    /// assert total votes casted
    assertEq(
        totalVotes, 
        5,
        "total votes for proposal should be 5 (3 + 1 + 1)"
    );

    /// assert for votes = 2
    assertEq(
        forVotes, 
        2,
        "for votes should be 2 (1 from contributor3 and 1 from contributor4)"
    );

    /// assert against votes = 3
    assertEq(
        againstVotes,
        3,
        "against votes should be 3 (3 from contributor5, self + 2 delegated from contributor1 and contributor2)"
    );

    /// contributor1 tries to vote even when voting is live but fails, already delegated to contributor5
    vm.startPrank(contributor1);
    vm.expectRevert(
        abi.encodeWithSelector(
            RaiseBoxErrorsLib.RaiseBoxVoting_AlreadyDelegatedVote.selector, 
            contributor1
        )
    );
    raiseBoxVoting.vote(endToEndRaiseId, proposalId1, true);
    vm.stopPrank();

    /// end voting period, advance time by 7 days:
    advanceBlockTime(7 days);

    /// trigger vote tallying since voting has ended
    vm.expectEmit(true, true, false, false);
    emit RaiseBoxEventsLib.RaiseBoxVoting_VoteTallyTriggered( raiseCreator, proposalId1, block.timestamp );
    vm.startPrank(raiseCreator);
    raiseBoxVoting.triggerVoteTally(endToEndRaiseId, proposalId1);
    vm.stopPrank();

    // raiseCreator tries to trigger vote tallying of same proposal twice and fails:
    vm.startPrank(raiseCreator);
    vm.expectRevert(
        abi.encodeWithSelector(
            RaiseBoxErrorsLib.RaiseBoxVoting_VotingAlreadyEnded.selector,
            endToEndRaiseId,
            proposalId1
        )
    );
    raiseBoxVoting.triggerVoteTally(endToEndRaiseId, proposalId1);
    vm.stopPrank();

    /// assert raise state has been updated back to PROPOSAL to allow creator host more proposals
    assertEq(
        uint256(raiseBoxCore.getRaiseState(endToEndRaiseId)), 
        uint256(IRaiseBoxCore.RaiseState.PROPOSAL),
        "raise state has to change from 3 (VOTING) back to 2 (PROPOSAL) after vote tally"
    );

    /// asser proposal state for proposalId1 is now FAILED since againstVotes > forVotes
    assertEq(
        uint256(raiseBoxProposalContract.getProposalState(endToEndRaiseId, proposalId1)), 
        uint256(IRaiseBoxProposal.ProposalState.FAILED),
        "proposal state should be FAILED (3) since againstVotes > forVotes"
    );

    /// contributor5 tries to vote again after voting ended and fails
    vm.startPrank(contributor5);
    vm.expectRevert(
        abi.encodeWithSelector(
            RaiseBoxErrorsLib.RaiseBoxVoting_VotingAlreadyEnded.selector,
            endToEndRaiseId,
            proposalId1
        )
    );
    raiseBoxVoting.vote(endToEndRaiseId, proposalId1, false);
    vm.stopPrank();    










    }







    
}
