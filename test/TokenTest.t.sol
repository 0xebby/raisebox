// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {RaiseBoxCreation} from "../src/RaiseBoxRaiseCreation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RaiseBoxContribution} from "../src/RaiseBoxContribution.sol";
import {RaiseBoxProposal} from "../src/RaiseBoxProposal.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {RaiseBoxVoting} from "../src/RaiseBoxVoting.sol";
import {RaiseBoxDripHandler} from "src/RaiseBoxDripHandler.sol";
import {MockToken} from "../src/mock/MockToken.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";
import {TestsHelpers} from "./TestsHelpers.sol";

contract TokenTest is Test, TestsHelpers {

    function testERC20Contribution() public {
        address contributor = makeAddr("contributor");
        console.log("DripHandler CA: ", address(raiseBoxDripHandler));
        console.log("RaiseBoxContribution CA: ", address(raiseBoxContributionContract));
        
        // Setup: Create ERC20 raise
        vm.startPrank(testOwner);
        bytes32 raiseId = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
                projectName: "ERC20 Test Project",
                valueProposition: "Testing ERC20 contributions",
                raiseTarget: 1000 ether,
                projectDuration: 52 weeks
            })
        );
        vm.stopPrank();
        
        // Setup: Give tokens to contributor and approve
        raiseboxtoken.mint(contributor, 500 ether);
        vm.startPrank(contributor);
        raiseboxtoken.approve(address(raiseBoxContributionContract), 500 ether);
        
        // Test: Contribute ERC20 tokens
        raiseBoxContributionContract.contribute(100 ether, raiseId);
        vm.stopPrank();
        
        // Assert: Check contribution was recorded
        uint256 contributed = raiseBoxContributionContract.getUserRaiseContributions(raiseId, contributor);
        assertEq(contributed, 100 ether);
        
        uint256 totalRaised = raiseBoxContributionContract.getTotalContributionsToRaise(raiseId);
        assertEq(totalRaised, 100 ether);
    }

    function testCannotContributWithEth() public {
        address contributor = makeAddr("contributor");
        vm.deal(contributor, 100 ether);
        
        // Setup: Create ERC20 raise
        vm.startPrank(testOwner);
        bytes32 raiseId = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
                projectName: "ERC20 Test Project",
                valueProposition: "Testing ERC20 contributions",
                raiseTarget: 1000 ether,
                projectDuration: 52 weeks
            })
        );
        vm.stopPrank();
        uint256 amount = 10 ether;

        vm.prank(contributor);
        raiseBoxContributionContract.contribute{value: amount }(amount, raiseId);
        // Assert: Check contribution was recorded
        uint256 contributed = raiseBoxContributionContract.getUserRaiseContributions(raiseId, contributor);
        assertEq(contributed, 10 ether);
        
        uint256 totalRaised = raiseBoxContributionContract.getTotalContributionsToRaise(raiseId);
        assertEq(totalRaised, 10 ether);
    }

    function testErc20AndEtherContribution() public {
        address contributor = makeAddr("contributor");
        vm.deal(contributor, 100 ether);
        raiseboxtoken.mint(contributor, 100 ether);
        
        // Setup: Create ERC20 raise
        vm.startPrank(testOwner);
        bytes32 raiseId = raiseBoxRaiseCreationContract.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
                projectName: "ERC20 Test Project",
                valueProposition: "Testing ERC20 contributions",
                raiseTarget: 1000 ether,
                projectDuration: 52 weeks
            })
        );
        vm.stopPrank();

        vm.startPrank(contributor);
        raiseboxtoken.approve(address(raiseBoxContributionContract), 10 ether);
        raiseBoxContributionContract.contribute{value: 10 ether}(10 ether, raiseId);
        raiseBoxContributionContract.contribute(10 ether, raiseId);
        vm.stopPrank();

        (uint256 ethRaised, uint256 erc20Raised) = raiseBoxContributionContract.getEthAndErcRaisedByProject(raiseId);
        assertEq(10 ether, ethRaised);
        assertEq(10 ether, erc20Raised);
    }
}