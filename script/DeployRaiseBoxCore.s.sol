// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {RaiseBox} from "../src/RaiseBoxProjectCreation.sol";
import {Script} from "forge-std/Script.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {RaiseBoxContribution} from "../src/RaiseBoxContribution.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
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

        raiseBoxCore = new RaiseBoxCore();

        raiseBoxProjectCreationContract = new RaiseBox(address(raiseBoxCore));

        raiseBoxCore.setProjectCreationContractAddress(address(raiseBoxProjectCreationContract));

        raiseBoxContributionContract = new RaiseBoxContribution(address(raiseBoxCore));

        raiseBoxCore.setContributionContractAddress(address(raiseBoxContributionContract));

        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore), address(0)); // set voting contract address later

        raiseBoxCore.setProposalContractAddress(address(raiseBoxProposalContract));

        RaiseBoxVoting raiseBoxVotingContract =
            new RaiseBoxVoting(address(raiseBoxCore), address(raiseBoxContributionContract));

        raiseBoxCore.setVotingContractAddress(address(raiseBoxVotingContract));

        // now set the voting contract address in proposal contract
        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore), address(raiseBoxVotingContract));

        



        vm.stopBroadcast();
    }
}
