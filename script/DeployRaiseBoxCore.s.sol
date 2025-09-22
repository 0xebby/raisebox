// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {RaiseBox} from "../src/RaiseBoxProjectCreation.sol";
import {Script} from "forge-std/Script.sol";

contract DeployRaiseBoxCore is Script {
    RaiseBox deployedRaiseBox;

    function run() public {
        vm.startBroadcast();
        deployedRaiseBox = new RaiseBox(address(0x5));
        vm.stopBroadcast();
    }
}
