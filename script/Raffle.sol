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

/**
 * @title Raffle smart contract
 * @author Hasany ibrohim
 * @dev impelements chainlink VRF v2 to generate random number for raffle winner selection
 * @notice this contract is for creating a sample raffle system, where users can enter the raffle by sending a certain amount of ether, and the contract will randomly select a winner after a specified time period. The winner will receive the total amount of ether collected from the participants.
 */

contract Raffle {
    /* custome error */
    error NOtEnoughETHToEnterRaffle();

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    /**
     * @dev durasi lottery dalam detik, misalnya 1 hari = 86400 detik
     */
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    /* Events */
    event PlayerEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
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

    function pickWinner() external view {
        if (block.timestamp - s_lastTimeStamp > i_interval) {
            // get current block timestamp
            revert();
        }
    }

    /* Getter functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
