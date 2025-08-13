// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CrowdFund} from "../src/CrowdFund.sol";
import {Test, console} from "forge-std/Test.sol";

contract TestCrowdFund is Test {
    CrowdFund crowdFundContract;
    

    address contributor1 = address(0x1);
    address contributor2 = address(0x2);
    address contributor3 = address(0x3);
    address owner = address(0x4);
    address protocolOwner = 0x3989F40a2b256004A2866Ab0805859d30605Ca4a;

    function setUp() public {
        vm.deal(contributor1, 10 ether);
        vm.deal(contributor2, 10 ether);
        vm.deal(contributor3, 10 ether);
        // vm.deal(owner, 5 ether);

        crowdFundContract = new CrowdFund(owner);

       
       
    }

    function testTotalAmountContributedIsCorrect() public {
        vm.prank(contributor1);
        crowdFundContract.contribute{value: 1 ether}(1 ether);

        vm.prank(contributor2);
        crowdFundContract.contribute{value: 2 ether}(2 ether);

        uint256 contributions = 3 ether;
        uint256 _protocolFee = crowdFundContract.getProtocolFee(contributions);


        uint amountAfterFeesDeduction = contributions - _protocolFee;

        assertEq(crowdFundContract.getTotalAmountContributed(), amountAfterFeesDeduction);
    }

    function testGetProtocolFee() public {
        vm.prank(contributor1);
        crowdFundContract.contribute{value: 1 ether}(1 ether);

        uint256 _protocolFee = crowdFundContract.getProtocolFee( 1 ether);
        console.log(_protocolFee);
        assertEq((1 ether - _protocolFee), 95e16);
    }

    function testContribute() public {
        vm.prank(contributor1);
        crowdFundContract.contribute{value: 1 ether}( 1 ether );

        vm.prank(contributor2);
        crowdFundContract.contribute{value: 1 ether}( 1 ether );

        uint256 contributions = 2 ether;
        uint256 _protocolFee = crowdFundContract.getProtocolFee(contributions);
        uint amountAfterFeesDeduction = contributions - _protocolFee;

        // State Update Assertion: check that the contibutors list has been updated with contributor1
        // State Update Assertion 2: check that the mapping of addressToAmountContributed updates the right amount contributed by contributor 1

        address[] memory contributorsList = crowdFundContract.getContributors();
        assertEq(contributorsList[0], contributor1);
        assertEq(contributorsList[1], contributor2);
        assertTrue(contributorsList.length == 2);
       

        // Balance Assertions:
        // 1: check that the balance of the project Owner increased by the amount contributed - protocol fee
        assertEq(crowdFundContract.projectOwner().balance, amountAfterFeesDeduction);


        // 2. check that contract/protocol balance increased by protocolFee amount
        assertEq(address(crowdFundContract).balance, crowdFundContract.getTotalProtocolFees());


        // 3. check that balance of contributor reduces by amount contributed
        assertEq(address(contributor1).balance, 9 ether);

        // mappping update Assertions:
        // check that the amount contributed per address has been updated correctly in the addressToAmountContributed mapping
        assertEq(crowdFundContract.contributorsToAmountContributed(contributor1), 1 ether);
        assertEq(crowdFundContract.contributorsToAmountContributed(contributor2), 1 ether);

        // check that a contributed is marked as has contributed if succesfully contributed

        assertTrue(crowdFundContract.hasContributed(contributor1) == true);

        // Revert Assertions:
        // check that the contract reverts if an invalid or 0 eth contribution is going to be made by contributor

        vm.prank(contributor1);
        vm.expectRevert();
        crowdFundContract.contribute{value: 0 ether }(0 ether);


    }

    function testWithdrawProtocolFees() public {
        // Balance Assertion: 1. check that the protocol balance increases by protocol fee when contribute is called

        // 2. check that only protocolOwner can withdraw fees
        vm.startPrank(contributor1);
        crowdFundContract.contribute{value: 1 ether}( 1 ether);
        vm.expectRevert();
        crowdFundContract.withdrawProtocolFees();
        vm.stopPrank();

        // 3. check that protocol owner can actually withdraw fees:
        // a. balance of protocol before and after withdrawal updates correctly

        uint256 protoc0lOwnerInitialBalance;
        vm.prank(protocolOwner);
        crowdFundContract.withdrawProtocolFees();
        uint256 protocolOwnerFinalBalance = crowdFundContract.protocol().balance;

        console.log(crowdFundContract.totalProtocolFees());

        assertTrue(protoc0lOwnerInitialBalance != protocolOwnerFinalBalance);
        // assertEq(protocolOwnerFinalBalance,  e16);
        

    }
}

// Helper contract to receive ETH
contract PayableReceiver {
    receive() external payable {}
}
