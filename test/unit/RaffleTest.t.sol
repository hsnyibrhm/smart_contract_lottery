// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    bytes32 gasLane;
    address vrfCoordinator;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        // 1. Jalankan skrip deployer resmi agar mengembalikan instance Raffle dan HelperConfig yang valid
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        // 2. Ambil data konfigurasi jaringan yang aktif
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        gasLane = config.gasLane;
        vrfCoordinator = config.vrfCoordinator;

        // 3. Berikan modal ETH ke player tiruan untuk bahan uji coba
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

    function testDontAllowPlayersToEnterWhenCalculating() public {
        // Arrange - player masuk ke raffle
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Majukan waktu simulator agar syarat durasi penutupan raffle terpenuhi
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Eksekusi performUpkeep untuk mengubah status state Raffle menjadi CALCULATING
        raffle.performUpkeep("");

        // Act & Assert - Player memaksa masuk saat menghitung, harus diblokir (revert)
        vm.expectRevert(Raffle.RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*////////////////////////////////////////////////////////////////*/

    function testCheckUpKeepReturnsFalseIfHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
    }
}

/*////////////////////////////////////////////////////////////////////////////////////////////////////////////*/
// Wrapper khusus diletakkan di bagian paling bawah untuk keperluan pengujian fulfillRandomWords lanjutan nanti
/*////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

contract TestableRaffle is Raffle {
    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    )
        Raffle(
            _entranceFee,
            _interval,
            _vrfCoordinator,
            _gasLane,
            _subscriptionId,
            _callbackGasLimit
        )
    {}

    function callFulfill(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external {
        fulfillRandomWords(requestId, randomWords);
    }
}
