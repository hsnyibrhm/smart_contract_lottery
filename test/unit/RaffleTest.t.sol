// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
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

    /// to do list
    // test checkupkeep returns false if enough time has passed
    // test checkupkeep returns true when parameters are good

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange - player masuk ke raffle
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Majukan waktu simulator agar syarat durasi penutupan raffle terpenuhi
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act & Assert - checkUpkeep harus mengembalikan false karena status bukan OPEN
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Act & Assert - checkUpkeep harus mengembalikan false karena tidak ada pemain yang masuk
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpkeepNotNeeded.selector,
                address(raffle).balance,
                0,
                uint256(Raffle.RaffleState.OPEN)
            )
        );
        raffle.performUpkeep("");
    }

    // ==========================================
    // PENJELASAN MODIFIER:
    // 1. Berfungsi sebagai awalan untuk menyaring akses ke sebuah fungsi.
    // 2. Digunakan untuk validasi kondisi tertentu (misal: mengecek kecukupan dana, status kontrak, atau hak akses penembak fungsi).
    // 3. Menghindari duplikasi kode (DRY - Don't Repeat Yourself) agar fungsi-fungsi tidak perlu menulis ulang logika 'require' atau 'if' yang sama.
    // 4. Simbol `_;` (merge wildcard) adalah instruksi bagi Solidity untuk melanjutkan eksekusi ke baris kode utama di dalam fungsi setelah syarat modifier lolos.
    // ==========================================
    modifier enteredRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Majukan waktu simulator agar syarat durasi penutupan raffle terpenuhi
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepChangesRaffleStateAndEmitsRequestId()
        public
        enteredRaffle
    {
        // // Arrange - player masuk ke raffle
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();

        // // Majukan waktu simulator agar syarat durasi penutupan raffle terpenuhi
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);

        // Act & Assert - checkUpkeep harus mengembalikan false karena status bukan OPEN
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    function testFulfillRandomWordsCanOnlyRunAfterPerformUpkeep(
        uint256 requestId
    ) public enteredRaffle {
        // Act & Assert - fulfillRandomWords harus mengembalikan false karena belum ada requestId yang valid
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsTheRaffleAndSendsMoney()
        public
        enteredRaffle
    {
        // Arrange

        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1; // karena PLAYER sudah masuk di index 0
        address expectedWinner = address(uint160(1)); // pemain kedua yang masuk akan menjadi pemenang karena requestId yang dihasilkan oleh performUpkeep akan selalu 1 (karena hanya ada satu pemain yang masuk saat performUpkeep dipanggil)
        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        vm.deal(address(raffle), entranceFee * (additionalEntrants + 1));
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        //act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        //assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerEndingBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerEndingBalance == (1 ether - entranceFee) + prize);
        assert(endingTimeStamp > startingTimeStamp);
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
