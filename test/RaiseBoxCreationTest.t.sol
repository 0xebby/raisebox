// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import {TestsHelpers} from "./TestsHelpers.sol";
import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";
import {IRaiseBoxProposal} from "src/interfaces/IRaiseBoxProposal.sol";


contract RaiseBoxCreationTest is Test, TestsHelpers {

    function testContributionRulesAreRespected() public {
        // whitelist project owner address
        // raiseBoxCore.verifyAndAddToWhitelist(ebby);

        // create a raise
        vm.startPrank(ebby);
        bytes32 raiseId = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
                projectName: "raisebox",
                valueProposition: "fully decentralized milestone based crowdfunding for projects you care about",
                raiseTarget: 20 ether,
                projectDuration: 52 weeks
            })
        ); 
        vm.stopPrank();

        // check if raise exists

        // raise is now in contribution state - contributors can contribute
        vm.prank(uche);
        vm.expectRevert();
        raiseBoxContributionContract.contribute{value: 0 ether}(0 ether, raiseId);

        vm.prank(max);
        vm.expectRevert();
        raiseBoxContributionContract.contribute{value: 2 ether}(4 ether, raiseId);

        uint minContribution = raiseBoxCore.getMinimumContribution();
        vm.prank(vitalik);
        vm.expectRevert();
        raiseBoxContributionContract.contribute{value: minContribution-0.09 ether }(minContribution-0.09 ether, raiseId);

        IRaiseBoxCore.RaiseState raiseState = raiseBoxCore.getRaiseState(raiseId);
        assertEq(raiseState == IRaiseBoxCore.RaiseState.CONTRIBUTION, true);

        vm.prank(carl);
        raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, raiseId);

        vm.prank(carl);
        // vm.expectRevert();
        raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, raiseId);
        
        vm.prank(carl);
        // vm.expectRevert();
        raiseBoxContributionContract.contribute{value: 0.5 ether}(0.5 ether, raiseId);

        // raiseBoxContributionContract.getTotalContributionsToRaise(raiseId);

    
        // advanceBlockTime(5 weeks + 1 seconds);
        // uint deadline = raiseBoxCore.getRaiseDeadline(raiseId);
        // assertTrue(block.timestamp > deadline);

        // // contribution exactly reaching target at deadline is accepted and should pass
        vm.prank(magiceden);
        raiseBoxContributionContract.contribute{value: 4 ether}(4 ether, raiseId);

        raiseBoxContributionContract.hasUserContributed(raiseId, ebby);raiseBoxContributionContract.hasUserContributed(raiseId, magiceden);
        raiseBoxContributionContract.getContributors(raiseId);
        raiseBoxContributionContract.getTotalContributors(raiseId);

        raiseBoxContributionContract.getTotalContributionsToRaise(raiseId);raiseBoxContributionContract.getContributionHistory(carl, raiseId);raiseBoxContributionContract.getContributionHistory(magiceden, raiseId);
        raiseBoxContributionContract.getUserRaiseContributions(raiseId, carl);
        // // raiseBoxCore.getRaiseState(raiseId);
        
        // vm.prank(arbitrum);
        // raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, raiseId);

        // vm.prank(ethereum);
        // raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, raiseId);

        // // assertions:
        // address creator = raiseBoxCore.getRaiseCreator(raiseId);
        // assertTrue(creator == ebby);
        // // assertEq(raiseBoxContributionContract.getContributionHistory(uche, raiseId), 0.4 ether);
    }

    function testCreate5ConcurrentRaises() public {
    // whitelist raise creator first
    // raise creators
    raiseBoxCore.verifyAndAddToWhitelist(uche);
    raiseBoxCore.verifyAndAddToWhitelist(arbitrum);
    raiseBoxCore.verifyAndAddToWhitelist(max);
    raiseBoxCore.verifyAndAddToWhitelist(sally);
    raiseBoxCore.verifyAndAddToWhitelist(carl);

    // uche creates a raise
    vm.startPrank(uche);
        bytes32 raiseId1 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectName:"uche's raise",
            valueProposition:"agi",
            raiseTarget:200 ether,
            projectDuration:52 weeks
        })
    );
    vm.stopPrank();

    // arbitrum creates a raise
    vm.startPrank(arbitrum);
        bytes32 raiseId2 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectName:"arbitrum's raise",
            valueProposition:"agi",
            raiseTarget:2000 ether,
            projectDuration:60 weeks
        })
    );
    vm.stopPrank();

    // max creates a raise
    vm.startPrank(max);
        bytes32 raiseId3 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectName:"max's raise",
            valueProposition:"agi",
            raiseTarget:500 ether,
            projectDuration:50 weeks
        })
    );
    vm.stopPrank();

    
    vm.startPrank(sally);
        bytes32 raiseId4 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectName:"hhhhhhhhhhh",
            valueProposition:"agi",
            raiseTarget:50000 ether,
            projectDuration:50 weeks
        })
    );
    vm.stopPrank();


    }
    
   function testCreateARaise() public {

    // whitelist raise creator first
    // raise creators
    raiseBoxCore.verifyAndAddToWhitelist(uche);
    // raiseBoxCore.verifyAndAddToWhitelist(ebby);
    raiseBoxCore.verifyAndAddToWhitelist(max);
    raiseBoxCore.verifyAndAddToWhitelist(sally);

    vm.startPrank(uche);
   bytes32 raiseId1 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectName:"sentient",
            valueProposition:"agi",
            raiseTarget:20 ether,
            projectDuration:52 weeks
        })
    );
    vm.stopPrank();

    vm.startPrank(gowagr);
        raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, raiseId1);
    vm.stopPrank();

    // advanceBlockTime(30 weeks);


    address[19] memory contributors = [
            ebby, sally, carl, 
            max, mark, alice, 
            joe, testOwner, sam, 
            vitalik, arbitrum, ethereum, 
            polymarket, elon, trump, 
            tether, base, magiceden, 
            openseas
            ];

        for (uint256 i = 0; i < contributors.length; i++) {
            vm.startPrank(contributors[i]);
            raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, raiseId1);
            vm.stopPrank();
        }

    vm.prank(uche);
    uint proposalId = raiseBoxProposalContract.hostProposal(
        raiseId1, 
        IRaiseBoxProposal.MilestoneInfo({
            description: "this is the first proposal for raisebox v3",
            milestone: "milestone achieved is creation of a steady stable release",
            dripPercent: 25
        })
        );

    raiseBoxProposalContract.getProposalState(raiseId1, proposalId);

    advanceBlockTime(2 days);

    vm.startPrank(ebby);
    raiseBoxVoting.vote(raiseId1, proposalId, true);
    vm.stopPrank();

    vm.startPrank(sally);
    raiseBoxVoting.vote(raiseId1, proposalId, true);
    vm.stopPrank();

    vm.startPrank(vitalik);
    raiseBoxVoting.vote(raiseId1, proposalId, false);
    vm.stopPrank();

    advanceBlockTime(7 days);

    raiseBoxProposalContract.getProposalInfo(raiseId1, proposalId);

    vm.startPrank(uche);
    raiseBoxVoting.triggerVoteTally(raiseId1, proposalId);
    vm.stopPrank();



    raiseBoxProposalContract.getProposalState(raiseId1, proposalId);

    // // second proposal

    advanceBlockTime(5 weeks);

    vm.prank(uche);
    uint proposalId2 = raiseBoxProposalContract.hostProposal(
        raiseId1, 
        IRaiseBoxProposal.MilestoneInfo({
            description: "this is the second proposal for raisebox v3",
            milestone: "now works with testnet faucet tokens",
            dripPercent: 25
        })
        );

    raiseBoxProposalContract.getProposalState(raiseId1, proposalId2);

    advanceBlockTime(2 days);

    vm.startPrank(ebby);
    raiseBoxVoting.vote(raiseId1, proposalId2, true);
    vm.stopPrank();

    vm.startPrank(sally);
    raiseBoxVoting.vote(raiseId1, proposalId2, false);
    vm.stopPrank();

    vm.startPrank(vitalik);
    raiseBoxVoting.vote(raiseId1, proposalId2, false);
    vm.stopPrank();

    advanceBlockTime(7 days);

    vm.startPrank(uche);
    raiseBoxVoting.triggerVoteTally(raiseId1, proposalId2);
    vm.stopPrank();

    // // third proposal

    advanceBlockTime(5 weeks);

    vm.prank(uche);
    uint proposalId3 = raiseBoxProposalContract.hostProposal(
        raiseId1, 
        IRaiseBoxProposal.MilestoneInfo({
            description: "this is the third proposal for raisebox v3",
            milestone: "testnet website for mvp ready",
            dripPercent: 15
        })
        );

    raiseBoxProposalContract.getProposalState(raiseId1, proposalId3);

    advanceBlockTime(2 days);

    vm.startPrank(ebby);
    raiseBoxVoting.vote(raiseId1, proposalId3, true);
    vm.stopPrank();

    vm.startPrank(sally);
    raiseBoxVoting.vote(raiseId1, proposalId3, false);
    vm.stopPrank();

    vm.startPrank(vitalik);
    raiseBoxVoting.vote(raiseId1, proposalId3, false);
    vm.stopPrank();

    advanceBlockTime(7 days);

    vm.startPrank(uche);
    raiseBoxVoting.triggerVoteTally(raiseId1, proposalId3);
    vm.stopPrank();


// // fourth proposal

    advanceBlockTime(5 weeks);

    vm.prank(uche);
    uint proposalId4 = raiseBoxProposalContract.hostProposal(
        raiseId1, 
        IRaiseBoxProposal.MilestoneInfo({
            description: "this is the fourth proposal for raisebox v3",
            milestone: "testnet website for mvp ready",
            dripPercent: 20
        })
        );

    raiseBoxProposalContract.getProposalState(raiseId1, proposalId4);
    advanceBlockTime(2 days);

    vm.startPrank(ebby);
    raiseBoxVoting.vote(raiseId1, proposalId4, true);
    vm.stopPrank();

    vm.startPrank(sally);
    raiseBoxVoting.vote(raiseId1, proposalId4, false);
    vm.stopPrank();

    vm.startPrank(vitalik);
    raiseBoxVoting.vote(raiseId1, proposalId4, false);
    vm.stopPrank();

    advanceBlockTime(7 days);

    vm.startPrank(uche);
    raiseBoxVoting.triggerVoteTally(raiseId1, proposalId4);
    vm.stopPrank();

    // // fifth proposal

    advanceBlockTime(5 weeks);

    vm.prank(uche);
    uint proposalId5 = raiseBoxProposalContract.hostProposal(
        raiseId1, 
        IRaiseBoxProposal.MilestoneInfo({
            description: "this is the fifth proposal for raisebox v3",
            milestone: "testnet website for mvp ready",
            dripPercent: 20
        })
        );

    raiseBoxProposalContract.getProposalState(raiseId1, proposalId5);
    vm.startPrank(sally);
    raiseBoxVoting.delegateVote(raiseId1, proposalId5, sally, vitalik );
    vm.stopPrank();

    

    // vm.startPrank(vitalik);
    // raiseBoxVoting.delegateVote(raiseId1, proposalId5, vitalik, ebby );
    // vm.stopPrank();

    advanceBlockTime(2 days);

    vm.startPrank(ebby);
    raiseBoxVoting.vote(raiseId1, proposalId5, true);
    vm.stopPrank();

    vm.startPrank(vitalik);
    raiseBoxVoting.vote(raiseId1, proposalId5, false);
    vm.stopPrank();

    

    advanceBlockTime(7 days);
   

    vm.startPrank(uche);
    raiseBoxVoting.triggerVoteTally(raiseId1, proposalId5);
    vm.stopPrank();

     // // sixth proposal

    advanceBlockTime(5 weeks);

    vm.prank(uche);
    vm.expectRevert();
    uint proposalId6 = raiseBoxProposalContract.hostProposal(
        raiseId1, 
        IRaiseBoxProposal.MilestoneInfo({
            description: "this is the sixth proposal for raisebox v3",
            milestone: "v3.5 is live",
            dripPercent: 25
        })
        );

   
    raiseBoxCore.getRaiseInfo(raiseId1);
    console.log(address(raiseBoxContributionContract).balance);
    console.log(address(raiseBoxDripHandler).balance);
    raiseBoxContributionContract.getContributors(raiseId1);
    raiseBoxContributionContract.getTotalContributors(raiseId1);
    IRaiseBoxCore.RaiseState raiseState = raiseBoxCore.getRaiseState(raiseId1);
    
    // raiseBoxCore.getRaiseState(raiseId2);


    
    // another raise by different project

//     vm.startPrank(ebby);
//    bytes32 raiseId2 = raiseBoxRaiseCreationContract.createNewRaise(
//         IRaiseBoxCore.ProjectInfo({
//             projectName:"shade l2",
//             valueProposition:"private layer 2 blockchain",
//             raiseTarget:20 ether,
//             projectDuration:52 weeks
//         })
//     );
//     vm.stopPrank();

//     vm.startPrank(gowagr);
//         raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, raiseId2);
//     vm.stopPrank();

//     // advanceBlockTime(30 weeks);


//     address[19] memory contributorsToRaise2 = [
//             uche, sally, carl, 
//             max, mark, alice, 
//             joe, testOwner, sam, 
//             vitalik, arbitrum, ethereum, 
//             polymarket, elon, trump, 
//             tether, base, magiceden, 
//             openseas
//             ];

//         for (uint256 i = 0; i < contributorsToRaise2.length; i++) {
//             vm.startPrank(contributorsToRaise2[i]);
//             raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, raiseId2);
//             vm.stopPrank();
//         }

//     vm.prank(ebby);
//     uint proposalIdForRaiseId2 = raiseBoxProposalContract.hostProposal(
//         raiseId2, 
//         IRaiseBoxProposal.MilestoneInfo({
//             description: "stealth addresses achieved in shade l2",
//             milestone: "wallets can perform transactions in stealth mode and then broadcast to the blockcahin when done.",
//             dripPercent: 20
//         })
//         );

//     advanceBlockTime(2 days);

//     vm.startPrank(openseas);
//     raiseBoxVoting.vote(raiseId2, proposalIdForRaiseId2, true);
//     vm.stopPrank();



    
//     // voting continues in parallelfor first raise
//     vm.startPrank(base);
//     raiseBoxVoting.vote(raiseId1, proposalId, true);
//     vm.stopPrank();

//     raiseBoxProposalContract.getProposalState(raiseId1, proposalId);





    


   }

   function testEndRaiseFailsWhenUnauthorizedCallerCalls() public {

        vm.startPrank(ebby);
   bytes32 raiseId = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectName:"sentient",
            valueProposition:"agi",
            raiseTarget:20 ether,
            projectDuration:52 weeks
        })
    );
    vm.stopPrank();

    vm.prank(ebby);
    vm.expectRevert();
    raiseBoxCore.endRaise(raiseId);
    
        
   }

//    function testCreateARaiseWithoutWhitelist() public {
//         vm.startPrank(max);
//         vm.expectRevert();
//         bytes32 projectId4 = raiseBoxRaiseCreationContract.createNewRaise(
//         IRaiseBoxCore.ProjectInfo({
//             projectName:"navy opsec",
//             valueProposition:"provide combat gear for navy for period of 5 years",
//             raiseTarget:35 ether,
//             projectDuration:60 weeks
//         })
//     );
//     vm.stopPrank();
//    }

//    function testContributionFailsAfterRaiseDurationElapse() public {
//     raiseBoxCore.verifyAndAddToWhitelist(max);
//       vm.startPrank(max);
//         bytes32 projectId4 = raiseBoxRaiseCreationContract.createNewRaise(
//         IRaiseBoxCore.ProjectInfo({
//             projectName:"navy opsec",
//             valueProposition:"provide combat gear for navy for period of 5 years",
//             raiseTarget:35 ether,
//             projectDuration:60 weeks
//         })
//     );
//     vm.stopPrank();

//     vm.startPrank(uche);
//     raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, projectId4);
//     vm.stopPrank();

//     advanceBlockTime(20 weeks); // allowed raise duration is 5 weeks

//     vm.startPrank(uche);
//     vm.expectRevert();
//     raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, projectId4);
//     vm.stopPrank();


//    }

//    function testUserCanContributeExactlyMinimumContributionAmount() public {
//      vm.startPrank(vitalik);
//         bytes32 projectId = raiseBoxRaiseCreationContract.createNewRaise(
//         IRaiseBoxCore.ProjectInfo({
//             projectName:"navy opsec",
//             valueProposition:"provide combat gear for navy for period of 5 years",
//             raiseTarget:35 ether,
//             projectDuration:60 weeks
//         })
//     );
//     vm.stopPrank();

//     vm.startPrank(ebby);
//     raiseBoxContributionContract.contribute{value: 0.1 ether}(0.1 ether, projectId );
//     vm.stopPrank();

//     vm.startPrank(ebby);
//     raiseBoxContributionContract.contribute{value: 0.1 ether}(0.1 ether, projectId );
//     vm.stopPrank();

//     vm.startPrank(max);
//     raiseBoxContributionContract.contribute{value: 0.1 ether}(0.1 ether, projectId );
//     vm.stopPrank();
//    }

//       function testContributionRevertsIfAmountIsGreaterThanMaxAllowedOrEqualRaiseTarget() public {
//      vm.startPrank(vitalik);
//         bytes32 projectId = raiseBoxRaiseCreationContract.createNewRaise(
//         IRaiseBoxCore.ProjectInfo({
//             projectName:"navy opsec",
//             valueProposition:"provide combat gear for navy for period of 5 years",
//             raiseTarget:35 ether,
//             projectDuration:60 weeks
//         })
//     );
//     vm.stopPrank();

//     vm.startPrank(ebby);
//     raiseBoxContributionContract.contribute{value: 0.1 ether}(0.1 ether, projectId );
//     vm.stopPrank();

//     vm.startPrank(ebby);
//     vm.expectRevert();
//     raiseBoxContributionContract.contribute{value: 36 ether}(36 ether, projectId );
//     vm.stopPrank(); // 6.9 more ether alllowed for this user but my error doesn't cover decimal (fix required)

//     vm.startPrank(max);
//     vm.expectRevert();
//     raiseBoxContributionContract.contribute{value: 35 ether}(35 ether, projectId );
//     vm.stopPrank();

//     vm.startPrank(ebby);
//    vm.expectRevert();
//     raiseBoxContributionContract.contribute{value: 0 ether}(0 ether, projectId );
//     vm.stopPrank();
//    }

//    function testCannotContributeAfterRaiseStateEntersProposal() public {
//     // creates a project and contributes till raise passes
//     // state switches from inactive to contribution to proposal 0->1->2
//     // at proposal state, raise has already passed and any contribution afterwards should revert
//     bytes32 projectId = contributeToTestProject();

//     // try contributing after this, contributor must be user who hasn't contributed before
// vm.startPrank(vitalik);
//    vm.expectRevert();
//     raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, projectId );
// vm.stopPrank();

//    }

   

//     function testContributeToProjects() public {

//         /// creates a raise and contributes till the raise passes:
//         bytes32 projectId = contributeToTestProject();

//         console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
//         console.log("project owner balance:", ben.balance);


//         // raise passed for project 1, can now host proposal

//         // proposal 1
//         vm.startPrank(ben);

//         uint256 proposalId1 = raiseBoxProposalContract.hostProposal(
//             "new hires", "hiring of devs for project, 2 smart contract devs and 1 rust dev", projectId, 10
//         );

//         vm.stopPrank();

//         // proposal hosted, voting can now commence:

//         // jump to just after scheduled voting start for proposal 1
//         uint256 _start = raiseBoxVoting.s_votingStartTime(projectId, 1);
//         raiseBoxVoting.delegateVote(projectId, 1, max, uche);
//         vm.warp(_start + 1);

//         vm.startPrank(mark);
//         raiseBoxVoting.vote(projectId, 1, true);
//         vm.stopPrank();

//         vm.startPrank(sally);
//         raiseBoxVoting.vote(projectId, 1, false);
//         vm.stopPrank();

//         vm.startPrank(uche);
//         raiseBoxVoting.vote(projectId, 1, true);
//         vm.stopPrank();

//         vm.startPrank(ebby);
//         raiseBoxVoting.vote(projectId, 1, true);
//         vm.stopPrank();

//         vm.warp(_start + 10 days);
//         console.log(address(raiseBoxProposalContract));

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended(voting duration exceeded by atleast 12 hours) and the caller is in-fact the proposal owner
//         vm.startPrank(ben);
//         raiseBoxVoting.triggerVoteTally(projectId, 1);
//         vm.stopPrank();

//         (uint256 forVotes, uint256 againstVotes, uint256 aggregate) = raiseBoxVoting.getProposalVotes(projectId, 1);

//         console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
//         console.log("project owner balance:", ben.balance);

//         // proposal 2
//         vm.startPrank(ben);

//         advanceBlockTime(4 weeks);

//         uint256 proposalId2 = raiseBoxProposalContract.hostProposal(
//             "new website", "pay for new website", projectId, 25
//         );

//         vm.stopPrank();

//         // jump to just after scheduled voting start for proposal 2
//         uint256 _start2 = raiseBoxVoting.s_votingStartTime(projectId, proposalId2);
//         vm.warp(_start2 + 1);

//         vm.startPrank(mark);
//         raiseBoxVoting.vote(projectId, proposalId2, false);
//         vm.stopPrank();

//         vm.startPrank(sally);
//         raiseBoxVoting.vote(projectId, proposalId2, true);
//         vm.stopPrank();

//         vm.startPrank(uche);
//         raiseBoxVoting.vote(projectId, proposalId2, true);
//         vm.stopPrank();

//         vm.warp(_start2 + 10 days);

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
//         vm.startPrank(ben);
//         raiseBoxVoting.triggerVoteTally(projectId, proposalId2);
//         vm.stopPrank();

//         console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
//         console.log("project owner balance:", ben.balance);

//         // proposal 3

//         vm.startPrank(ben);

//         advanceBlockTime(4 weeks);

//         uint256 proposalId3 = raiseBoxProposalContract.hostProposal(
//             "launch mvp", "beta test mvp", projectId, 20
//         );

//         vm.stopPrank();

//         // jump to just after scheduled voting start for proposal 2
//         uint256 _start3 = raiseBoxVoting.s_votingStartTime(projectId, proposalId3);
//         vm.warp(_start3 + 1);

//         vm.startPrank(mark);
//         raiseBoxVoting.vote(projectId, proposalId3, false);
//         vm.stopPrank();

//         vm.startPrank(sally);
//         raiseBoxVoting.vote(projectId, proposalId3, true);
//         vm.stopPrank();

//         vm.startPrank(uche);
//         raiseBoxVoting.vote(projectId, proposalId3, true);
//         vm.stopPrank();

//         vm.warp(_start3 + 10 days);

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
//         vm.startPrank(ben);
//         raiseBoxVoting.triggerVoteTally(projectId, proposalId3);
//         vm.stopPrank();

//         console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
//         console.log("project owner balance:", ben.balance);

//         // proposal 4

//         vm.startPrank(ben);

//         advanceBlockTime(4 weeks);

//         uint256 proposalId4 = raiseBoxProposalContract.hostProposal(
//             "first testnet app",
//             "testnet faucet and app v1 creation",
//             projectId,
//             20
//         );

//         vm.stopPrank();

//         // jump to just after scheduled voting start for proposal 2
//         uint256 _start4 = raiseBoxVoting.s_votingStartTime(projectId, proposalId4);
//         vm.warp(_start4 + 1);

//         vm.startPrank(mark);
//         raiseBoxVoting.vote(projectId, proposalId4, false);
//         vm.stopPrank();

//         vm.startPrank(sally);
//         raiseBoxVoting.vote(projectId, proposalId4, true);
//         vm.stopPrank();

//         vm.startPrank(uche);
//         raiseBoxVoting.vote(projectId, proposalId4, true);
//         vm.stopPrank();

//         vm.warp(_start4 + 10 days);

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
//         vm.startPrank(ben);
//         raiseBoxVoting.triggerVoteTally(projectId, proposalId4);
//         vm.stopPrank();

//         console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
//         console.log("project owner balance:", ben.balance);

//         // proposal 5

//         vm.startPrank(ben);

//         advanceBlockTime(5 weeks);

//         uint256 proposalId5 = raiseBoxProposalContract.hostProposal(
//             "v2 launch",
//             "version 2 of testnet app is ready to be tested",
//             projectId,
//             20
//         );

//         vm.stopPrank();

//         // jump to just after scheduled voting start for proposal 2
//         uint256 _start5 = raiseBoxVoting.s_votingStartTime(projectId, proposalId5);
        
//         vm.startPrank(max);
//         raiseBoxVoting.delegateVote(
//         projectId, proposalId5, max, ebby
//         );

//         vm.stopPrank();

//         vm.warp(_start5 + 1);

//         vm.startPrank(mark);
//         raiseBoxVoting.vote(projectId, proposalId5, false);
//         vm.stopPrank();

//         vm.startPrank(sally);
//         raiseBoxVoting.vote(projectId, proposalId5, true);
//         vm.stopPrank();

//         vm.startPrank(uche);
//         raiseBoxVoting.vote(projectId, proposalId5, true);
//         vm.stopPrank();

//         vm.startPrank(ebby);
//         raiseBoxVoting.vote(projectId, proposalId5, true);
//         vm.stopPrank();

//         vm.warp(_start5 + 10 days);

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
//         vm.startPrank(ben);
//         raiseBoxVoting.triggerVoteTally(projectId, proposalId5);
//         vm.stopPrank();

//         vm.startPrank(ben);

//         advanceBlockTime(5 weeks);
//         // proposal 6

//         uint256 proposalId6 = raiseBoxProposalContract.hostProposal(
//             "v2 launch",
//             "version 2 of testnet app is ready to be tested",
//             projectId,
//             20
//         );

//         vm.stopPrank();

//         // vm.startPrank(ebby);
//         // bytes32 projectId2 = raiseBoxRaiseCreationContract.createNewRaise(
//         //     IRaiseBoxCore.ProjectInfo({
//         //     projectName:"ebbycore",
//         //     valueProposition:"personal project",
//         //     raiseTarget:200 ether,
//         //     projectDuration:60 weeks
//         // })
//         // );
//         // vm.stopPrank();

//         raiseBoxRaiseCreationContract.getAllRaisesCreated();
//         raiseBoxCore.getProtocol();
//         raiseBoxCore.getMinimumContribution();
//         raiseBoxCore.getAmtRaisedByProject(projectId);
//         raiseBoxCore.getRaiseState(projectId);
//         raiseBoxCore.getRaiseCreator(projectId);
//         raiseBoxCore.getAmountToRaise(projectId);
//         raiseBoxCore.doesRaiseExist(projectId);
//         raiseBoxCore.getRaiseBoxOwner();
//         raiseBoxCore.isRaiseCreator(ben, projectId);
//         raiseBoxCore.getRaiseDeadline();
//         vm.expectRevert();
//         raiseBoxCore.updateRaiseInfo(
//             IRaiseBoxCore.ProjectInfo({
//             projectName:"ebbycore",
//             valueProposition:"personal project",
//             raiseTarget:200 ether,
//             projectDuration:60 weeks
//         }),
//         block.timestamp,
//         300 ether,
//         true,
//         projectId,
//         vitalik
//         );
//         raiseBoxCore.isRaiseCreator(address(0), projectId);
//         raiseBoxProposalContract.getProposalCount(projectId);
//         raiseBoxCore.getProposalsHosted(projectId);
//         raiseBoxProposalContract.getProposalState( projectId, proposalId5);

//         // raiseBoxCore.getRaiseState(projectId);
//         // raiseBoxProposalContract.isValidProposal(0x0ef765bb5612bfab35f0518fdb194eb02394c410530030a57d2fecaabd944ef8, 1);
//         // raiseBoxCore.doesRaiseExist(0x0ef765bb5612bfab35f0518fdb194eb02394c410530030a57d2fecaabd944ef8);
//         // raiseBoxProposalContract.getProposalInfo(projectId, 6);
//         // raiseBoxCore.getProposalState(0x0ef765bb5612bfab35f0518fdb194eb02394c410530030a57d2fecaabd944ef8, 6);


        
        
//     }


//     function testVotingAndDelegationOnProposalsWorks() public {
//         console.log("drip handler intial balance:", address(raiseBoxDripHandler).balance);
//         console.log("raise owner initial balance:", ben.balance);
//         // create and contribute to raise till it passes
//         bytes32 raiseId = contributeToTestProject();

//         console.log("drip handler balance after raise passes:", address(raiseBoxDripHandler).balance);
//         console.log("raise owner balance after raise passes:", ben.balance);

//         // host first proposal ---> proposal1
//         vm.prank(ben);
//         uint256 proposalId = raiseBoxProposalContract.hostProposal(
//             "MVP",
//             "Finished building the minimum viable product for sentient agi and it's ready for testing",
//             raiseId,
//             20
//         );

//         // delegate votes to ethereum:
//         raiseBoxVoting.delegateVote(raiseId, proposalId, arbitrum, ethereum);
//         raiseBoxVoting.delegateVote(raiseId, proposalId, openseas, ethereum);
//         raiseBoxVoting.delegateVote(raiseId, proposalId, gowagr, ethereum);
//         raiseBoxVoting.delegateVote(raiseId, proposalId, elon, ethereum);
//         raiseBoxVoting.delegateVote(raiseId, proposalId, magiceden, trump);
//         raiseBoxVoting.delegateVote(raiseId, proposalId, polymarket, trump);
//         // vm.startPrank(ethereum);
//         // raiseBoxVoting.vote(raiseId, proposalId, true);

//         advanceBlockTime(48 hours);
        
//         // raiseBoxVoting.delegateVote(raiseId, proposalId, tether, trump);

//         address[10] memory voters = [ebby, sally, uche, max, mark, alice, joe, testOwner, sam, vitalik];

//         // delegators votes:
//         vm.startPrank(ethereum);
//         raiseBoxVoting.vote(raiseId, proposalId, true);
//         vm.stopPrank();


//         for (uint256 i = 0; i < voters.length; i++) {
//             vm.startPrank(voters[i]);
//             if (i % 2 == 0) {
//                 raiseBoxVoting.vote(raiseId, proposalId, true );

//             } else {
//                 raiseBoxVoting.vote(raiseId, proposalId, false  );
//             }
            
//             vm.stopPrank();
//         }

//         vm.startPrank(tether);
//         raiseBoxVoting.vote(raiseId, proposalId, false);
//         vm.stopPrank();

//         vm.startPrank(trump);
//         raiseBoxVoting.vote(raiseId, proposalId, false);
//         vm.stopPrank();

//         raiseBoxVoting.getProposalVotes(raiseId, proposalId);


//         advanceBlockTime(7 days);

//         raiseBoxVoting.getProposalVotes(raiseId, proposalId);

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
//         vm.startPrank(ben);
//         raiseBoxVoting.triggerVoteTally(raiseId, proposalId);
//         vm.stopPrank();

//         console.log("drip handler balance after first proposal passes:", address(raiseBoxDripHandler).balance);
//         console.log("raise owner balance after first proposal passes:", ben.balance);

         
         
         
//          // host second proposal ---> proposal2
//          advanceBlockTime(4 weeks);
//          raiseBoxCore.getRaiseState(raiseId);
//         vm.prank(ben);
//         uint256 proposalId1 = raiseBoxProposalContract.hostProposal(
//             "built public API",
//             "Public API for use by other devs seeking to integrate sentient has been completed and tested",
//             raiseId,
//             20
//         );

//         advanceBlockTime(48 hours);

        
//         // delegators votes:
//         vm.startPrank(ethereum);
//         raiseBoxVoting.vote(raiseId, proposalId1, true);
//         vm.stopPrank();

//     for (uint256 i = 0; i < voters.length; i++) {
//             vm.startPrank(voters[i]);
//             if (i % 2 == 0) {
//                 raiseBoxVoting.vote(raiseId, proposalId1, true );

//             } else {
//                 raiseBoxVoting.vote(raiseId, proposalId1, false  );
//             }
            
//             vm.stopPrank();
//         }

//         vm.startPrank(tether);
//         raiseBoxVoting.vote(raiseId, proposalId1, true);
//         vm.stopPrank();

//         vm.startPrank(trump);
//         raiseBoxVoting.vote(raiseId, proposalId1, false);
//         vm.stopPrank();

//         raiseBoxVoting.getProposalVotes(raiseId, proposalId1);


//         advanceBlockTime(7 days);

//         raiseBoxVoting.getProposalVotes(raiseId, proposalId1);

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
//         vm.startPrank(ben);
//         // vm.expectRevert();
//         raiseBoxVoting.triggerVoteTally(raiseId, proposalId1);
//         vm.stopPrank();

//         console.log("drip handler balance after second proposal passes:", address(raiseBoxDripHandler).balance);
//         console.log("raise owner balance after second proposal passes:", ben.balance);



//         // host third proposal ---> proposal3
//          advanceBlockTime(4 weeks);
//          raiseBoxCore.getRaiseState(raiseId);
//         vm.prank(ben);
//         uint256 proposalId2 = raiseBoxProposalContract.hostProposal(
//             "finished tesntet launch",
//             "public testnet is live and ready for testers to test how sentient agi works for real",
//             raiseId,
//             20
//         );

//         // delegate votes to ethereum:
//         address[4] memory delegators = [arbitrum, openseas, gowagr, elon];

//         for (uint256 i = 0; i < delegators.length; i++) {
//             if (i == delegators.length - 1) {
//             vm.startPrank(delegators[i]);
//             raiseBoxVoting.delegateVote(raiseId, proposalId2, delegators[i], ethereum);
//             vm.stopPrank();
//             } else {
//             vm.startPrank(delegators[i]);
//             raiseBoxVoting.delegateVote(raiseId, proposalId2, delegators[i], tether);
//             vm.stopPrank();
//             }
//         }
//         // raiseBoxVoting.delegateVote(raiseId, proposalId2, arbitrum, tether);
//         // raiseBoxVoting.delegateVote(raiseId, proposalId2, openseas, tether);
//         // raiseBoxVoting.delegateVote(raiseId, proposalId2, gowagr, tether);
//         // raiseBoxVoting.delegateVote(raiseId, proposalId2, elon, ethereum);

//         advanceBlockTime(48 hours);

        
//         // delegators votes:
//         vm.startPrank(ethereum);
//         raiseBoxVoting.vote(raiseId, proposalId2, false);
//         vm.stopPrank();
        

//     for (uint256 i = 0; i < voters.length; i++) {
//             vm.startPrank(voters[i]);
//             if (i % 2 == 0) {
//                 raiseBoxVoting.vote(raiseId, proposalId2, true );

//             } else {
//                 raiseBoxVoting.vote(raiseId, proposalId2, false  );
//             }
            
//             vm.stopPrank();
//         }

//         vm.startPrank(tether);
//         raiseBoxVoting.vote(raiseId, proposalId2, false);
//         vm.stopPrank();

//         vm.startPrank(trump);
//         raiseBoxVoting.vote(raiseId, proposalId2, false);
//         vm.stopPrank();

//         raiseBoxVoting.getProposalVotes(raiseId, proposalId2);


//         advanceBlockTime(7 days);

//         raiseBoxVoting.getProposalVotes(raiseId, proposalId2);

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
//         vm.startPrank(ben);
//         // vm.expectRevert();
//         raiseBoxVoting.triggerVoteTally(raiseId, proposalId2);
//         vm.stopPrank();

//         console.log("drip handler balance after third proposal passes:", address(raiseBoxDripHandler).balance);
//         console.log("raise owner balance after third proposal passes:", ben.balance);

//         raiseBoxCore.isRaiseCreator(ben, raiseId);
//         raiseBoxCore.getAmtRaisedByProject(raiseId); // 13,200 -- 1,027
//         raiseBoxCore.getAmountToRaise(raiseId); // 13, 500 -- 1,300
//         raiseBoxCore.getRaiseInfo(raiseId);
//         uint256 proposalCount = 3;

//         for (uint256 i = 0; i < 12; i++ ) {
//         advanceBlockTime(4 weeks);
//         vm.startPrank(ben);
//         uint256 proposalId2 = raiseBoxProposalContract.hostProposal(
//             "finished tesntet launch",
//             "public testnet is live and ready for testers to test how sentient agi works for real",
//             raiseId,
//             20
//         );
//         proposalCount++;
//         vm.stopPrank();


//         // delegate votes to ethereum:
//         address[4] memory delegators = [arbitrum, openseas, gowagr, elon];

//         for (uint256 i = 0; i < delegators.length; i++) {
//             if (i == delegators.length - 1) {
//             vm.startPrank(delegators[i]);
//             raiseBoxVoting.delegateVote(raiseId, proposalId2, delegators[i], ethereum);
//             vm.stopPrank();
//             } else {
//             vm.startPrank(delegators[i]);
//             raiseBoxVoting.delegateVote(raiseId, proposalId2, delegators[i], tether);
//             vm.stopPrank();
//             }
//         }
//         // raiseBoxVoting.delegateVote(raiseId, proposalId2, arbitrum, tether);
//         // raiseBoxVoting.delegateVote(raiseId, proposalId2, openseas, tether);
//         // raiseBoxVoting.delegateVote(raiseId, proposalId2, gowagr, tether);
//         // raiseBoxVoting.delegateVote(raiseId, proposalId2, elon, ethereum);

//         advanceBlockTime(48 hours);

        
//         // delegators votes:
//         vm.startPrank(ethereum);
//         raiseBoxVoting.vote(raiseId, proposalId2, false);
//         vm.stopPrank();
        

//     for (uint256 i = 0; i < voters.length; i++) {
//             vm.startPrank(voters[i]);
//             if (i % 2 == 0) {
//                 raiseBoxVoting.vote(raiseId, proposalId2, true );

//             } else {
//                 raiseBoxVoting.vote(raiseId, proposalId2, false  );
//             }
            
//             vm.stopPrank();
//         }

//         vm.startPrank(tether);
//         raiseBoxVoting.vote(raiseId, proposalId2, false);
//         vm.stopPrank();

//         vm.startPrank(trump);
//         raiseBoxVoting.vote(raiseId, proposalId2, false);
//         vm.stopPrank();

//         raiseBoxVoting.getProposalVotes(raiseId, proposalId2);


//         advanceBlockTime(7 days);

//         raiseBoxVoting.getProposalVotes(raiseId, proposalId2);

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
//         vm.startPrank(ben);
//         // vm.expectRevert();
//         raiseBoxVoting.triggerVoteTally(raiseId, proposalId2);
//         vm.stopPrank();

//         console.log("drip handler balance after", proposalCount, "proposal passes:", address(raiseBoxDripHandler).balance);
//         console.log("raise owner balance after", proposalCount, "proposal passes:", ben.balance);
//         raiseBoxVoting.getFailedProposalsCount(raiseId);
        


//         }





//     }

    function testRaiseBoxCompleteFlow() public {
        // from creation of raise -> contribution -> hosting of proposals -> voting -> drips -> end of raise
        vm.startPrank(ben);
        bytes32 raiseId_ = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
            projectName:"sentient",
            valueProposition:"agi",
            raiseTarget:144 ether,
            projectDuration:60 weeks
        })
        );
        vm.stopPrank();

        // contribute

        address[12] memory contributors = [
            ebby, sally, uche, 
            max, mark, arbitrum,
            openseas, carl, base,
            tether, magiceden, gowagr
            ];

        for (uint256 i = 0; i < contributors.length; i++) {
            vm.startPrank(contributors[i]);
            raiseBoxContributionContract.contribute{value: 12 ether}(12 ether, raiseId_);
            vm.stopPrank();
        }

       hostAndVoteOnProposals(raiseId_);

        console.log(address(raiseBoxDripHandler).balance);
        raiseBoxCore.getRaiseInfo(raiseId_);
        raiseBoxVoting.getVotingStartTime(raiseId_, 11);



    }

    // test 2 critical bugs in voting contract current implementation before fixing:
    // 1. any contirbutor(attacker) can force deleagte another contributor's vote by colluding with another contributor via delegation
    // 2. a contributor that has delegated their vote can still receive delegation which leads to vote loss since he cannot vote as he initially delagted beforehand

    function testVulInCurrentVotingContractImpl() public {
        // whitelist raise creator:
        address raiseCreator = makeAddr("raiseCreator");
        raiseBoxCore.verifyAndAddToWhitelist(raiseCreator);

        // raiseCreator creates a new raise:
        vm.startPrank(raiseCreator);
        bytes32 raiseId = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
                projectName: "new project",
                valueProposition: "to test vulnerability in voting contract",
                raiseTarget: 10 ether,
                projectDuration: 60 weeks
            })
        );
        vm.stopPrank();

        // create and fund users that will contribute to the raise:
        address contributor1 = makeAddr("contributor1");
        vm.deal(contributor1, 1000 ether);

        address contributor2 = makeAddr("contributor2");
        vm.deal(contributor2, 1000 ether);

        address colluder = makeAddr("colluder");
        vm.deal(colluder, 500 ether);

        address attacker = makeAddr("attacker");
        vm.deal(attacker, 20 ether);

        address contributor3 = makeAddr("contributor3");
        vm.deal(contributor3, 400 ether);

        // contributors contribute to raise:
        address[5] memory contributors = [contributor1, contributor2, colluder, attacker, contributor3];
        for (uint256 i = 0; i < contributors.length; i++) {
            vm.startPrank(contributors[i]);
            raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, raiseId);
            vm.stopPrank();
        }
        

        // raiseCreator hosts a proposal since raise passed, 10 ether successfully raised:
        vm.startPrank(raiseCreator);
        uint256 proposalId1 = raiseBoxProposalContract.hostProposal(
            raiseId, 
            IRaiseBoxProposal.MilestoneInfo({
                description: "completed mvp for new project",
                milestone: "mvp",
                dripPercent: 25
            })
        );

        // attack happens here for the first proposal:
        // attack force delegate other contributors votes:
        // for (uint256 a = 0; a < contributors.length; a++) {
        //     vm.startPrank(attacker);
        //     if (a == 0 || a == 1 || a == 4 || a == 3) {
        //         raiseBoxVoting.delegateVote(raiseId, proposalId1, contributors[a], colluder);
        //     }
        //     vm.stopPrank();
        // }

        // vul 1: fixed by ensuring caller is in-fact the owner of the vote to delegate
        vm.startPrank(attacker);
        vm.expectRevert();
        raiseBoxVoting.delegateVote(raiseId, proposalId1, contributor1, colluder);
        vm.stopPrank();

        // vul2: fixed by ensuring a contributor that has delegated votes can no longer receive vote delagation, preventing loss of votes delegated to himafter his own delegation

        vm.startPrank(attacker);
        // vm.expectRevert();
        raiseBoxVoting.delegateVote(raiseId, proposalId1, attacker, colluder);
        vm.stopPrank();

        vm.startPrank(contributor2);
        vm.expectRevert();
        raiseBoxVoting.delegateVote(raiseId, proposalId1, contributor2, attacker);
        vm.stopPrank();

        vm.startPrank(contributor3);
        // vm.expectRevert();
        raiseBoxVoting.delegateVote(raiseId, proposalId1, contributor3, attacker);
        vm.stopPrank();


        // advance time so voting can begin
        advanceBlockTime(2 days);

        // attacker tries to vote but cannot since he's been marked above has a delegatee and delegatees cannot vote as it's assumed that they lost voting rights on delegation, since contributor2 losses vote
        vm.startPrank(attacker);
        vm.expectRevert();
        raiseBoxVoting.vote(raiseId, proposalId1, true);
        vm.stopPrank();

        // legit contributors tries to vote but cannot since their votes have been stolen from them by `attacker` during forced delegation
        vm.startPrank(contributor1);
        // vm.expectRevert();
        raiseBoxVoting.vote(raiseId, proposalId1, true);
        vm.stopPrank();

        // colluder can vote now with 5 votes, his and those granted him by the attacker and he is going to vote `false`
        // @notice contributor1 voted true but it won't count, only what the colluder wants counts, attacker won
        vm.startPrank(colluder);
        raiseBoxVoting.vote(raiseId, proposalId1, false);
        vm.stopPrank();
        // after fix, colluder can vote with just 1 now since deleagtion of stolen votes to him is no longer possible

        // adavance block time so votes can be tallied
        advanceBlockTime(7 days);

        vm.prank(raiseCreator);
        raiseBoxVoting.triggerVoteTally(raiseId, proposalId1);

        raiseBoxCore.getRaiseInfo(raiseId);
    }

}
