// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import {RaiseBox} from "../src/RaiseBoxProjectCreation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RaiseBoxContribution} from "../src/RaiseBoxContribution.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {RaiseBoxProposal} from "../src/RaiseBoxProposal.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";

contract TestRaiseBox is Test {
    // main contract that holds general storage
    RaiseBoxCore raiseBoxStorage;

    // project creation contract
    RaiseBox raiseBoxProjectCreationContract;

    // contribution contract
    RaiseBoxContribution raiseBoxContributionContract;

    // proposal contract
    RaiseBoxProposal raiseBoxProposalContract;

    // faucet contract address
    address faucetToken = 0xB15D5A9DCcCCcb3Caf55360D89610834A72Cf6b3;

    // raisebox owner == deployer
    address owner;

    // mkae dummy addresses for test
    address alice = makeAddr("alice");
    address joe = makeAddr("joe");
    address ben = makeAddr("ben");

    // get  would be ca of raisebox - project creation contract

    using Strings for uint256;

    function setUp() public {
        // deploy the main contract that holds general storage
        raiseBoxStorage = new RaiseBoxCore();

        // deploy project creation contract with CA of main contract above
        raiseBoxProjectCreationContract = new RaiseBox(address(raiseBoxStorage));

        // set the address of the project creation contract so it can be referenced
        raiseBoxStorage.setProjectCreationContractAddress(address(raiseBoxProjectCreationContract));

        raiseBoxContributionContract = new RaiseBoxContribution(address(raiseBoxStorage));

        raiseBoxStorage.setContributionContractAddress(address(raiseBoxContributionContract));
        // raiseBoxProposalContract = new RaiseBoxProposal(
        //     address(raiseBoxStorage),
        //     address(raiseBoxProjectCreationContract)
        // );
        owner = address(this);
        vm.deal(owner, 50 ether);
        vm.deal(alice, 100 ether);
        vm.deal(joe, 100 ether);
        vm.deal(ben, 100 ether);

        // advanceBlockTime(78 weeks);
    }

    /**
     * @dev Helper function to simulate time passing since testing environment doesn't work as expected
     * @param duration_ amount of time to advanced, could be in days, hours, minutes or seconds. default is seconds*
     */
    function advanceBlockTime(uint256 duration_) internal {
        vm.warp(block.timestamp + duration_);
    }

    function test_address() public {
        vm.prank(alice);
        bytes32 projectId1 = raiseBoxProjectCreationContract.createProject(
            "starknet", "zero knowledge proof trades, trading should be aprivate affair", 300 ether, 35 days
        );

        vm.prank(owner);
        bytes32 ownerProjectId = raiseBoxProjectCreationContract.createProject(
            "memeland", "building the largest decentralized meme platform", 5000 ether, 50 days
        );

        assertEq(raiseBoxStorage.doesProjectExist(ownerProjectId), true);

        // advanceBlockTime(block.timestamp + 78 weeks);

        // bytes32 projectID = keccak256(
        //     abi.encode(
        //         "fake project",
        //         5000 ether,
        //         block.timestamp,
        //         "fake value",
        //         alice
        //     )
        // );

        address projectCreationCA = address(raiseBoxProjectCreationContract);

        // raiseBoxStorage.updateIDsStorage(projectID);

        // vm.prank(alice);

        // raiseBoxStorage.updateStorage(
        //     projectID,
        //     "fake project",
        //     address(0x1),
        //     "fake value proposition",
        //     5000 ether,
        //     10 days,
        //     true,
        //     block.timestamp,
        //     0,
        //     0,
        //     1
        // );

        // vm.prank(ben);
        // bytes32 projectId11 = raiseBoxProjectCreationContract.createProject(
        //     "zerion",
        //     "decentralized crypto wallet with perps integration",
        //     5000 ether,
        //     30 days
        // );

        // vm.prank(ben);
        // bytes32 projectId12 = raiseBoxProjectCreationContract.createProject(
        //     "trustwallet",
        //     "decentralized crypto wallet with perps integration",
        //     3000 ether,
        //     30 days
        // );

        // vm.prank(alice);
        // bytes32 projectId3 = raiseBoxProjectCreationContract.createProject(
        //     "starknet3",
        //     "zero knowledge proof trades, trading should be aprivate affair",
        //     3000 ether,
        //     35 days
        // );

        // vm.prank(alice);
        // bytes32 projectId4 = raiseBoxProjectCreationContract.createProject(
        //     "starknet4",
        //     "zero knowledge proof trades, trading should be aprivate affair",
        //     3000 ether,
        //     35 days
        // );

        // advanceBlockTime(block.timestamp + 18 weeks + 18 weeks);
        // vm.prank(alice);
        // bytes32 projectId3 = raiseBoxProjectCreationContract.createProject(
        //     "starknet3",
        //     "zero knowledge proof trades, trading should be aprivate affair",
        //     3000 ether,
        //     35 days
        // );

        // raiseBoxStorage.getProjectInfo(projectId1);

        // vm.prank(alice);
        // raiseBoxContributionContract.contribute{value: 50 ether}(
        //     50 ether,
        //     projectId1
        // );

        // raiseBoxStorage.getProjectInfo(projectID);
    }

    function testContributeUpdatesStatesCorrectly() public {
        vm.startPrank(alice);
        bytes32 projectID1 = raiseBoxProjectCreationContract.createProject(
            "project 1", "solve testnet sybil with zkp", 10 ether, 30 days
        );
        vm.stopPrank();

        raiseBoxStorage.doesProjectExist(projectID1);

        raiseBoxContributionContract.getMaxContributionAllowedForProject(projectID1);

        raiseBoxStorage.getAmountToRaise(projectID1);

        vm.startPrank(owner);
        bytes32 projectID2 = raiseBoxProjectCreationContract.createProject(
            "project 2", "solve high gas fees in ethereum using transaction bundling", 500 ether, 30 days
        );
        vm.stopPrank();

        raiseBoxStorage.getAmountToRaise(projectID2);

        raiseBoxContributionContract.getMaxContributionAllowedForProject(projectID2);

        // contribution

        vm.prank(joe);
        raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, projectID1);

        vm.prank(ben);
        raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, projectID1);

        vm.prank(owner);
        raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, projectID1);

        vm.prank(alice);
        raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, projectID1);

        vm.startPrank(address(0x50));
        vm.deal(address(0x50), 100 ether);
        raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, projectID1);
        vm.stopPrank();

        vm.startPrank(address(0x30));
        vm.deal(address(0x30), 100 ether);
        raiseBoxContributionContract.contribute{value: 0.5 ether}(0.5 ether, projectID1);
        vm.stopPrank();

        vm.startPrank(address(0x30));
        vm.deal(address(0x30), 100 ether);
        raiseBoxContributionContract.contribute{value: 0.5 ether}(0.5 ether, projectID1);
        vm.stopPrank();

        vm.startPrank(address(0x30));
        vm.deal(address(0x30), 100 ether);
        raiseBoxContributionContract.contribute{value: 0.5 ether}(0.5 ether, projectID2);
        vm.stopPrank();

        address prot = raiseBoxStorage.getProtocol();
        console.log(prot.balance);
        raiseBoxContributionContract.getTotalContributionsToProject(projectID1);
        raiseBoxStorage.getProject(projectID1);

        raiseBoxContributionContract.getContributors(projectID1);

        raiseBoxContributionContract.getContributionsToProject(address(0x30), projectID1);

        bytes32 projectID3 = keccak256(abi.encode("fake project", 5000 ether, block.timestamp, "fake value", alice));

        // vm.prank(joe);
        // raiseBoxContributionContract.contribute{value: 5 ether}(
        //     5 ether,
        //     projectID3
        // );

        raiseBoxStorage.getProject(projectID2);

        raiseBoxContributionContract.getTotalContributionsToProject(projectID2);

        raiseBoxContributionContract.getContributionsToProject(joe, projectID1);

        // vm.prank(ben);
        // raiseBoxContributionContract.contribute{value: 7 ether}(
        //     7 ether,
        //     projectID2
        // );

        // console.log(raiseBoxStorage.getAmountRaisedByProject(projectID1));
        // console.log(raiseBoxStorage.getAmountRaisedByProject(projectID2));

        // uint256 totalAmountContributedByJoeToProject1 = raiseBoxContributionContract
        //         .getContributions(joe, projectID1);
        // assertEq(
        //     totalAmountContributedByJoeToProject1,
        //     2 ether,
        //     "Joe's contributions to project 1: 2 ether"
        // );

        // uint256 totalAmountContributedByJoeToProject2 = raiseBoxContributionContract
        //         .getContributions(joe, projectID2);
        // assertEq(
        //     totalAmountContributedByJoeToProject2,
        //     5 ether,
        //     "Joe's contributions to project 2: 5 ether"
        // );

        // uint256 totalAmountRaisedByProject1 = raiseBoxProjectCreationContract
        //     .getAmountRaisedByProject(projectID1);

        // assertEq(
        //     totalAmountRaisedByProject1,
        //     4 ether,
        //     "Joe and Ben Contributed total of 4 ethers"
        // );

        // // ben contribution checks

        // uint256 totalAmountContributedByBenToProject1 = raiseBoxContributionContract
        //         .getContributions(ben, projectID1);
        // assertEq(
        //     totalAmountContributedByBenToProject1,
        //     2 ether,
        //     "Ben's contributions to project 1: 2 ether"
        // );

        // uint256 totalAmountContributedByBenToProject2 = raiseBoxContributionContract
        //         .getContributions(ben, projectID2);
        // assertEq(
        //     totalAmountContributedByBenToProject2,
        //     7 ether,
        //     "Ben's contributions to project 2: 7 ether"
        // );

        // uint256 totalAmountRaisedByProject2 = raiseBoxProjectCreationContract
        //     .getAmountRaisedByProject(projectID2);

        // assertEq(
        //     totalAmountRaisedByProject2,
        //     12 ether,
        //     "Joe and Ben Contributed total of 12 ethers toproject 2"
        // );
        // uint256 protocolBal = raiseBoxProjectCreationContract.getProtocol().balance;

        // assertEq(
        //     protocolBal,
        //     16 ether,
        //     "project1: 4 ether + project2: 12 ether"
        // );

        // vm.prank(alice);
        // raiseBoxContributionContract.contribute{value: 7 ether}(
        //     7 ether,
        //     projectID1
        // );

        // alice contributed again to project 2
        // vm.prank(alice);
        // raiseBoxContributionContract.contribute{value: 48 ether}(
        //     48 ether,
        //     projectID2
        // );

        // vm.prank(alice);
        // raiseBoxContributionContract.contribute{value: 2 ether}(
        //     2 ether,
        //     projectID2
        // );

        // uint256 protocolFeesFromProject2 = raiseBoxProjectCreationContract.getFeesFromProject(
        //     projectID2
        // );
        // console.log(protocolFeesFromProject2);

        // vm.prank(alice);
        // raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, 2);

        // vm.prank(alice);
        // raiseBoxContributionContract.contribute{value: 1 ether}(
        //     1 ether,
        //     projectID1
        // );

        // vm.prank(alice);
        // raiseBoxContributionContract.contribute{value: 11 ether}(11 ether, 1);

        // vm.prank(alice);
        // raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, 1);
    }

    // function testHostProposal() public {
    //     vm.startPrank(alice);
    //     bytes32 projectID1 = raiseBoxProjectCreationContract.createProject(
    //         "project 1",
    //         "solve testnet sybil with zkp",
    //         10 ether,
    //         30 days
    //     );
    //     vm.stopPrank();

    //     vm.startPrank(ben);
    //     raiseBoxContributionContract.contribute{value: 2 ether}(
    //         2 ether,
    //         projectID1
    //     );
    //     vm.stopPrank();

    //     vm.prank(joe);
    //     raiseBoxContributionContract.contribute{value: 2 ether}(
    //         2 ether,
    //         projectID1
    //     );

    //     vm.prank(address(0x10));
    //     vm.deal(address(0x10), 100 ether);
    //     raiseBoxContributionContract.contribute{value: 2 ether}(
    //         2 ether,
    //         projectID1
    //     );

    //     vm.prank(address(0x11));
    //     vm.deal(address(0x11), 100 ether);
    //     raiseBoxContributionContract.contribute{value: 2 ether}(
    //         2 ether,
    //         projectID1
    //     );

    //     vm.prank(address(0x12));
    //     vm.deal(address(0x12), 100 ether);
    //     raiseBoxContributionContract.contribute{value: 2 ether}(
    //         2 ether,
    //         projectID1
    //     );

    //     vm.prank(alice);
    //     raiseBoxProposalContract.hostProposal(
    //         "mvp ready and hosted",
    //         "modelled and built minimum viable product",
    //         projectID1
    //     );

    //     advanceBlockTime(70 days);
    //     vm.prank(alice);
    //     raiseBoxProposalContract.hostProposal(
    //         "docs website ready",
    //         "built docs website to help users and dev understand product",
    //         projectID1
    //     );

    //     advanceBlockTime(100 days);
    //     vm.prank(alice);
    //     raiseBoxProposalContract.hostProposal(
    //         "testnet is live and ready for testing in beta",
    //         "beta product built and ready for testing",
    //         projectID1
    //     );
    // }

    // function logProject(RaiseBoxCore.ProjectInfo memory p) internal view {
    //     console.log(
    //         string(
    //             abi.encodePacked(
    //                 "Name: ",
    //                 p.projectName,
    //                 " | Owner: ",
    //                 Strings.toHexString(uint160(p.projectOwner), 20),
    //                 " | Problem: ",
    //                 p.valueProposition,
    //                 " | Amount To Raise: ",
    //                 p.amountToRaise.toString(),
    //                 " | Duration: ",
    //                 p.duration.toString(),
    //                 " | ID: ",
    //                 p.projectID,
    //                 " | Amount Raised: ",
    //                 p.amountRaisedByProject.toString()
    //             )
    //         )
    //     );
    // }

    // function testAnyoneCanUpdateStorage() public {
    //     vm.startPrank(alice);
    //     bytes32 projectID1 = raiseBoxProjectCreationContract.createProject(
    //         "project 1",
    //         "solve testnet sybil with zkp",
    //         100 ether,
    //         30 days
    //     );
    //     vm.stopPrank();

    //     raiseBoxStorage.getProjectCreator(projectID1);

    //     vm.prank(ben);
    //     raiseBoxContributionContract.contribute{value: 2 ether}(
    //         2 ether,
    //         projectID1
    //     );

    //     // vm.startPrank(owner);
    //     // bytes32 projectID2 = raiseBoxProjectCreationContract.createProject(
    //     //     "project 2",
    //     //     "solve high gas fees in ethereum using transaction bundling",
    //     //     500 ether,
    //     //     30 days
    //     // );
    //     // vm.stopPrank();

    //     // raiseBoxStorage.updateStorage(
    //     //     projectID2,
    //     //     "project 1",
    //     //     alice,
    //     //     "solve testnet sybil with zkp",
    //     //     100 ether,
    //     //     30 days,
    //     //     true,
    //     //     block.timestamp,
    //     //     0,
    //     //     0,
    //     //     "project creation"
    //     // );

    //     // vm.warp(3 seconds);

    //     // bytes32 projectID = keccak256(
    //     //     abi.encode(
    //     //         "project 3",
    //     //         100 ether,
    //     //         block.timestamp,
    //     //         "solve testnet sybil with zkp"
    //     //     )
    //     // );

    //     // raiseBoxStorage.updateStorage(
    //     //     projectID,
    //     //     "project 1",
    //     //     alice,
    //     //     "solve testnet sybil with zkp",
    //     //     100 ether,
    //     //     30 days,
    //     //     true,
    //     //     block.timestamp,
    //     //     0,
    //     //     0,
    //     //     // "project creation"
    //     // );
    // }

    // function testRemainingContribution() public {
    //     vm.startPrank(alice);
    //     raiseBoxProjectCreationContract.createProject(
    //         "project 1",
    //         "solve testnet sybil with zkp",
    //         10 ether,
    //         30 days
    //     );
    //     vm.stopPrank();

    //     raiseBoxContributionContract.contribute{value: 1.5 ether}(1.5 ether, 1);

    //     // raiseBoxContributionContract.contribute{value: 20 ether}(20 ether, 10);

    //     uint256 remaining = raiseBoxContributionContract.getRemainingContributionInEth(1);

    //     // Logs as raw wei (e.g. 1900000000000000000)
    //     console.log("Remaining (wei):", remaining);

    //     // Logs with 18 decimals (divide into whole and fractional)
    //     uint256 whole = remaining / 1e18;
    //     uint256 fraction = remaining % 1e18;

    //     console.log("Remaining (ether): ", whole, fraction);
    // }

    // function testCreateProject() public {
    //     vm.prank(owner);
    //     bytes32 id1 = raiseBoxProjectCreationContract.createProject(
    //         "project 1",
    //         "solve testnet sybil with zkp",
    //         10 ether,
    //         30 days
    //     );

    //     // vm.warp(2 days);

    //     // vm.prank(owner);
    //     // bytes32 id2 = raiseBoxProjectCreationContract.createProject(
    //     //     "project 1",
    //     //     "solve testnet sybil with zkp",
    //     //     10 ether,
    //     //     30 days
    //     // );

    //     // vm.prank(owner);
    //     // bytes32 id2 = raiseBoxProjectCreationContract.createProject(
    //     //     "project 2",
    //     //     "decentralize AI",
    //     //     50 ether,
    //     //     30 days
    //     // );

    //     bool projectExist = raiseBoxStorage.doesProjectExist(id1);

    //     // vm.prank(joe);
    //     // raiseBoxContributionContract.contribute{value: 2 ether}(2 ether, id1);

    //     // logProject(raiseBoxStorage.getProject(id1));

    //     // vm.prank(owner);
    //     // bytes32 id3 = raiseBoxProjectCreationContract.createProject(
    //     //     "project 3",
    //     //     "solve testnet sybil with zkp",
    //     //     600_000,
    //     //     30 days
    //     // );

    //     // RaiseBox.ProjectInfo memory p3 = raiseBoxProjectCreationContract.getProject(id3);
    //     // logProject(p3);

    //     // vm.prank(owner);
    //     // bytes32 id4 = raiseBoxProjectCreationContract.createProject(
    //     //     "project 4",
    //     //     "solve testnet sybil with zkp",
    //     //     100_000_000,
    //     //     30 days
    //     // );

    //     // RaiseBox.ProjectInfo memory p4 = raiseBoxProjectCreationContract.getProject(id4);
    //     // logProject(p4);

    //     // // RaiseBox.ProjectInfo memory p5 = raiseBoxProjectCreationContract.getProject(5);
    //     // logProject(p5);

    //     // console.log(raiseBoxProjectCreationContract.getProtocolFeeForProject(8));
    // }

    // function testGetProjectByIndexReturnsCorrectProjectID() public {
    //     vm.prank(alice);
    //     bytes32 id = raiseBoxProjectCreationContract.createProject(
    //         "poseidon",
    //         "AI Swarmp",
    //         300 ether,
    //         30 days
    //     );

    //     vm.prank(alice);
    //     bytes32 id2 = raiseBoxProjectCreationContract.createProject(
    //         "poseidon2",
    //         "zero knowledge proof verifs",
    //         3000 ether,
    //         30 days
    //     );

    //     assertEq(raiseBoxProjectCreationContract.getProjectByIndex(1).projectID, id);
    //     assertEq(raiseBoxProjectCreationContract.getProjectByIndex(2).projectID, id2);
    // }

    // function testAmountRaisedByProjectUpdatesCorrectly() public {
    //     vm.prank(alice);
    //     raiseBoxProjectCreationContract.createProject(
    //         "project 1",
    //         "solve high gas fees in ethereum using transaction bundling",
    //         50 ether,
    //         30 days
    //     );

    //     vm.prank(alice);
    //     raiseBoxContributionContract.contribute{value: 20 ether}(20 ether, 1);

    //     console.log(raiseBoxContributionContract.getTotalContributions(1));
    //     console.log(
    //         raiseBoxContributionContract.getTotalAmountContributedByContributor(
    //             alice,
    //             1
    //         )
    //     );

    //     console.log(raiseBoxProjectCreationContract.getProtocol().balance);
    //     console.log(raiseBoxProjectCreationContract.getAmountRaisedByProject(1));

    //     vm.prank(alice);
    //     raiseBoxContributionContract.contribute{value: 20 ether}(20 ether, 1);

    //     console.log(raiseBoxContributionContract.getTotalContributions(1));
    //     console.log(
    //         raiseBoxContributionContract.getTotalAmountContributedByContributor(
    //             alice,
    //             1
    //         )
    //     );

    //     console.log(address(raiseBoxProjectCreationContract));

    // }

    // function testGetProjectInfo() public {
    //     vm.startPrank(alice);
    //     raiseBoxProjectCreationContract.createProject(
    //         "project 1",
    //         "solve testnet sybil with zkp",
    //         10 ether,
    //         30 days
    //     );

    //     raiseBoxContributionContract.contribute{value: 1 ether}(1 ether, 1);
    //     vm.stopPrank();
    //     vm.prank(alice);
    //     raiseBoxContributionContract.contribute{value: 7 ether}(7 ether, 1);

    //     string memory projectName = raiseBoxProjectCreationContract.getProject(1).projectName;
    //     address projectOwner = raiseBoxProjectCreationContract.getProject(1).projectOwner;
    //     string memory valueProposition = raiseBoxProjectCreationContract
    //         .getProject(1)
    //         .valueProposition;
    //     uint256 amountToRaise = raiseBoxProjectCreationContract.getProject(1).amountToRaise;
    //     uint256 duration = raiseBoxProjectCreationContract.getProject(1).duration;
    //     uint256 projectId = raiseBoxProjectCreationContract.getProject(1).projectID;
    //     uint256 amountRaised = raiseBoxProjectCreationContract
    //         .getProject(1)
    //         .amountRaisedByProject;

    //     console.log(projectName);
    //     console.log(projectOwner);
    //     console.log(valueProposition);
    //     console.log(amountToRaise);
    //     console.log(duration);
    //     console.log(projectId);
    //     console.log(amountRaised);
    // }
}
