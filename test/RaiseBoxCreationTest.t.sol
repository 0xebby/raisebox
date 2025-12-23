// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import {TestsHelpers} from "./TestsHelpers.sol";
import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";

contract RaiseBoxCreationTest is Test, TestsHelpers {
    // function testCreateProject() public {
    //     vm.startPrank(alice);
    //     bytes32 projectID1 =
    //         raiseBoxRaiseCreationContract.createRaise("project 1", "solve testnet sybil with zkp", 10 ether, 60 weeks);
    //     vm.stopPrank();

    //     (
    //         string memory projectName,
    //         address projectCreator,
    //         string memory projectValuePropDesciption,
    //         uint256 raiseTarget,
    //         uint256 durationOfRaise,
    //         bytes32 raiseId,
    //         bool projectExist,
    //         uint256 timeCreated,
    //         uint256 amountRaised,
    //         uint256 proposalsHosted,
    //         uint256 NumOfProjectCreated
    //     ) = raiseBoxCore.getRaiseInfo(projectID1);

    //     assertEq(projectName, "project 1");
    //     assertEq(projectValuePropDesciption, "solve testnet sybil with zkp");
    //     assertEq(projectCreator, alice);
    //     assertEq(raiseTarget, 10 ether);
    //     assertEq(durationOfRaise, 60 weeks);
    //     assertEq(raiseId, projectID1);
    //     assertEq(amountRaised, 0);
    //     assertEq(timeCreated, block.timestamp);
    //     assertEq(proposalsHosted, 0);

    //     vm.startPrank(ben);
    //     bytes32 projectID2 = raiseBoxRaiseCreationContract.createRaise(
    //         "sentient", "AGI: AI but collectively owned and decentralized", 30 ether, 55 weeks
    //     );
    //     vm.stopPrank();

    //     vm.startPrank(joe);
    //     bytes32 projectID3 = raiseBoxRaiseCreationContract.createRaise(
    //         "FeedTheWorld NGO", "operation feed 2,000 kids", 100 ether, 55 weeks
    //     );
    //     vm.stopPrank();

    //     vm.startPrank(sally);

    //     raiseBoxContributionContract.contribute{value: 6 ether}(
    //         6 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     raiseBoxContributionContract.getContributionsToProject(
    //         ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );
    //     raiseBoxContributionContract.getTotalContributionsToProject(
    //         0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     vm.stopPrank();

    //     vm.startPrank(joe);

    //     raiseBoxContributionContract.contribute{value: 6 ether}(
    //         6 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     raiseBoxContributionContract.getContributionsToProject(
    //         ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );
    //     raiseBoxContributionContract.getTotalContributionsToProject(
    //         0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     vm.stopPrank();

    //     vm.startPrank(alice);

    //     raiseBoxContributionContract.contribute{value: 6 ether}(
    //         6 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     raiseBoxContributionContract.getContributionsToProject(
    //         ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );
    //     raiseBoxContributionContract.getTotalContributionsToProject(
    //         0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     vm.stopPrank();

    //     vm.startPrank(testOwner);

    //     raiseBoxContributionContract.contribute{value: 6 ether}(
    //         6 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     raiseBoxContributionContract.getContributionsToProject(
    //         ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );
    //     raiseBoxContributionContract.getTotalContributionsToProject(
    //         0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     vm.stopPrank();

    //     vm.startPrank(address(0x1));
    //     vm.deal(address(0x1), 50 ether);

    //     raiseBoxContributionContract.contribute{value: 5 ether}(
    //         5 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     raiseBoxContributionContract.getContributionsToProject(
    //         ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );
    //     raiseBoxContributionContract.getTotalContributionsToProject(
    //         0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     vm.stopPrank();

    //     raiseBoxCore.getAmtRaisedByProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

    //     vm.startPrank(address(0x11));
    //     vm.deal(address(0x11), 50 ether);

    //     raiseBoxContributionContract.contribute{value: 1 ether}(
    //         1 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     raiseBoxContributionContract.getContributionsToProject(
    //         ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );
    //     raiseBoxContributionContract.getTotalContributionsToProject(
    //         0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b
    //     );

    //     vm.stopPrank();

    //     // advanceBlockTime(104 weeks); // 2 years
    //     // vm.startPrank(joe);
    //     // bytes32 projectID4 =
    //     //     raiseBoxRaiseCreationContract.createRaise("NGO", "missionary journey to Rome", 50 ether, 30 days);
    //     // vm.stopPrank();

    //     raiseBoxCore.getRaiseCount();
    //     raiseBoxCore.getProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

    //     // raiseBoxContributionContract.getContributors(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
    //     // raiseBoxContributionContract.getContributorsCount(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
    //     // raiseBoxContributionContract.getContributorsCount(0x17e319276da7a011fd833f23f0a7e1e61f6b68d4e50953d6b818b13ac05524e4);
    //     // raiseBoxContributionContract.getContributorsCount(0x1fb69664d8a26cd9173477051b28805064fd6be187121907b1894822c61b27ea);
    //     // // raiseBoxContributionContract.getContributorsCount(0x1fb69664d8a26cd9173477051b28805064fd6be187121907b1894822c61b27ae);
    // }

   function testCreateARaise() public {

    // whitelist raise creator first
    raiseBoxCore.verifyAndAddToWhitelist(uche);
    raiseBoxCore.verifyAndAddToWhitelist(ebby);

    vm.startPrank(uche);
   bytes32 projectId = raiseBoxRaiseCreationContract.createNewRaise(
        IRaiseBoxCore.ProjectInfo({
            projectOwner:uche,
            projectName:"sentient",
            valueProposition:"agi",
            raiseTarget:20 ether,
            projectDuration:52 weeks
        })
    );
    vm.stopPrank();

    raiseBoxCore.getRaiseInfo(projectId);

    raiseBoxCore.getRaiseState(projectId);

    address[5] memory contributors = [ebby, sally, ben, max, mark];

    for (uint256 i = 0; i < contributors.length; i++) {
            vm.startPrank(contributors[i]);
            raiseBoxContributionContract.contribute{value: 4 ether}(4 ether, projectId);
            vm.stopPrank();
        }

    
     vm.startPrank(uche);

        uint256 proposalId1 = raiseBoxProposalContract.hostProposal(
            "new hires", "hiring of devs for project, 2 smart contract devs and 1 rust dev", projectId, 10
        );

    vm.stopPrank();
    raiseBoxCore.getRaiseInfo(projectId);
    raiseBoxCore.getRaiseState(projectId);

    // advanceBlockTime(4 weeks);

    //  vm.startPrank(uche);

    //     uint256 proposalId2 = raiseBoxProposalContract.hostProposal(
    //         "second proposal", "hiring of devs for project, 2 smart contract devs and 1 rust dev", projectId, 10
    //     );

    // vm.stopPrank();
    // raiseBoxCore.getRaiseInfo(projectId);
    // raiseBoxCore.getRaiseState(projectId);

   // jump to just after scheduled voting start for proposal 1
        uint256 _start = raiseBoxVoting.votingStartTime(projectId, 1);
        vm.warp(_start + 1);

        vm.startPrank(mark);
        raiseBoxVoting.vote(projectId, 1, true, mark);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, 1, false, sally);
        vm.stopPrank();

        vm.startPrank(max);
        raiseBoxVoting.delegateVote(projectId, 1, max, ben);
        raiseBoxVoting.vote(projectId, 1, true, ben);
        vm.stopPrank();

        vm.startPrank(ebby);
        raiseBoxVoting.vote(projectId, 1, true, ebby);
        vm.stopPrank();

        vm.warp(_start + 10 days);
        console.log(address(raiseBoxProposalContract));
        // raiseBoxVoting.endVoting(projectId, 1);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended(voting duration exceeded by atleast 12 hours) and the caller is in-fact the proposal owner
        vm.startPrank(uche);
        raiseBoxVoting.triggerVoteTally(projectId, 1);
        vm.stopPrank();

        raiseBoxCore.getRaiseState(projectId);
        raiseBoxCore.getRaiseInfo(projectId);

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
        vm.warp(_start + 1);

        vm.startPrank(mark);
        raiseBoxVoting.vote(projectId, 1, true, mark);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, 1, false, sally);
        vm.stopPrank();

        vm.startPrank(max);
        raiseBoxVoting.delegateVote(projectId, 1, max, uche);
        raiseBoxVoting.vote(projectId, 1, true, uche);
        vm.stopPrank();

        vm.startPrank(ebby);
        raiseBoxVoting.vote(projectId, 1, true, ebby);
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
        raiseBoxVoting.vote(projectId, proposalId2, false, mark);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, proposalId2, true, sally);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxVoting.vote(projectId, proposalId2, true, uche);
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
        raiseBoxVoting.vote(projectId, proposalId3, false, mark);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, proposalId3, true, sally);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxVoting.vote(projectId, proposalId3, true, uche);
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
        raiseBoxVoting.vote(projectId, proposalId4, false, mark);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, proposalId4, true, sally);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxVoting.vote(projectId, proposalId4, true, uche);
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
        vm.warp(_start5 + 1);

        vm.startPrank(mark);
        raiseBoxVoting.vote(projectId, proposalId5, false, mark);
        vm.stopPrank();

        vm.startPrank(sally);
        raiseBoxVoting.vote(projectId, proposalId5, true, sally);
        vm.stopPrank();

        vm.startPrank(uche);
        raiseBoxVoting.vote(projectId, proposalId5, true, uche);
        vm.stopPrank();

        vm.startPrank(max);
        raiseBoxVoting.delegateVote(
        projectId, proposalId5, max, ebby
        );
        vm.stopPrank();

        vm.startPrank(ebby);
        raiseBoxVoting.vote(projectId, proposalId5, true, ebby);
        vm.stopPrank();

        vm.warp(_start5 + 10 days);

        // special trigger by project owner if user voting doesn't lead to vote tallying, can only happen if voting has ended and the caller is in-fact the proposal owner
        vm.startPrank(ben);
        raiseBoxVoting.triggerVoteTally(projectId, proposalId5);
        vm.stopPrank();

        assert(raiseBoxProposalContract.getProposalCount(projectId) == numOfProposalsHosted);
        raiseBoxProposalContract.getTotalProposals();
    }
}
