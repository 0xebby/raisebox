// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {RaiseBoxCreation} from "../src/RaiseBoxRaiseCreation.sol";
import {Script} from "forge-std/Script.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {RaiseBoxContribution} from "../src/RaiseBoxContribution.sol";
import {RaiseBoxProposal} from "../src/RaiseBoxProposal.sol";
import {RaiseBoxVoting} from "../src/RaiseBoxVoting.sol";
import {RaiseBoxDripHandler} from "src/RaiseBoxDripHandler.sol";

contract DeployRaiseBoxCore is Script {
    function run() public {
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

        vm.startBroadcast();

        // setter contract
        // setter = new SetterContract()


        raiseBoxCore = new RaiseBoxCore();

        // setter.setRaiseBoxCore(address())

        raiseBoxRaiseCreationContract = new RaiseBoxCreation(address(raiseBoxCore));

        raiseBoxCore.setRaiseCreationContract(address(raiseBoxRaiseCreationContract));


        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore)); 

        raiseBoxCore.setProposalContract(address(raiseBoxProposalContract));

        
        raiseBoxDripHandler = new RaiseBoxDripHandler(address(raiseBoxCore), address(raiseBoxProposalContract), address(0));

        raiseBoxCore.setDripHandlerContract(address(raiseBoxDripHandler));
        

        raiseBoxContributionContract = new RaiseBoxContribution(address(raiseBoxCore), address(raiseBoxDripHandler));

        raiseBoxCore.setContributionContract(address(raiseBoxContributionContract));

        
        raiseBoxVoting = new RaiseBoxVoting(address(raiseBoxCore), address(raiseBoxContributionContract), address(raiseBoxProposalContract), address(raiseBoxDripHandler));

        raiseBoxCore.setVotingContract(address(raiseBoxVoting));

        raiseBoxDripHandler.setVoting(address(raiseBoxVoting));

        vm.stopBroadcast();
    }
}
