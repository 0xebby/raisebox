// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CrowdFund} from "../src/CrowdFund.sol";
import {Script} from "forge-std/Script.sol";

contract DeployCrowdFund is Script {
    CrowdFund crowdFund;

    function run() public {
        vm.startBroadcast();
        crowdFund = new CrowdFund();
        // 0x32e29476f95e446a4f717d25825ba882c5874f04;
        //0x32E29476f95e446A4f717d25825BA882c5874F04
        vm.stopBroadcast();
    }

    // ca: 0xBa4201af3137eC58528bEED242B95cddb228f99C
}
