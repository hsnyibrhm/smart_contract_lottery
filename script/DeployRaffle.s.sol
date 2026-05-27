// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {console} from "forge-std/console.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployRaffle is Script {
    function run() public returns (Raffle, HelperConfig) {
        return DeployContract();
    }

    function DeployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        //lokal -> deploy mock, get local config
        //testnet -> get testnet config
        //sepolia -> get sepoli config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        // If subscriptionId is zero or invalid for this coordinator, create and fund a new one
        bool needNewSub = false;
        if (config.subscriptionId == 0) {
            needNewSub = true;
        } else {
            // try to read the subscription; if it reverts it's invalid
            try
                VRFCoordinatorV2_5Mock(config.vrfCoordinator).getSubscription(
                    config.subscriptionId
                )
            returns (uint96, uint96, uint64, address, address[] memory) {
                // subscription exists
            } catch {
                needNewSub = true;
            }
        }

        if (needNewSub) {
            CreateSubscription createsub = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createsub
                .createSubscription(config.vrfCoordinator, config.account);

            // fund subscription
            FundSubscription fundsub = new FundSubscription();
            fundsub.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.link,
                config.account
            );
        }
        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // Tidak perlu strart broadcast karena sudah ada di addcunsumer
        AddConsumer addconsumer = new AddConsumer();
        addconsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId,
            config.account
        );

        return (raffle, helperConfig);
    }
}
