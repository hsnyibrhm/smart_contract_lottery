// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant LOCAL_CHAINID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        bytes32 gasLane;
        address vrfCoordinator;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainid => NetworkConfig) public networkConfigs;

    constructor() {
        /*localNetworkConfig = NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 30,
            subscriptionId: 0,
            callbackGasLimit: 200000,
            gasLane: bytes32(0),
            vrfCoordinator: address(0)
        }); */

        networkConfigs[SEPOLIA_CHAINID] = getSepoliaEthConfig();
        //networkConfigs[LOCAL_CHAINID] = getLocalEthConfig();
    }

    function getConfigByChainId(
        uint256 chainid
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[block.chainid].vrfCoordinator != address(0)) {
            return networkConfigs[block.chainid];
        } else if (chainid == LOCAL_CHAINID) {
            //getOrCreateAnvilConfig();
        } else {
            revert("Network config not found for the current chain id");
        }
    }

    function getSepoliaEthConfig() public returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                gasLane: bytes32(
                    0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be
                ), // TODO: update with actual gas lane
                vrfCoordinator: address(
                    0x5CE8D5A2BC84beb22a398CCA51996F7930313D61
                ), // TODO: update with actual VRF coordinator address
                callbackGasLimit: 200000,
                subscriptionId: 0 // TODO: update with actual subscription id
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //check to see if set an active NetwokConfig, if not, create one
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
    }
}
