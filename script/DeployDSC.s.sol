//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DSCEngine} from "../src/DSCEngine.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {Script} from "forge-std/Script.sol";

contract DeployDSC is Script {
    function run() external returns(StableCoin, DSCEngine) {
        vm.startBroadcast();
        StableCoin dsc = new StableCoin();
        DSCEngine engine = new DSCEngine();
        vm.stopBroadcast();
    }
}