// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "lib/forge-std/src/Test.sol";
import {TestsHelpers} from "test/TestsHelpers.sol";
import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxProposal} from "src/interfaces/IRaiseBoxProposal.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";
import {RaiseBoxErrorsLib} from "src/RaiseBoxLib/RaiseBoxErrorsLib.sol";

contract RaiseBoxIntegrationTests is Test, TestsHelpers {

    
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


    
}
