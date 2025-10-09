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
import {RaiseBoxStorage} from "../src/RaiseBoxStorage.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";

contract RaiseBoxProjectCreationTest is Test {
    // main contract that holds general storage
    RaiseBoxStorage raiseBoxStorage;

    // core interface
    IRaiseBoxCore raiseBoxCore;

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
        raiseBoxStorage = new RaiseBoxStorage();

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
    }

    /**
     * @dev Helper function to simulate time passing since testing environment doesn't work as expected
     * @param duration_ amount of time to advanced, could be in days, hours, minutes or seconds. default is seconds*
     */
    function advanceBlockTime(uint256 duration_) internal {
        vm.warp(block.timestamp + duration_);
    }

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
            "sentient", "AGI: AI but collectively owned and decentralized", 100 ether, 30 days
        );
        vm.stopPrank();

        vm.startPrank(joe);
        bytes32 projectID3 = raiseBoxProjectCreationContract.createProject(
            "FeedTheWorld NGO", "operation feed 2,000 kids", 100 ether, 30 days
        );
        vm.stopPrank();

        advanceBlockTime(104 weeks); // 2 years
        vm.startPrank(joe);
        bytes32 projectID4 =
            raiseBoxProjectCreationContract.createProject("NGO", "missionary journey to Rome", 50 ether, 30 days);
        vm.stopPrank();

        raiseBoxStorage.getProjectCount();
        assertEq(raiseBoxStorage.getProjectCount(), 4);
    }
}
