//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function fund(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        console.log("FundMe was funded with $s", SEND_VALUE);
        vm.stopBroadcast();
    }

    function run() external {
        vm.startBroadcast();
        address contractAddress = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fund(contractAddress);
        vm.stopBroadcast();
    }
}

contract WithdrawFundMe is Script {
    function withdraw(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("FundMe was withdrawn");
    }

    function run() external {
        vm.startBroadcast();
        address contractAddress = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdraw(contractAddress);
        vm.stopBroadcast();
    }
}
