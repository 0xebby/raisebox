// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {RaiseBox} from "../src/RaiseBoxProjectCreation.sol";
import {Script} from "forge-std/Script.sol";
import {RaiseBoxStorage} from "../src/RaiseBoxStorage.sol";

contract DeployRaiseBoxCore is Script {
    RaiseBox raiseBoxProjectCreationDeployer;
    RaiseBoxStorage raiseBoxStorageDeployer;

    function run() public {
        vm.startBroadcast();
        raiseBoxStorageDeployer = new RaiseBoxStorage();
        raiseBoxProjectCreationDeployer = new RaiseBox(address(raiseBoxStorageDeployer));

        raiseBoxStorageDeployer.setProjectCreationContractAddress(address(raiseBoxProjectCreationDeployer));
        vm.stopBroadcast();
    }
}
