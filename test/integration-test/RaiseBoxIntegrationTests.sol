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




    
}
