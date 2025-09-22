// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./moon.sol";
import {Script} from "forge-std/Script.sol";

contract deployMoon is Script {
    moon moonContract;

    function run() public {
        vm.startBroadcast();
        moonContract = new moon();
        vm.stopBroadcast();
    }
}
