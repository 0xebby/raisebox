// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

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

        // upkeep or sync raise state
        advanceBlockTime(12 hours);
        (bool upkeepNeeded, bytes memory performData) = raiseBoxCore.checkUpkeep("");
        raiseBoxCore.performUpkeep(performData);

        // contribute:
        vm.startPrank(uche);
        vm.expectEmit(true, true, true, false);
        emit RaiseBoxEventsLib.Contributed(
            uche, 
            contributionAmount, 
            raiseIdSmall,
            contributionAmount,
            true
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

        advanceBlockTime(12 hours);
        raiseBoxCore.syncRaiseState(raiseIdSmall);

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

        advanceBlockTime(12 hours);
        raiseBoxCore.syncRaiseState(raiseIdSmall);

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

        advanceBlockTime(12 hours);
        raiseBoxCore.syncRaiseState(raiseIdSmall);

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

        advanceBlockTime(12 hours);
        raiseBoxCore.syncRaiseState(raiseIdSmall);

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
                " more ether to this project"
            )
        );

        advanceBlockTime(12 hours);

        (bool upkeepNeeded, bytes memory performData) = raiseBoxCore.checkUpkeep("");
        raiseBoxCore.performUpkeep(performData);

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

        /// assert raise state change INACTIVE -> ACTIVE
        assertEq(
            uint256(raiseStateAfterRaiseCreation), 
            uint256(IRaiseBoxCore.RaiseState.ACTIVE),
            "raise state has to change from 0 (inactive) to 1 (contribution)"
            );

        /// contribution to raise:
        /// 5 contributors will contribute 20 eth each to reach raise target of 100
        /// eth

        /// each now contributes 20 ether to raise in any other and frequency:

        advanceBlockTime(12 hours);
        raiseBoxCore.syncRaiseState(endToEndRaiseId);

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
            // abi.encodeWithSelector(
            // RaiseBoxErrorsLib.RaiseBoxContribution_contribute_AboveMaxAllowed.selector,
            // 20 ether,
            // reason
            // )
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

        uint256 proposalId1 = _hostProposalAndCompleteVotingFlow(
            endToEndRaiseId,
            raiseCreator,
            nonContributor,
            "First proposal for end to end raise",
            "This is the first proposal for the comprehensive end to end raise cycle test",
            10
        );

        uint256 proposalId2 = _hostProposalAndCompleteVotingFlow(
            endToEndRaiseId,
            raiseCreator,
            nonContributor,
            "second proposal for end to end raise",
            "This is the first proposal for the comprehensive end to end raise cycle test",
            25
        );


        // The proposal-hosting and voting flow is now exercised through the shared
        // helper in TestsHelpers.sol for reuse across the test suite.
    }

    function test_Integration_51_HostProposalsUntilRaiseIsDripped() public {
        console.log("\n=== TEST 51: Host proposals until the raise is fully dripped ===");

        address nonContributor = makeAddr("drip-non-contributor");
        vm.deal(nonContributor, 1000 ether);

        advanceBlockTime(30 days);

        vm.startPrank(raiseCreator);
        bytes32 drainedRaiseId = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
                projectName: "drip test raise",
                valueProposition: "drip lifecycle",
                raiseTarget: 100 ether,
                projectDuration: 60 weeks
            })
        );
        vm.stopPrank();

        advanceBlockTime(12 hours);
        raiseBoxCore.syncRaiseState(drainedRaiseId);

        address[5] memory contributors = [contributor1, contributor2, contributor3, contributor4, contributor5];
        for (uint256 i = 0; i < contributors.length; i++) {
            vm.startPrank(contributors[i]);
            raiseBoxContributionContract.contribute{value: 20 ether}(20 ether, drainedRaiseId);
            vm.stopPrank();
        }

        assertEq(
            raiseBoxContributionContract.getTotalContributionsToRaise(drainedRaiseId),
            100 ether,
            "raise should reach target before drip cycle"
        );

        uint8[] memory dripPercents = new uint8[](5);
        dripPercents[0] = 10;
        dripPercents[1] = 15;
        dripPercents[2] = 20;
        dripPercents[3] = 10;
        dripPercents[4] = 15;

        _hostSuccessfulProposalsUntilDripped(
            drainedRaiseId,
            raiseCreator,
            nonContributor,
            dripPercents,
            "drip test proposal"
        );

        uint256 totalRaised = raiseBoxCore.getAmtRaisedByProject(drainedRaiseId);
        uint256 totalDripped = raiseBoxDripHandler.totalEthDrippedForProject(drainedRaiseId) + raiseBoxDripHandler.totalErc20DrippedForProject(drainedRaiseId);
        uint256 protocolFee = totalRaised / 100;
        uint256 expectedNetRaised = totalRaised > protocolFee ? totalRaised - protocolFee : 0;

        advanceBlockTime(4 weeks);
        raiseBoxCore.syncRaiseState(drainedRaiseId);

        assertGe(
            totalDripped,
            expectedNetRaised / 2,
            "raise should have dripped a meaningful portion of the net raised funds"
        );

        assertEq(
            uint256(raiseBoxCore.getRaiseState(drainedRaiseId)),
            uint256(IRaiseBoxCore.RaiseState.PROPOSAL),
            "raise should return to PROPOSAL once the drip sequence has exhausted the remaining funds"
        );
    }

    function test_integration_preventHostingAfterDrained() public {
        // create raise and fund
        vm.startPrank(creator);
        bytes32 raiseId = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
                projectName: "integration drain",
                valueProposition: "integration check",
                raiseTarget: 5 ether,
                projectDuration: 52 weeks
            })
        );
        vm.stopPrank();

        // move to contribution
        advanceBlockTime(12 hours);
        (bool upkeepNeeded, bytes memory performData) = raiseBoxCore.checkUpkeep("");
        raiseBoxCore.performUpkeep(performData);

        // contribute using multiple contributors to respect per-user cap (20% of raiseTarget)
        address[5] memory contributors = [alice, joe, ben, max, ebby];
        for (uint256 i = 0; i < contributors.length; i++) {
            vm.prank(contributors[i]);
            raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, raiseId);
        }

        // mark dripped to full by probing mapping storage slots and writing the dripped total
        bool wrote = false;
        for (uint256 slot = 0; slot < 50; slot++) {
            bytes32 mappingSlot = keccak256(abi.encodePacked(raiseId, uint256(slot)));
            vm.store(address(raiseBoxDripHandler), mappingSlot, bytes32(uint256(5 ether)));
            if (raiseBoxDripHandler.totalEthDrippedForProject(raiseId) == 5 ether) { wrote = true; break; }
        }
        assertTrue(wrote, "failed to write dripped total into drip handler storage");

        // attempt to host proposal should revert
        vm.startPrank(creator);
        vm.expectRevert();
        raiseBoxProposalContract.hostProposal(
            raiseId,
            IRaiseBoxProposal.MilestoneInfo({
                description: "integration should fail",
                milestone: "no funds",
                dripPercent: 5
            })
        );
        vm.stopPrank();
    }







    
}
