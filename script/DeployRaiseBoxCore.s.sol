// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {RaiseBox} from "../src/RaiseBoxProjectCreation.sol";
import {Script} from "forge-std/Script.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";

contract DeployRaiseBoxCore is Script {
    RaiseBox raiseBoxProjectCreationDeployer;
    RaiseBoxCore raiseBoxStorageDeployer;

    function run() public {
        vm.startBroadcast();
        raiseBoxStorageDeployer = new RaiseBoxCore();
        raiseBoxProjectCreationDeployer = new RaiseBox(address(raiseBoxStorageDeployer));

        raiseBoxStorageDeployer.setProjectCreationContractAddress(address(raiseBoxProjectCreationDeployer));
        vm.stopBroadcast();
    }
}
