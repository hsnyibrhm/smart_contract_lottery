// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle smart contract
 * @author Hasany ibrohim
 * @dev impelements chainlink VRF v2 to generate random number for raffle winner selection
 * @notice this contract is for creating a sample raffle system, where users can enter the raffle by sending a certain amount of ether, and the contract will randomly select a winner after a specified time period. The winner will receive the total amount of ether collected from the participants.
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /* custome error */
    error NOtEnoughETHToEnterRaffle();
    error TransferFailed();

    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUMWORDS = 1;
    uint256 private immutable i_entranceFee;
    uint32 private immutable i_callbackGasLimit;
    /**
     * @dev durasi lottery dalam detik, misalnya 1 hari = 86400 detik
     */
    uint256 private immutable i_interval;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;

    /* Events */
    event PlayerEntered(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee,"Not enough ETH to enter the raffle");

        /* ini adalah cara yang lebih irit gas dengan require + custome error tapi hanya di vesi 0.8.26 keatas.
        require(msg.value >= i_entranceFee, NOtEnoughETHToEnterRaffle());
        */

        if (msg.value < i_entranceFee) {
            revert NOtEnoughETHToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit PlayerEntered(msg.sender);
    }

    function pickWinner() external {
        if (block.timestamp - s_lastTimeStamp > i_interval) {
            // get current block timestamp
            revert();
        }

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATION,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUMWORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        //s_players akan 10 orang
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        // reset state
        s_recentWinner = recentWinner;
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /* Getter functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
