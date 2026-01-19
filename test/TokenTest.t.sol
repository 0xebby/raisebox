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

contract TokenTest is Test {
    RaiseBoxDripHandler dripHandler;
    RaiseBoxProposal raiseboxProposal;
    RaiseBoxCreation raiseBoxCreation;
    RaiseBoxVoting raiseBoxVoting;
    RaiseBoxContribution raiseBoxContribution;
    RaiseBoxCore raiseBoxCore;
    MockToken token;

    address owner = address(this);
    uint256 public constant STARTING_BALANCE = 100_000;

    function setUp() external {
        token = new MockToken(STARTING_BALANCE);

        raiseBoxCore = new RaiseBoxCore();

        raiseBoxCreation = new RaiseBoxCreation(address(raiseBoxCore));
        raiseboxProposal = new RaiseBoxProposal(address(raiseBoxCore));

        dripHandler = new RaiseBoxDripHandler(
            address(raiseBoxCore),
            address(raiseboxProposal),
            address(0)  // voting - will set later
        );

        raiseBoxContribution =
            new RaiseBoxContribution(address(raiseBoxCore), address(dripHandler));

        raiseBoxVoting =
            new RaiseBoxVoting(
                address(raiseBoxCore),
                address(raiseBoxContribution),
                address(raiseboxProposal),
                address(dripHandler)
            );

        // register modules in core contract
        raiseBoxCore.setRaiseCreationContract(address(raiseBoxCreation));
        raiseBoxCore.setProposalContract(address(raiseboxProposal));
        raiseBoxCore.setContributionContract(address(raiseBoxContribution));
        raiseBoxCore.setVotingContract(address(raiseBoxVoting));
        raiseBoxCore.setDripHandlerContract(address(dripHandler));
        raiseboxProposal.setVotingContract(address(raiseBoxVoting));
        
        // Complete circular dependencies
        dripHandler.setVoting(address(raiseBoxVoting));
        dripHandler.setContribution(address(raiseBoxContribution));

        // Set token after all contracts are deployed
        vm.startPrank(owner);
        raiseBoxCore.setAcceptedToken(address(token));
        vm.stopPrank();
        
        raiseBoxCore.verifyAndAddToWhitelist(owner);
    }

    function testERC20Contribution() public {
        address contributor = makeAddr("contributor");
        console.log("DripHandler CA: ", address(dripHandler));
        console.log("RaiseBoxContribution CA: ", address(raiseBoxContribution));
        
        // Setup: Create ERC20 raise
        vm.startPrank(owner);
        bytes32 raiseId = raiseBoxCreation.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
                projectName: "ERC20 Test Project",
                valueProposition: "Testing ERC20 contributions",
                raiseTarget: 1000 ether,
                projectDuration: 52 weeks
            })
        );
        vm.stopPrank();
        
        // Setup: Give tokens to contributor and approve
        token.mint(contributor, 500 ether);
        vm.startPrank(contributor);
        token.approve(address(raiseBoxContribution), 500 ether);
        
        // Test: Contribute ERC20 tokens
        raiseBoxContribution.contribute(100 ether, raiseId);
        vm.stopPrank();
        
        // Assert: Check contribution was recorded
        uint256 contributed = raiseBoxContribution.getUserRaiseContributions(raiseId, contributor);
        assertEq(contributed, 100 ether);
        
        uint256 totalRaised = raiseBoxContribution.getTotalContributionsToRaise(raiseId);
        assertEq(totalRaised, 100 ether);
    }

    function testCannotContributWithEth() public {
        address contributor = makeAddr("contributor");
        vm.deal(contributor, 100 ether);
        
        // Setup: Create ERC20 raise
        vm.startPrank(owner);
        bytes32 raiseId = raiseBoxCreation.createNewRaise(
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
        raiseBoxContribution.contribute{value: amount }(amount, raiseId);
        // Assert: Check contribution was recorded
        uint256 contributed = raiseBoxContribution.getUserRaiseContributions(raiseId, contributor);
        assertEq(contributed, 10 ether);
        
        uint256 totalRaised = raiseBoxContribution.getTotalContributionsToRaise(raiseId);
        assertEq(totalRaised, 10 ether);
    }

    function testErc20AndEtherContribution() public {
        address contributor = makeAddr("contributor");
        vm.deal(contributor, 100 ether);
        token.mint(contributor, 100 ether);
        
        // Setup: Create ERC20 raise
        vm.startPrank(owner);
        bytes32 raiseId = raiseBoxCreation.createNewRaise(
            IRaiseBoxCore.ProjectInfo({
                projectName: "ERC20 Test Project",
                valueProposition: "Testing ERC20 contributions",
                raiseTarget: 1000 ether,
                projectDuration: 52 weeks
            })
        );
        vm.stopPrank();

        vm.startPrank(contributor);
        token.approve(address(raiseBoxContribution), 10 ether);
        raiseBoxContribution.contribute{value: 10 ether}(10 ether, raiseId);
        raiseBoxContribution.contribute(10 ether, raiseId);
        vm.stopPrank();

        (uint256 ethRaised, uint256 erc20Raised) = raiseBoxContribution.getEthAndErcRaisedByProject(raiseId);
        assertEq(10 ether, ethRaised);
        assertEq(10 ether, erc20Raised);
    }
}