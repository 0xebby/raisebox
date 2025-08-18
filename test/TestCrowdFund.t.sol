// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CrowdFund} from "../src/CrowdFund.sol";
import {Test, console} from "forge-std/Test.sol";

contract TestCrowdFund is Test {
    CrowdFund crowdFundContract;
    

    address contributor1 = address(0x1);
    address contributor2 = address(0x2);
    address contributor3 = address(0x3);

    address public projectA = address(0x4);
    address public projectB = address(0x5);
    address public projectC = address(0x6);

    // address protocolOwner = address(0x5);
    // address protocolFees = address(0x6);

    function setUp() public {
        vm.deal(contributor1, 10 ether);
        vm.deal(contributor2, 10 ether);
        vm.deal(contributor3, 10 ether);

        crowdFundContract = new CrowdFund();
        
    }

    function testHostAProposal() public {
        // enough time has passed before hosting a new proposal
        vm.warp(30 days);
        vm.prank(projectA);
        crowdFundContract.hostProposal("proposal name: new dao", "achievement: deployed first dao mvp", projectA);

        uint256 last1 = crowdFundContract.blockTimeOfLastProposal();
        console.log(last1);

        vm.warp(40 days);
        vm.prank(projectB);
        crowdFundContract.hostProposal("proposal name: dubai event", "achievement: sorted all event planning and logistics", projectB);

        vm.warp(70 days);
        vm.prank(projectB);
        crowdFundContract.hostProposal("proposal name: shaighai event", "achievement: sorted all event planning and logistics", projectB);
        

        vm.warp(60 days);
        vm.prank(projectA);
        crowdFundContract.hostProposal("proposal name: testnet launch", "achievement: testnet website completed", projectA);
        assertEq(crowdFundContract.getMilestoneProposalDetails(projectA)[0].lastProposalTime, 2592000 );

         vm.warp(90 days);
        vm.prank(projectA);
        crowdFundContract.hostProposal("proposal name: testnet launch", "achievement: testnet website completed", projectA);
        

        //  vm.warp(90 days);
        // vm.prank(projectA);
        // crowdFundContract.hostProposal("proposal name: testnet launch", "achievement: testnet website completed", projectA);

        uint256 lastProposalDate = crowdFundContract.getMilestoneProposalDetails(projectA)[0].lastProposalTime;
        uint256 secondProposalDate = crowdFundContract.getMilestoneProposalDetails(projectA)[1].lastProposalTime;
        uint256 lastProposalDateB = crowdFundContract.getMilestoneProposalDetails(projectB)[0].lastProposalTime;
        console.log(lastProposalDate);
        console.log(secondProposalDate);
        console.log(lastProposalDateB);
        uint256 last = crowdFundContract.blockTimeOfLastProposal();
        console.log(last);
        




       
      
    }

}

       
       
//     }
//     function testAmountContributedIsEqualProtocolBalance() public {
//         vm.prank(contributor2);
//         crowdFundContract.contribute{value: 1 ether}(1 ether);
//         uint256 fee = crowdFundContract.getProtocolFee(1 ether);
//         uint256 actualAmountContributedByContributor2 = 1 ether - fee;
//         assertEq(crowdFundContract.protocol().balance, actualAmountContributedByContributor2);
        

//     }
//     function testContribute() public {
//         vm.prank(contributor1);
//         crowdFundContract.contribute{value: 1 ether}(1 ether);

//         vm.prank(contributor2);
//         crowdFundContract.contribute{value: 1 ether}(1 ether);

//         uint256 contributions = 2 ether;
//         uint256 feesPaidToProtocol = crowdFundContract.getProtocolFee(contributions);

//         assertEq(address(crowdFundContract.protocol()).balance, (contributions - feesPaidToProtocol));

//         // vm.prank(protocolFees);
//         // crowdFundContract.withdrawProtocolFees();
//         // assertEq(protocolFees.balance, crowdFundContract.getTotalProtocolFees());

//         // assertEq(crowdFundContract.getTotalAmountContributed(), (contributions - feesPaidToProtocol));
//         // console.log(crowdFundContract.getAmountContributedByContributor(contributor1));
//         // console.log(crowdFundContract.getAmountContributedByContributor(contributor2));
//     }

//     function testTotalAmountContributed() public {
        
//         vm.prank(contributor1);
//         crowdFundContract.contribute{value: 1 ether}( 1 ether );

//         vm.prank(contributor1);
//         crowdFundContract.contribute{value: 1 ether}( 1 ether );

//         vm.prank(contributor2);
//         crowdFundContract.contribute{value: 1 ether}( 1 ether );
//         address[] memory contributorsList = crowdFundContract.getContributors();

//         uint256 actualAmountContributedToProject = crowdFundContract.getTotalAmountContributed();
//         console.log(actualAmountContributedToProject);

//         for (uint256 i = 0; i < contributorsList.length; i++) {
//             console.log(crowdFundContract.getAmountContributedByContributor(contributorsList[i]));

            
//         }


        
//     }

//     function testTotalAmountContributedIsCorrect() public {
//         vm.prank(contributor1);
//         crowdFundContract.contribute{value: 1 ether}(1 ether);

//         vm.prank(contributor2);
//         crowdFundContract.contribute{value: 2 ether}(2 ether);

//         uint256 contributions = 3 ether;
//         uint256 _protocolFee = crowdFundContract.getProtocolFee(contributions);


//         uint amountAfterFeesDeduction = contributions - _protocolFee;

//         assertEq(crowdFundContract.getTotalAmountContributed(), amountAfterFeesDeduction);
//     }

//     function testGetProtocolFee() public {
//         vm.prank(contributor1);
//         crowdFundContract.contribute{value: 1 ether}(1 ether);

//         uint256 _protocolFee = crowdFundContract.getProtocolFee( 1 ether);
//         console.log(_protocolFee);
//         assertEq((1 ether - _protocolFee), 95e16);
//     }

//     // function testContribute() public {
//     //     vm.prank(contributor1);
//     //     crowdFundContract.contribute{value: 1 ether}( 1 ether );

//     //     vm.prank(contributor1);
//     //     crowdFundContract.withdrawProtocolFees();
//     //     // check if protocoFee balance increased by contribution
//     //     console.log(address(crowdFundContract).balance);
//     //     console.log(protocolOwner.balance);
//     //     console.log(protocolFees.balance);

        



        

//     //     // uint256 contributions = 1 ether;
//     //     // uint256 _protocolFee = crowdFundContract.getProtocolFee(contributions);
//     //     // uint256 amountAfterFeesDeduction = (contributions - _protocolFee);

//     //     // // State Update Assertion: check that the contibutors list has been updated with contributor1
//     //     // // State Update Assertion 2: check that the mapping of addressToAmountContributed updates the right amount contributed by contributor 1

//     //     // address[] memory contributorsList = crowdFundContract.getContributors();

//     //     // assertEq(contributorsList[0], contributor1);
//     //     // // assertEq(contributorsList[1], contributor2);
//     //     // // assertTrue(contributorsList.length == 2);
       

//     //     // // Balance Assertions:
//     //     // // 1: check that the balance of the project Owner increased by the amount contributed - protocol fee
//     //     // // assertEq(crowdFundContract.projectOwner().balance, amountAfterFeesDeduction);


//     //     // // 2. check that contract/protocol balance increased by protocolFee amount
//     //     // // assertEq(address(crowdFundContract).balance, crowdFundContract.getTotalProtocolFees());
//     //     // console.log(address(crowdFundContract).balance);
//     //     // console.log(crowdFundContract.getTotalProtocolFees());
//     //     // console.log(amountAfterFeesDeduction);
//     //     // console.log(owner.balance);


//     //     // // 3. check that balance of contributor reduces by amount contributed
//     //     // assertEq(address(contributor1).balance, 9 ether);

//     //     // // mappping update Assertions:
//     //     // // check that the amount contributed per address has been updated correctly in the addressToAmountContributed mapping
//     //     // assertEq(crowdFundContract.contributorsToAmountContributed(contributor1), 1 ether);
//     //     // // assertEq(crowdFundContract.contributorsToAmountContributed(contributor2), 2 ether);

//     //     // // check that a contributed is marked as has contributed if succesfully contributed

//     //     // // assertTrue(crowdFundContract.hasContributed(contributor1) == true);

//     //     // // Revert Assertions:
//     //     // // check that the contract reverts if an invalid or 0 eth contribution is going to be made by contributor

//     //     vm.prank(contributor1);
//     //     vm.expectRevert();
//     //     crowdFundContract.contribute{value: 0 ether }(0 ether);


//     // }

//     function testWithdrawProtocolFees() public {
//         // Balance Assertion: 1. check that the protocol balance increases by protocol fee when contribute is called

//         // 2. check that only protocolOwner can withdraw fees
//         vm.startPrank(contributor1);
//         crowdFundContract.contribute{value: 1 ether}( 1 ether);
//         // vm.expectRevert();
//         // crowdFundContract.withdrawProtocolFees();
//         vm.stopPrank();

//         // 3. check that protocol owner can actually withdraw fees:
//         // a. balance of protocol before and after withdrawal updates correctly

//         uint256 protocolOwnerInitialBalance;
//          console.log(crowdFundContract.totalProtocolFees());
//          crowdFundContract.updateProtocolOwner(protocolFees);
//         vm.prank(protocolFees);
//         crowdFundContract.withdrawProtocolFees();
//         uint256 protocolOwnerFinalBalance = crowdFundContract.protocol().balance;

//         console.log(crowdFundContract.totalProtocolFees());
//         console.log(address(crowdFundContract).balance);

//         assertTrue(protocolOwnerInitialBalance != protocolOwnerFinalBalance);
//         // assertEq(protocolOwnerFinalBalance,  e16);
        

//     }

//     function testOnlyProjectOwnerCanCallHostProposal() public {
       
        

//     }
// }


