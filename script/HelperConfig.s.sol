//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

// Error if the network is not supported
error HelperConfig__UnsupportedNetwork(uint256 chainid);

contract HelperConfig is Script {
    struct NetworkConfig {
        address priceFeedAddress;
    }

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 18;
    int256 public constant INITIAL_PRICE = 2000e8; // 2000 USD

    constructor() {
        if (block.chainid == 11155111) {
            //Sepolia
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 260) {
            //ZkSync Sepolia
            activeNetworkConfig = getZkSyncSepoliaConfig();
        } else if (block.chainid == 31337) {
            // Localhost
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        } else {
            // Unsupported network
            revert HelperConfig__UnsupportedNetwork(block.chainid);
        }
    }

    // Use chainlink price feed address to convert ETH/USD
    /*
        Network: Sepolia Testnet
        Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
    */
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig =
            NetworkConfig({priceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    /*
        Network: ZKSync Sepolia Testnet
        Address: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF
    */
    function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory zkSyncConfig =
            NetworkConfig({priceFeedAddress: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF});
        return zkSyncConfig;
    }

    //Simulate the Sepolia testnet on localhost
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //Check if there is an instance of anvil running, if yes, use it
        // and don't create a new one.
        if (activeNetworkConfig.priceFeedAddress != address(0)) {
            return activeNetworkConfig;
        }
        // Otherwise, create a new instance of anvil
        // and deploy the mock price feed contract.
        vm.startBroadcast();
        // Deploy mocks
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({priceFeedAddress: address(mockV3Aggregator)});

        // Return mock address
        return anvilConfig;
    }
}
