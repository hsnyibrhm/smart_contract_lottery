// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

abstract contract CodeConstants {
    /* VRF Mock values */
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9; // 0.000
    //LINK / ETH Price
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;

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
        if (networkConfigs[chainid].vrfCoordinator != address(0)) {
            NetworkConfig memory config = networkConfigs[chainid];
            return config;
        } else if (chainid == LOCAL_CHAINID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
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

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK
        );
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            gasLane: bytes32(
                0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be
            ), // TODO: update with actual gas lane
            vrfCoordinator: address(vrfCoordinatorV2Mock), // TODO: update with actual VRF coordinator address
            callbackGasLimit: 200000,
            subscriptionId: 0 // TODO: update with actual subscription id
        });

        return localNetworkConfig;
    }
}
