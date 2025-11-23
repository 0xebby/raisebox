// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import {TestsHelpers} from "./TestsHelpers.sol";

contract RaiseBoxProjectCreationTest is Test, TestsHelpers {
    

    function testCreateProject() public {
        vm.startPrank(alice);
        bytes32 projectID1 = raiseBoxProjectCreationContract.createProject(
            "project 1", "solve testnet sybil with zkp", 10 ether, 30 days
        );
        vm.stopPrank();

        (
            string memory projectName,
            address projectCreator,
            string memory projectValuePropDesciption,
            uint256 amountToRaise,
            uint256 durationOfRaise,
            bytes32 projectId,
            bool projectExist,
            uint256 timeCreated,
            uint256 amountRaised,
            uint256 proposalsHosted
        ) = raiseBoxStorage.getProjectInfo(projectID1);

        assertEq(projectName, "project 1");
        assertEq(projectValuePropDesciption, "solve testnet sybil with zkp");
        assertEq(projectCreator, alice);
        assertEq(amountToRaise, 10 ether);
        assertEq(durationOfRaise, 30 days);
        assertEq(projectId, projectID1);
        assertEq(amountRaised, 0);
        assertEq(timeCreated, block.timestamp);
        assertEq(proposalsHosted, 0);

        vm.startPrank(ben);
        bytes32 projectID2 = raiseBoxProjectCreationContract.createProject(
            "sentient", "AGI: AI but collectively owned and decentralized", 30 ether, 30 days
        );
        vm.stopPrank();

        vm.startPrank(joe);
        bytes32 projectID3 = raiseBoxProjectCreationContract.createProject(
            "FeedTheWorld NGO", "operation feed 2,000 kids", 100 ether, 30 days
        );
        vm.stopPrank();

        vm.startPrank(ben);

        raiseBoxContributionContract.contribute{value: 6 ether}(6 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);



        raiseBoxContributionContract.getContributionsToProject(ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
        raiseBoxContributionContract.getTotalContributionsToProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

        vm.stopPrank();

        vm.startPrank(joe);

        raiseBoxContributionContract.contribute{value: 6 ether}(6 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);



        raiseBoxContributionContract.getContributionsToProject(ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
        raiseBoxContributionContract.getTotalContributionsToProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

        vm.stopPrank();

        vm.startPrank(alice);

        raiseBoxContributionContract.contribute{value: 6 ether}(6 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);



        raiseBoxContributionContract.getContributionsToProject(ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
        raiseBoxContributionContract.getTotalContributionsToProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

        vm.stopPrank();

        vm.startPrank(owner);

        raiseBoxContributionContract.contribute{value: 6 ether}(6 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);



        raiseBoxContributionContract.getContributionsToProject(ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
        raiseBoxContributionContract.getTotalContributionsToProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

        vm.stopPrank();

        vm.startPrank(address(0x1));
        vm.deal(address(0x1), 50 ether);

        raiseBoxContributionContract.contribute{value: 5 ether}(5 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);



        raiseBoxContributionContract.getContributionsToProject(ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
        raiseBoxContributionContract.getTotalContributionsToProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

        vm.stopPrank();

        raiseBoxStorage.getAmountRaisedByProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

        vm.startPrank(address(0x11));
        vm.deal(address(0x11), 50 ether);

        raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);



        raiseBoxContributionContract.getContributionsToProject(ben, 0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
        raiseBoxContributionContract.getTotalContributionsToProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

        vm.stopPrank();


        // advanceBlockTime(104 weeks); // 2 years
        // vm.startPrank(joe);
        // bytes32 projectID4 =
        //     raiseBoxProjectCreationContract.createProject("NGO", "missionary journey to Rome", 50 ether, 30 days);
        // vm.stopPrank();

        raiseBoxStorage.getProjectCount();
        raiseBoxStorage.getProject(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);

        // raiseBoxContributionContract.getContributors(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
        // raiseBoxContributionContract.getContributorsCount(0xae13d606d445835ab7365f6ea8fdd3208ece4b8c27adb5a3d65a2ebdbe39120b);
        // raiseBoxContributionContract.getContributorsCount(0x17e319276da7a011fd833f23f0a7e1e61f6b68d4e50953d6b818b13ac05524e4);
        // raiseBoxContributionContract.getContributorsCount(0x1fb69664d8a26cd9173477051b28805064fd6be187121907b1894822c61b27ea);
        // // raiseBoxContributionContract.getContributorsCount(0x1fb69664d8a26cd9173477051b28805064fd6be187121907b1894822c61b27ae);
    }

    function testMultipleProjectCreation() public {
        createTestProjects();

        
    }

    function testContributeToProjects() public {
        createTestProjects();
        contributeToTestProject(0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85, max, 2 ether);

        contributeToTestProject(0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85, ben, 2 ether);

        contributeToTestProject(0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85, alice, 2 ether);

        contributeToTestProject(0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85, uche, 2 ether);

        contributeToTestProject(0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85, sam, 2 ether);

        vm.startPrank(joe);
        raiseBoxProposalContract.hostProposal("built mvp", "receive 2 ether to complete next milestone: tetsnet website", 0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85);
        vm.stopPrank();

        raiseBoxProposalContract.getLastProposalTime(0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85);

        // advanceBlockTime(35 days);
        // console.log(block.timestamp);

        // vm.startPrank(joe);
        // raiseBoxProposalContract.hostProposal("testnet website built and live", "receive 1 eth for KOL onboarding", 0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85);
        // vm.stopPrank();

        // vm.startPrank(joe);
        // raiseBoxProposalContract.hostProposal("testnet website built and live", "receive 1 eth for KOL onboarding", 0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85);
        // vm.stopPrank();

        //  vm.startPrank(joe);
        // raiseBoxProposalContract.hostProposal("testnet website built and live", "receive 1 eth for KOL onboarding", 0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85);
        // vm.stopPrank();

        // contributeToTestProject(0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85, owner, 2 ether);



        // address protocol = raiseBoxStorage.getProtocol();

        // console.log(address(protocol).balance);

        // raiseBoxStorage.getProject(0xea5e8de8d9a6511bbc46b319034911d0e0fab1e886dff5aac86bf6c028e63a85);
    }

    

    

    

    
}
