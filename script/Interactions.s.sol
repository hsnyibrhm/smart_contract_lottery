// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subId, ) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256, address) {
        // create subscription
        console.log("Creating subscription...", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log("Subscription created with ID:", subId);
        console.log(
            "update the subscription ID in your contract in helperconfig.s.sol..."
        );
        return (subId, vrfCoordinator);
    }
}

contract FundSubscription is Script, CodeConstants {
    // Increase fund amount to ensure mock coordinator can cover payment calculations
    uint96 public constant FUND_AMOUNT = 1000000 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken,
        address account
    ) public {
        // fund subscription
        console.log("Funding subscription...", subscriptionId);
        console.log("Using VRF Coordinator at:", vrfCoordinator);
        // console.log("Using LINK token at:", linkToken);
        console.log("On chainid:", block.chainid);

        if (block.chainid == LOCAL_CHAINID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            // For testnet/mainnet, we need to use the LINK token to fund the subscription
            console.log("Funding subscription with LINK token...");
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer(
        address contractToAddtoVrf,
        address vrfCoordinator,
        uint256 subId,
        address account
    ) public {
        console.log("Adding consumer...", contractToAddtoVrf);
        console.log("Using VRF Coordinator at:", vrfCoordinator);
        console.log("On chainid:", block.chainid);

        vm.startBroadcast(account);
        // Try to add consumer; if subscription is invalid, create and fund a new subscription then add
        try
            VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
                subId,
                contractToAddtoVrf
            )
        {
            // added successfully
        } catch {
            // create a new subscription owned by the broadcaster and fund it
            uint256 newSubId = VRFCoordinatorV2_5Mock(vrfCoordinator)
                .createSubscription();
            // fund with a large enough amount for tests
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                newSubId,
                100 ether
            );
            VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
                newSubId,
                contractToAddtoVrf
            );
        }
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
