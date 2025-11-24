// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {RaiseBox} from "../src/RaiseBoxProjectCreation.sol";
import {Script} from "forge-std/Script.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {RaiseBoxContribution} from "../src/RaiseBoxContribution.sol";
import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {RaiseBoxProposal} from "../src/RaiseBoxProposal.sol";

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

        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore));

        raiseBoxCore.setProposalContractAddress(address(raiseBoxProposalContract));

        vm.stopBroadcast();
    }
}
