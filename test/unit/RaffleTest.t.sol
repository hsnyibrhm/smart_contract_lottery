// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    bytes32 gasLane;
    address vrfCoordinator;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed winner);
}

// Testable wrapper to expose internal fulfillRandomWords for unit testing
contract TestableRaffle is Raffle {
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    )
        Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        )
    {}

    function callFulfill(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external {
        fulfillRandomWords(requestId, randomWords);
    }
}

contract RaffleTestable is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    bytes32 gasLane;
    address vrfCoordinator;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // deploy a testable raffle so we can call fulfillRandomWords directly
        TestableRaffle testable = new TestableRaffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );

        raffle = Raffle(address(testable));

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenNotEnoughETH() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.NOtEnoughETHToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsPlayerEnteredEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit PlayerEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testEmitsWinnerPickedEvent() public {
        address player2 = makeAddr("player2");
        vm.deal(player2, STARTING_PLAYER_BALANCE);

        // PLAYER enters first, then player2
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.prank(player2);
        raffle.enterRaffle{value: entranceFee}();

        vm.expectEmit(true, false, false, false, address(raffle));
        emit WinnerPicked(PLAYER);

        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0; // picks index 0 -> PLAYER
        TestableRaffle(address(raffle)).callFulfill(0, randomWords);
    }

    function testDontAllowPlayersToEnterWhenCalculating() public {
        //Arrange - enter the raffle
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // move time forward so upkeep is needed
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // perform upkeep to change state to calculating
        raffle.performUpkeep("");

        //Act $ Assert - try to enter raffle and expect revert
        vm.expectRevert(Raffle.RaffleNotOpen.selector);

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
}
