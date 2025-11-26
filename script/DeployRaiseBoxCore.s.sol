// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {RaiseBox} from "../src/RaiseBoxRaiseCreation.sol";
import {Script} from "forge-std/Script.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {RaiseBoxContribution} from "../src/RaiseBoxContribution.sol";
import {RaiseBoxProposal} from "../src/RaiseBoxProposal.sol";
import {RaiseBoxVoting} from "../src/RaiseBoxVoting.sol";

contract DeployRaiseBoxCore is Script {
    function run() public {
        // main contract that holds general storage
        RaiseBoxCore raiseBoxCore;

        // project creation contract
        RaiseBox raiseBoxProjectCreationContract;

        // contribution contract
        RaiseBoxContribution raiseBoxContributionContract;

        // proposal contract
        RaiseBoxProposal raiseBoxProposalContract;
        vm.startBroadcast();

        // setter contract
        // setter = new SetterContract()
        // 

        raiseBoxCore = new RaiseBoxCore();

        // setter.setRaiseBoxCore(address())

        raiseBoxProjectCreationContract = new RaiseBox(address(raiseBoxCore));

        raiseBoxCore.setRaiseCreationContract(address(raiseBoxProjectCreationContract));

        raiseBoxContributionContract = new RaiseBoxContribution(address(raiseBoxCore));

        raiseBoxCore.setContributionContract(address(raiseBoxContributionContract));

        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore), address(0)); // set voting contract address later

        raiseBoxCore.setProposalContract(address(raiseBoxProposalContract));

        RaiseBoxVoting raiseBoxVoting =
            new RaiseBoxVoting(address(raiseBoxCore), address(raiseBoxContributionContract));

        raiseBoxCore.setVotingContract(address(raiseBoxVoting));

        // now set the voting contract address in proposal contract
        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore), address(raiseBoxVoting));

        



        vm.stopBroadcast();
    }
}
