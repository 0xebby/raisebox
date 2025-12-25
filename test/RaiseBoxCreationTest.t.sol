// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import {TestsHelpers} from "./TestsHelpers.sol";
import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";

contract RaiseBoxCreationTest is Test, TestsHelpers {
    
   function testCreateARaise() public {

    // whitelist raise creator first
    // raise creators
    raiseBoxCore.verifyAndAddToWhitelist(uche);
    // raiseBoxCore.verifyAndAddToWhitelist(ebby);
    raiseBoxCore.verifyAndAddToWhitelist(max);
    raiseBoxCore.verifyAndAddToWhitelist(sally);

    vm.startPrank(uche);
   bytes32 projectId1 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectOwner:uche,
            projectName:"sentient",
            valueProposition:"agi",
            raiseTarget:20 ether,
            projectDuration:52 weeks
        })
    );
    vm.stopPrank();

    vm.startPrank(ebby);
   bytes32 projectId2 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectOwner:ebby,
            projectName:"arbitrum",
            valueProposition:"blazing fast L2 built on ethereum's security",
            raiseTarget:200 ether,
            projectDuration:55 weeks
        })
    );
    vm.stopPrank();

    vm.startPrank(sally);
   bytes32 projectId3 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectOwner:sally,
            projectName:"signal",
            valueProposition:"decentralized social app",
            raiseTarget:50 ether,
            projectDuration:59 weeks
        })
    );
    vm.stopPrank();

    vm.startPrank(max);
   bytes32 projectId4 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectOwner:max,
            projectName:"navy opsec",
            valueProposition:"provide combat gear for navy for period of 5 years",
            raiseTarget:35 ether,
            projectDuration:60 weeks
        })
    );
    vm.stopPrank();




//     raiseBoxCore.getRaiseInfo(projectId);

//     raiseBoxCore.getRaiseState(projectId);

//     address[5] memory contributors = [ebby, sally, ben, max, mark];

//     for (uint256 i = 0; i < contributors.length; i++) {
//             vm.startPrank(contributors[i]);
//             raiseBoxContributionContract.contribute{value: 4 ether}(4 ether, projectId);
//             vm.stopPrank();
//         }

    
//      vm.startPrank(uche);

//         uint256 proposalId1 = raiseBoxProposalContract.hostProposal(
//             "new hires", "hiring of devs for project, 2 smart contract devs and 1 rust dev", projectId, 10
//         );

//     vm.stopPrank();
//     raiseBoxCore.getRaiseInfo(projectId);
//     raiseBoxCore.getRaiseState(projectId);

//     // advanceBlockTime(4 weeks);

//     //  vm.startPrank(uche);

//     //     uint256 proposalId2 = raiseBoxProposalContract.hostProposal(
//     //         "second proposal", "hiring of devs for project, 2 smart contract devs and 1 rust dev", projectId, 10
//     //     );

//     // vm.stopPrank();
//     // raiseBoxCore.getRaiseInfo(projectId);
//     // raiseBoxCore.getRaiseState(projectId);

//    // jump to just after scheduled voting start for proposal 1
//         uint256 _start = raiseBoxVoting.votingStartTime(projectId, 1);
//         vm.warp(_start + 1);

//         vm.startPrank(mark);
//         raiseBoxVoting.vote(projectId, 1, true, mark);
//         vm.stopPrank();

//         vm.startPrank(sally);
//         raiseBoxVoting.vote(projectId, 1, false, sally);
//         vm.stopPrank();

//         vm.startPrank(max);
//         raiseBoxVoting.delegateVote(projectId, 1, max, ben);
//         raiseBoxVoting.vote(projectId, 1, true, ben);
//         vm.stopPrank();

//         vm.startPrank(ebby);
//         raiseBoxVoting.vote(projectId, 1, true, ebby);
//         vm.stopPrank();

//         vm.warp(_start + 10 days);
//         console.log(address(raiseBoxProposalContract));
//         // raiseBoxVoting.endVoting(projectId, 1);

//         // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended(voting duration exceeded by atleast 12 hours) and the caller is in-fact the proposal owner
//         vm.startPrank(uche);
//         raiseBoxVoting.triggerVoteTally(projectId, 1);
//         vm.stopPrank();

//         raiseBoxCore.getRaiseState(projectId);
//         raiseBoxCore.getRaiseInfo(projectId);

   }

   function testCreateARaiseWithoutWhitelist() public {
        vm.startPrank(max);
        vm.expectRevert();
        bytes32 projectId4 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectOwner:max,
            projectName:"navy opsec",
            valueProposition:"provide combat gear for navy for period of 5 years",
            raiseTarget:35 ether,
            projectDuration:60 weeks
        })
    );
    vm.stopPrank();
   }

   function testContributionFailsAfterRaiseDurationElapse() public {
    raiseBoxCore.verifyAndAddToWhitelist(max);
      vm.startPrank(max);
        bytes32 projectId4 = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectOwner:max,
            projectName:"navy opsec",
            valueProposition:"provide combat gear for navy for period of 5 years",
            raiseTarget:35 ether,
            projectDuration:60 weeks
        })
    );
    vm.stopPrank();

    vm.startPrank(uche);
    raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, projectId4);
    vm.stopPrank();

    advanceBlockTime(20 weeks); // allowed raise duration is 5 weeks

    vm.startPrank(uche);
    vm.expectRevert();
    raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, projectId4);
    vm.stopPrank();


   }

   function testUserCanContributeExactlyMinimumContributionAmount() public {
     vm.startPrank(vitalik);
        bytes32 projectId = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectOwner:vitalik,
            projectName:"navy opsec",
            valueProposition:"provide combat gear for navy for period of 5 years",
            raiseTarget:35 ether,
            projectDuration:60 weeks
        })
    );
    vm.stopPrank();

    vm.startPrank(ebby);
    raiseBoxContributionContract.contribute{value: 0.1 ether}(0.1 ether, projectId );
    vm.stopPrank();

    vm.startPrank(ebby);
    raiseBoxContributionContract.contribute{value: 0.1 ether}(0.1 ether, projectId );
    vm.stopPrank();

    vm.startPrank(max);
    raiseBoxContributionContract.contribute{value: 0.1 ether}(0.1 ether, projectId );
    vm.stopPrank();
   }

      function testContributionRevertsIfAmountIsGreaterThanMaxAllowedOrEqualRaiseTarget() public {
     vm.startPrank(vitalik);
        bytes32 projectId = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectOwner:vitalik,
            projectName:"navy opsec",
            valueProposition:"provide combat gear for navy for period of 5 years",
            raiseTarget:35 ether,
            projectDuration:60 weeks
        })
    );
    vm.stopPrank();

    vm.startPrank(ebby);
    raiseBoxContributionContract.contribute{value: 0.1 ether}(0.1 ether, projectId );
    vm.stopPrank();

    vm.startPrank(ebby);
    vm.expectRevert();
    raiseBoxContributionContract.contribute{value: 36 ether}(36 ether, projectId );
    vm.stopPrank(); // 6.9 more ether alllowed for this user but my error doesn't cover decimal (fix required)

    vm.startPrank(max);
    vm.expectRevert();
    raiseBoxContributionContract.contribute{value: 35 ether}(35 ether, projectId );
    vm.stopPrank();

    vm.startPrank(ebby);
   vm.expectRevert();
    raiseBoxContributionContract.contribute{value: 0 ether}(0 ether, projectId );
    vm.stopPrank();
   }

   function testCannotContributeAfterRaiseStateEntersProposal() public {
    // creates a project and contributes till raise passes
    // state switches from inactive to contribution to proposal 0->1->2
    // at proposal state, raise has already passed and any contribution afterwards should revert
    bytes32 projectId = contributeToTestProject();

    // try contributing after this, contributor must be user who hasn't contributed before
vm.startPrank(vitalik);
   vm.expectRevert();
    raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, projectId );
vm.stopPrank();

   }

   

    function testContributeToProjects() public {

        /// creates a raise and contributes till the raise passes:
        bytes32 projectId = contributeToTestProject();
        uint256 numOfProposalsHosted;


        console.log("balances at the start:");

        console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
        console.log("project owner balance:", ben.balance);


        // raise passed for project 1, can now host proposal

        // proposal 1

        uint256 maxContribution = raiseBoxContributionContract.getMaxContributionAllowedForProject(projectId);
        console.log(maxContribution);
        raiseBoxCore.getRaiseState(projectId);

        vm.startPrank(ben);

        uint256 proposalId1 = raiseBoxProposalContract.hostProposal(
            "new hires", "hiring of devs for project, 2 smart contract devs and 1 rust dev", projectId, 10
        );
        numOfProposalsHosted++;

        vm.stopPrank();

        // proposal hosted, voting can now commence:

        // jump to just after scheduled voting start for proposal 1
        uint256 _start = raiseBoxVoting.votingStartTime(projectId, 1);
        raiseBoxVoting.delegateVote(projectId, 1, max, uche);
        vm.warp(_start + 1);

        vm.startPrank(mark);
        raiseBoxVoting.vote(projectId, 1, true);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, 1, false);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxVoting.vote(projectId, 1, true);
        vm.stopPrank();

        vm.startPrank(ebby);
        raiseBoxVoting.vote(projectId, 1, true);
        vm.stopPrank();

        vm.warp(_start + 10 days);
        console.log(address(raiseBoxProposalContract));
        // raiseBoxVoting.endVoting(projectId, 1);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended(voting duration exceeded by atleast 12 hours) and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        raiseBoxVoting.triggerVoteTally(projectId, 1);
        vm.stopPrank();

        (uint256 forVotes, uint256 againstVotes, uint256 aggregate) = raiseBoxVoting.getProposalVotes(projectId, 1);

        console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
        console.log("project owner balance:", ben.balance);

        // proposal 2
        raiseBoxCore.getAmtRaisedByProject(projectId);
        raiseBoxCore.getRaiseState(projectId);

        vm.startPrank(ben);

        advanceBlockTime(4 weeks);

        uint256 proposalId2 = raiseBoxProposalContract.hostProposal(
            "new website", "pay for new website", projectId, 25
        );

        numOfProposalsHosted++;

        vm.stopPrank();

        // jump to just after scheduled voting start for proposal 2
        uint256 _start2 = raiseBoxVoting.votingStartTime(projectId, proposalId2);
        vm.warp(_start2 + 1);

        vm.startPrank(mark);
        raiseBoxVoting.vote(projectId, proposalId2, false);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, proposalId2, true);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxVoting.vote(projectId, proposalId2, true);
        vm.stopPrank();

        vm.warp(_start2 + 10 days);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        raiseBoxVoting.triggerVoteTally(projectId, proposalId2);
        vm.stopPrank();

        console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
        console.log("project owner balance:", ben.balance);

        // proposal 3

        vm.startPrank(ben);

        advanceBlockTime(4 weeks);

        uint256 proposalId3 = raiseBoxProposalContract.hostProposal(
            "launch mvp", "beta test mvp", projectId, 20
        );

        numOfProposalsHosted++;

        vm.stopPrank();

        // jump to just after scheduled voting start for proposal 2
        uint256 _start3 = raiseBoxVoting.votingStartTime(projectId, proposalId3);
        vm.warp(_start3 + 1);

        vm.startPrank(mark);
        raiseBoxVoting.vote(projectId, proposalId3, false);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, proposalId3, true);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxVoting.vote(projectId, proposalId3, true);
        vm.stopPrank();

        vm.warp(_start3 + 10 days);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        raiseBoxVoting.triggerVoteTally(projectId, proposalId3);
        vm.stopPrank();

        console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
        console.log("project owner balance:", ben.balance);

        // proposal 4

        vm.startPrank(ben);

        advanceBlockTime(4 weeks);

        uint256 proposalId4 = raiseBoxProposalContract.hostProposal(
            "first testnet app",
            "testnet faucet and app v1 creation",
            projectId,
            20
        );

        numOfProposalsHosted++;

        vm.stopPrank();

        // jump to just after scheduled voting start for proposal 2
        uint256 _start4 = raiseBoxVoting.votingStartTime(projectId, proposalId4);
        vm.warp(_start4 + 1);

        vm.startPrank(mark);
        raiseBoxVoting.vote(projectId, proposalId4, false);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, proposalId4, true);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxVoting.vote(projectId, proposalId4, true);
        vm.stopPrank();

        vm.warp(_start4 + 10 days);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        raiseBoxVoting.triggerVoteTally(projectId, proposalId4);
        vm.stopPrank();

        console.log("drip handler balance:", address(raiseBoxDripHandler).balance);
        console.log("project owner balance:", ben.balance);

        // proposal 5

        vm.startPrank(ben);

        advanceBlockTime(5 weeks);

        uint256 proposalId5 = raiseBoxProposalContract.hostProposal(
            "v2 launch",
            "version 2 of testnet app is ready to be tested",
            projectId,
            20
        );

        numOfProposalsHosted++;

        vm.stopPrank();

        // jump to just after scheduled voting start for proposal 2
        uint256 _start5 = raiseBoxVoting.votingStartTime(projectId, proposalId5);
        
        vm.startPrank(max);
        raiseBoxVoting.delegateVote(
        projectId, proposalId5, max, ebby
        );

        vm.stopPrank();

        vm.warp(_start5 + 1);

        vm.startPrank(mark);
        raiseBoxVoting.vote(projectId, proposalId5, false);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, proposalId5, true);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxVoting.vote(projectId, proposalId5, true);
        vm.stopPrank();

        vm.startPrank(ebby);
        raiseBoxVoting.vote(projectId, proposalId5, true);
        vm.stopPrank();

        vm.warp(_start5 + 10 days);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        raiseBoxVoting.triggerVoteTally(projectId, proposalId5);
        vm.stopPrank();

        assert(raiseBoxProposalContract.getProposalCount(projectId) == numOfProposalsHosted);
        raiseBoxProposalContract.getTotalProposals();
        raiseBoxCore.getRaiseInfo(projectId);
        raiseBoxCore.getRaiseState(projectId);

        vm.startPrank(ben);

        advanceBlockTime(5 weeks);

        uint256 proposalId6 = raiseBoxProposalContract.hostProposal(
            "v2 launch",
            "version 2 of testnet app is ready to be tested",
            projectId,
            20
        );

        // numOfProposalsHosted++;

        vm.stopPrank();

        raiseBoxProposalContract.getTotalProposals();
        raiseBoxCore.getRaiseInfo(projectId);
        raiseBoxCore.getRaiseState(projectId);

        //  vm.startPrank(ben);

        // advanceBlockTime(500 weeks);
        // vm.expectRevert();

        // uint256 proposalId7 = raiseBoxProposalContract.hostProposal(
        //     "v2 launch",
        //     "version 2 of testnet app is ready to be tested",
        //     projectId,
        //     20
        // );

        // // numOfProposalsHosted++;

        // vm.stopPrank();

        raiseBoxProposalContract.getTotalProposals();
        // raiseBoxCore.incrementConFaildProposals(projectId);
        raiseBoxCore.getRaiseInfo(projectId);
        // raiseBoxCore.getRaiseState(projectId);
        // raiseBoxProposalContract.isValidProposal(0x0ef765bb5612bfab35f0518fdb194eb02394c410530030a57d2fecaabd944ef8, 1);
        // raiseBoxCore.doesRaiseExist(0x0ef765bb5612bfab35f0518fdb194eb02394c410530030a57d2fecaabd944ef8);
        // raiseBoxProposalContract.getProposalDetails(projectId, 6);
        // raiseBoxCore.getProposalState(0x0ef765bb5612bfab35f0518fdb194eb02394c410530030a57d2fecaabd944ef8, 6);
        // raiseBoxProposalContract.getLastProposalState(projectId, 8);

        
    }


    function testVotingAndDelegationOnProposalsWorks() public {
        console.log("drip handler intial balance:", address(raiseBoxDripHandler).balance);
        console.log("raise owner initial balance:", ben.balance);
        // create and contribute to raise till it passes
        bytes32 raiseId = contributeToTestProject();

        console.log("drip handler balance after raise passes:", address(raiseBoxDripHandler).balance);
        console.log("raise owner balance after raise passes:", ben.balance);

        // host first proposal ---> proposal1
        vm.prank(ben);
        uint256 proposalId = raiseBoxProposalContract.hostProposal(
            "MVP",
            "Finished building the minimum viable product for sentient agi and it's ready for testing",
            raiseId,
            20
        );

        // delegate votes to ethereum:
        raiseBoxVoting.delegateVote(raiseId, proposalId, arbitrum, ethereum);
        raiseBoxVoting.delegateVote(raiseId, proposalId, openseas, ethereum);
        raiseBoxVoting.delegateVote(raiseId, proposalId, gowagr, ethereum);
        raiseBoxVoting.delegateVote(raiseId, proposalId, elon, ethereum);
        raiseBoxVoting.delegateVote(raiseId, proposalId, magiceden, trump);
        raiseBoxVoting.delegateVote(raiseId, proposalId, polymarket, trump);
        // vm.startPrank(ethereum);
        // raiseBoxVoting.vote(raiseId, proposalId, true);

        advanceBlockTime(48 hours);
        
        // raiseBoxVoting.delegateVote(raiseId, proposalId, tether, trump);

        address[10] memory voters = [ebby, sally, uche, max, mark, alice, joe, testOwner, sam, vitalik];

        // delegators votes:
        vm.startPrank(ethereum);
        raiseBoxVoting.vote(raiseId, proposalId, true);
        vm.stopPrank();


        for (uint256 i = 0; i < voters.length; i++) {
            vm.startPrank(voters[i]);
            if (i % 2 == 0) {
                raiseBoxVoting.vote(raiseId, proposalId, true );

            } else {
                raiseBoxVoting.vote(raiseId, proposalId, false  );
            }
            
            vm.stopPrank();
        }

        vm.startPrank(tether);
        raiseBoxVoting.vote(raiseId, proposalId, false);
        vm.stopPrank();

        vm.startPrank(trump);
        raiseBoxVoting.vote(raiseId, proposalId, false);
        vm.stopPrank();

        raiseBoxVoting.getProposalVotes(raiseId, proposalId);


        advanceBlockTime(7 days);

        raiseBoxVoting.getProposalVotes(raiseId, proposalId);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        raiseBoxVoting.triggerVoteTally(raiseId, proposalId);
        vm.stopPrank();

        console.log("drip handler balance after first proposal passes:", address(raiseBoxDripHandler).balance);
        console.log("raise owner balance after first proposal passes:", ben.balance);

         
         
         
         // host second proposal ---> proposal2
         advanceBlockTime(4 weeks);
         raiseBoxCore.getRaiseState(raiseId);
        vm.prank(ben);
        uint256 proposalId1 = raiseBoxProposalContract.hostProposal(
            "built public API",
            "Public API for use by other devs seeking to integrate sentient has been completed and tested",
            raiseId,
            20
        );

        advanceBlockTime(48 hours);

        
        // delegators votes:
        vm.startPrank(ethereum);
        raiseBoxVoting.vote(raiseId, proposalId1, true);
        vm.stopPrank();

    for (uint256 i = 0; i < voters.length; i++) {
            vm.startPrank(voters[i]);
            if (i % 2 == 0) {
                raiseBoxVoting.vote(raiseId, proposalId1, true );

            } else {
                raiseBoxVoting.vote(raiseId, proposalId1, false  );
            }
            
            vm.stopPrank();
        }

        vm.startPrank(tether);
        raiseBoxVoting.vote(raiseId, proposalId1, true);
        vm.stopPrank();

        vm.startPrank(trump);
        raiseBoxVoting.vote(raiseId, proposalId1, false);
        vm.stopPrank();

        raiseBoxVoting.getProposalVotes(raiseId, proposalId1);


        advanceBlockTime(7 days);

        raiseBoxVoting.getProposalVotes(raiseId, proposalId1);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        // vm.expectRevert();
        raiseBoxVoting.triggerVoteTally(raiseId, proposalId1);
        vm.stopPrank();

        console.log("drip handler balance after second proposal passes:", address(raiseBoxDripHandler).balance);
        console.log("raise owner balance after second proposal passes:", ben.balance);



        // host third proposal ---> proposal3
         advanceBlockTime(4 weeks);
         raiseBoxCore.getRaiseState(raiseId);
        vm.prank(ben);
        uint256 proposalId2 = raiseBoxProposalContract.hostProposal(
            "finished tesntet launch",
            "public testnet is live and ready for testers to test how sentient agi works for real",
            raiseId,
            20
        );

        // delegate votes to ethereum:
        address[4] memory delegators = [arbitrum, openseas, gowagr, elon];

        for (uint256 i = 0; i < delegators.length; i++) {
            if (i == delegators.length - 1) {
            vm.startPrank(delegators[i]);
            raiseBoxVoting.delegateVote(raiseId, proposalId2, delegators[i], ethereum);
            vm.stopPrank();
            } else {
            vm.startPrank(delegators[i]);
            raiseBoxVoting.delegateVote(raiseId, proposalId2, delegators[i], tether);
            vm.stopPrank();
            }
        }
        // raiseBoxVoting.delegateVote(raiseId, proposalId2, arbitrum, tether);
        // raiseBoxVoting.delegateVote(raiseId, proposalId2, openseas, tether);
        // raiseBoxVoting.delegateVote(raiseId, proposalId2, gowagr, tether);
        // raiseBoxVoting.delegateVote(raiseId, proposalId2, elon, ethereum);

        advanceBlockTime(48 hours);

        
        // delegators votes:
        vm.startPrank(ethereum);
        raiseBoxVoting.vote(raiseId, proposalId2, false);
        vm.stopPrank();
        

    for (uint256 i = 0; i < voters.length; i++) {
            vm.startPrank(voters[i]);
            if (i % 2 == 0) {
                raiseBoxVoting.vote(raiseId, proposalId2, true );

            } else {
                raiseBoxVoting.vote(raiseId, proposalId2, false  );
            }
            
            vm.stopPrank();
        }

        vm.startPrank(tether);
        raiseBoxVoting.vote(raiseId, proposalId2, false);
        vm.stopPrank();

        vm.startPrank(trump);
        raiseBoxVoting.vote(raiseId, proposalId2, false);
        vm.stopPrank();

        raiseBoxVoting.getProposalVotes(raiseId, proposalId2);


        advanceBlockTime(7 days);

        raiseBoxVoting.getProposalVotes(raiseId, proposalId2);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        // vm.expectRevert();
        raiseBoxVoting.triggerVoteTally(raiseId, proposalId2);
        vm.stopPrank();

        console.log("drip handler balance after third proposal passes:", address(raiseBoxDripHandler).balance);
        console.log("raise owner balance after third proposal passes:", ben.balance);

        raiseBoxCore.isRaiseCreator(ben, raiseId);
        raiseBoxCore.getAmtRaisedByProject(raiseId); // 13,200 -- 1,027
        raiseBoxCore.getAmountToRaise(raiseId); // 13, 500 -- 1,300
        raiseBoxCore.getRaiseInfo(raiseId);
        uint256 proposalCount = 3;

        for (uint256 i = 0; i < 12; i++ ) {
        advanceBlockTime(4 weeks);
        vm.startPrank(ben);
        uint256 proposalId2 = raiseBoxProposalContract.hostProposal(
            "finished tesntet launch",
            "public testnet is live and ready for testers to test how sentient agi works for real",
            raiseId,
            20
        );
        proposalCount++;
        vm.stopPrank();


        // delegate votes to ethereum:
        address[4] memory delegators = [arbitrum, openseas, gowagr, elon];

        for (uint256 i = 0; i < delegators.length; i++) {
            if (i == delegators.length - 1) {
            vm.startPrank(delegators[i]);
            raiseBoxVoting.delegateVote(raiseId, proposalId2, delegators[i], ethereum);
            vm.stopPrank();
            } else {
            vm.startPrank(delegators[i]);
            raiseBoxVoting.delegateVote(raiseId, proposalId2, delegators[i], tether);
            vm.stopPrank();
            }
        }
        // raiseBoxVoting.delegateVote(raiseId, proposalId2, arbitrum, tether);
        // raiseBoxVoting.delegateVote(raiseId, proposalId2, openseas, tether);
        // raiseBoxVoting.delegateVote(raiseId, proposalId2, gowagr, tether);
        // raiseBoxVoting.delegateVote(raiseId, proposalId2, elon, ethereum);

        advanceBlockTime(48 hours);

        
        // delegators votes:
        vm.startPrank(ethereum);
        raiseBoxVoting.vote(raiseId, proposalId2, false);
        vm.stopPrank();
        

    for (uint256 i = 0; i < voters.length; i++) {
            vm.startPrank(voters[i]);
            if (i % 2 == 0) {
                raiseBoxVoting.vote(raiseId, proposalId2, true );

            } else {
                raiseBoxVoting.vote(raiseId, proposalId2, false  );
            }
            
            vm.stopPrank();
        }

        vm.startPrank(tether);
        raiseBoxVoting.vote(raiseId, proposalId2, false);
        vm.stopPrank();

        vm.startPrank(trump);
        raiseBoxVoting.vote(raiseId, proposalId2, false);
        vm.stopPrank();

        raiseBoxVoting.getProposalVotes(raiseId, proposalId2);


        advanceBlockTime(7 days);

        raiseBoxVoting.getProposalVotes(raiseId, proposalId2);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        // vm.expectRevert();
        raiseBoxVoting.triggerVoteTally(raiseId, proposalId2);
        vm.stopPrank();

        console.log("drip handler balance after", proposalCount, "proposal passes:", address(raiseBoxDripHandler).balance);
        console.log("raise owner balance after", proposalCount, "proposal passes:", ben.balance);
        raiseBoxVoting.getFailedProposalsCount(raiseId);
        


        }





    }
}
