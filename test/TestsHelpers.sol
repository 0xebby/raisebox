// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../lib/forge-std/src/Test.sol";
import {RaiseBox} from "../src/RaiseBoxProjectCreation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RaiseBoxContribution} from "../src/RaiseBoxContribution.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {RaiseBoxProposal} from "../src/RaiseBoxProposal.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";

contract TestsHelpers is Test {
    // main contract that holds general storage
    RaiseBoxCore raiseBoxStorage;

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

    // make dummy addresses for test
    address alice = makeAddr("alice");
    address joe = makeAddr("joe");
    address ben = makeAddr("ben");
    address max = makeAddr("max");
    address uche = makeAddr("uche");
    address sam = makeAddr("sam");

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

        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxStorage));

        raiseBoxStorage.setProposalContractAddress(address(raiseBoxProposalContract));

        owner = address(this);
        vm.deal(owner, 500 ether);
        vm.deal(alice, 100 ether);
        vm.deal(joe, 100 ether);
        vm.deal(ben, 100 ether);
        vm.deal(max, 100 ether);
        vm.deal(uche, 100 ether);
        vm.deal(sam, 100 ether);
    }

    /**
     * @dev Helper function to simulate time passing since testing environment doesn't work as expected
     * @param duration_ amount of time to advanced, could be in days, hours, minutes or seconds. default is seconds*
     */
    function advanceBlockTime(uint256 duration_) internal {
        vm.warp(block.timestamp + duration_);
    }

    function createTestProjects() public {
        vm.startPrank(ben);
        bytes32 projectID0 = raiseBoxProjectCreationContract.createProject(
            "Sentient", "Building AGI - Collectively owned AI", 20 ether, 52 weeks
        );
        vm.stopPrank();

        vm.startPrank(alice);
        bytes32 projectID1 = raiseBoxProjectCreationContract.createProject(
            "Hello Elsa", "Chat, trade and swap using AI", 20 ether, 60 weeks
        );
        vm.stopPrank();

        // vm.startPrank(joe);
        // bytes32 projectID2 = raiseBoxProjectCreationContract.createProject(
        //     "FeedTheWorld NGO", "operation feed 2,000 kids", 10 ether, 30 days
        // );
        // vm.stopPrank();

        // vm.startPrank(max);
        // bytes32 projectID3 = raiseBoxProjectCreationContract.createProject(
        //     "Base App", "onboarding the next 1b users onchain", 100 ether, 30 days
        // );
        // vm.stopPrank();
    }

    function contributeToTestProject(bytes32 projectId, address contributor, uint256 amount) public {
        vm.startPrank(contributor);
        raiseBoxContributionContract.contribute{value: amount}(amount, projectId);
        vm.stopPrank();
    }
}
