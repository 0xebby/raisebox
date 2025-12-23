// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../lib/forge-std/src/Test.sol";
import {RaiseBoxCreation} from "../src/RaiseBoxRaiseCreation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RaiseBoxContribution} from "../src/RaiseBoxContribution.sol";
import {RaiseBoxProposal} from "../src/RaiseBoxProposal.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {RaiseBoxVoting} from "../src/RaiseBoxVoting.sol";
import {RaiseBoxDripHandler} from "src/RaiseBoxDripHandler.sol";
import {IRaiseBoxCore} from "src/interfaces/IRaiseBoxCore.sol";

contract TestsHelpers is Test {
    // main contract that holds general storage
    RaiseBoxCore raiseBoxCore;

    // project creation contract
    RaiseBoxCreation raiseBoxRaiseCreationContract;

    // contribution contract
    RaiseBoxContribution raiseBoxContributionContract;

    // proposal contract
    RaiseBoxProposal raiseBoxProposalContract;

    // voting contract
    RaiseBoxVoting raiseBoxVoting;

    // drip handler:
    RaiseBoxDripHandler raiseBoxDripHandler;

    // faucet contract address
    address faucetToken = 0xB15D5A9DCcCCcb3Caf55360D89610834A72Cf6b3;

    // raisebox testOwner == deployer
    address testOwner;

    // make dummy addresses for test
    address alice = makeAddr("alice");
    address joe = makeAddr("joe");
    address ben = makeAddr("ben");
    address max = makeAddr("max");
    address uche = makeAddr("uche");
    address sam = makeAddr("sam");
    address mark = makeAddr("mark");
    address sally = makeAddr("sally");
    address ebby = makeAddr("ebby");
    address vitalik = makeAddr("vitalik");

    // get  would be ca of raisebox - project creation contract

    using Strings for uint256;

    address raiseBoxOwner;

    function setUp() public {
        vm.startPrank(address(this));

        // deploy the main contract that holds general storage
        raiseBoxCore = new RaiseBoxCore();

        raiseBoxOwner = raiseBoxCore.getRaiseBoxOwner();

        // setter.setRaiseBoxCore(address())

        raiseBoxRaiseCreationContract = new RaiseBoxCreation(address(raiseBoxCore));

        raiseBoxCore.setRaiseCreationContract(address(raiseBoxRaiseCreationContract));

        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore));

        raiseBoxCore.setProposalContract(address(raiseBoxProposalContract));

        raiseBoxDripHandler =
            new RaiseBoxDripHandler(address(raiseBoxCore), address(raiseBoxProposalContract), address(0));

        raiseBoxCore.setDripHandlerContract(address(raiseBoxDripHandler));

        raiseBoxContributionContract = new RaiseBoxContribution(address(raiseBoxCore), address(raiseBoxDripHandler));

        raiseBoxCore.setContributionContract(address(raiseBoxContributionContract));

        raiseBoxVoting = new RaiseBoxVoting(
            address(raiseBoxCore),
            address(raiseBoxContributionContract),
            address(raiseBoxProposalContract),
            address(raiseBoxDripHandler)
        );

        raiseBoxCore.setVotingContract(address(raiseBoxVoting));

        raiseBoxProposalContract.setVotingContract(address(raiseBoxVoting));

        raiseBoxDripHandler.setVoting(address(raiseBoxVoting));

        vm.stopPrank();

        testOwner = address(this);
        vm.deal(testOwner, 500 ether);
        vm.deal(alice, 100 ether);
        vm.deal(joe, 100 ether);
        vm.deal(ben, 100 ether);
        vm.deal(max, 100 ether);
        vm.deal(uche, 100 ether);
        vm.deal(sam, 100 ether);
        vm.deal(mark, 100 ether);
        vm.deal(sally, 100 ether);
        vm.deal(ebby, 100 ether);
        vm.deal(vitalik, 100 ether);

        // whitelist 2 users to serve as raiseCreators:
        raiseBoxCore.verifyAndAddToWhitelist(ebby);
        raiseBoxCore.verifyAndAddToWhitelist(vitalik);
    }

    /**
     * @dev Helper function to simulate time passing since testing environment doesn't work as expected
     * @param raiseDuration_ amount of time to advanced, could be in days, hours, minutes or seconds. default is seconds*
     */
    function advanceBlockTime(uint256 raiseDuration_) internal {
        vm.warp(block.timestamp + raiseDuration_);
    }

    // function createTestProjects() public {
    //     vm.startPrank(ben);
    //     bytes32 projectID0 = raiseBoxRaiseCreationContract.createRaise(
    //         "Sentient", "Building AGI - Collectively owned AI", 20 ether, 52 weeks
    //     );
    //     vm.stopPrank();

    //     vm.startPrank(alice);
    //     bytes32 projectID1 =
    //         raiseBoxRaiseCreationContract.createRaise("Hello Elsa", "Chat, trade and swap using AI", 20 ether, 60 weeks);
    //     vm.stopPrank();
    // }

    function contributeToTestProject() public returns (bytes32 projectId) {
        raiseBoxCore.verifyAndAddToWhitelist(ben);
        vm.startPrank(ben);
        projectId = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
            projectOwner:ben,
            projectName:"sentient",
            valueProposition:"agi",
            raiseTarget:20 ether,
            projectDuration:56 weeks
        })
        );
        vm.stopPrank();

        raiseBoxCore.getRaiseInfo(projectId);


        address[5] memory contributors = [ebby, sally, uche, max, mark];

        for (uint256 i = 0; i < contributors.length; i++) {
            vm.startPrank(contributors[i]);
            raiseBoxContributionContract.contribute{value: 4 ether}(4 ether, projectId);
            vm.stopPrank();
        }

        return projectId;
    }
}
