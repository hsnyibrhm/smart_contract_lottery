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
    /* custom error */
    error NOtEnoughETHToEnterRaffle();
    error TransferFailed();
    error RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(
        uint256 balance,
        uint256 playerslength,
        uint256 raffleState
    );

    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State variables */
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUMWORDS = 1;
    uint256 private immutable i_entranceFee;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_subscriptionId;
    /**
     * @dev durasi lottery dalam detik, misalnya 1 hari = 86400 detik
     */
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    RaffleState private s_raffleState;

    /* Events */
    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_callbackGasLimit = callbackGasLimit;
        i_subscriptionId = subscriptionId;
        i_keyHash = gasLane;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    /* functions */

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee,"Not enough ETH to enter the raffle");

        /* ini adalah cara yang lebih irit gas dengan require + custome error tapi hanya di vesi 0.8.26 keatas.
        require(msg.value >= i_entranceFee, NOtEnoughETHToEnterRaffle());
        */

        if (msg.value < i_entranceFee) {
            revert NOtEnoughETHToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));

        emit PlayerEntered(msg.sender);
    }

    /**
     * @dev fungsi ini akan dipanggil oleh Chainlink Keeper untuk memeriksa apakah kondisi untuk memulai proses pemilihan pemenang sudah terpenuhi,
     * yaitu apakah interval waktu sudah terpenuhi dan apakah ada pemain yang masuk ke dalam raffle.
     * Jika kondisi terpenuhi, maka fungsi ini akan mengembalikan nilai true untuk upkeepNeeded,
     * yang akan memicu pemanggilan fungsi pickWinner oleh Chainlink Keeper.
     * @param - ignored
     * @return upkeepNeeded - boolean yang menunjukkan apakah kondisi untuk memulai proses pemilihan pemenang sudah terpenuhi
     * @return - bytes memory yang tidak digunakan dalam fungsi ini, tetapi diperlukan untuk memenuhi signature dari
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory) {
        bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasbalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = isOpen && timePassed && hasPlayers && hasbalance;
        return (upkeepNeeded, bytes(""));
    }

    /*otomatis akan dipanggil oleh Chainlink Keeper setelah interval waktu terpenuhi, untuk memulai proses pemilihan pemenang*/
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
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

        s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256,
        /*requestId*/
        uint256[] calldata randomWords
    ) internal override {
        //efek internal contract state, jadi tidak perlu validasi requestId karena hanya bisa dipanggil oleh VRF Coordinator
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        /*reset array dan state untuk memulai raffle baru*/
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        /*unteraksu (eksternal contract state)*/
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /* Getter functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
