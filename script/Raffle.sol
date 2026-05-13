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

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee,"Not enough ETH to enter the raffle");

        /* ini adalah cara yang lebih irit gas dengan require + custome error tapi hanya di vesi 0.8.26 keatas.
        require(msg.value >= i_entranceFee, NOtEnoughETHToEnterRaffle());
        */

        if (msg.value < i_entranceFee) {
            revert NOtEnoughETHToEnterRaffle();
        }
    }

    function pickWinner() public {}

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
