# 🎟️ Smart Contract Lottery (Raffle) - [WIP]

> **⚠️ Note: Proyek ini sedang dalam tahap pengembangan.**
> Repo ini saya gunakan sebagai jurnal belajar harian untuk mendalami pengembangan Smart Contract menggunakan Foundry.

Proyek ini bertujuan untuk membangun sistem undian (lottery) yang sepenuhnya terdesentralisasi, otomatis, dan terbukti adil menggunakan infrastruktur Web3.

## 🛠️ Tech Stack (Learning Path)

- **Solidity**: Logika Smart Contract.
- **Foundry**: Framework pengembangan (Forge, Cast, Anvil).
- **Chainlink VRF**: Untuk angka acak yang adil (Verifiable Randomness).
- **Chainlink Automation**: Untuk eksekusi otomatis tanpa intervensi manual.

## 🚀 Fitur yang Sedang Dikembangkan

- [x] Inisialisasi Project & Struktur Folder.
- [x] Inisialisasi Project & Struktur Folder.
- [x] State Variables & Constructor (Entrance Fee).
- [ ] Fungsi `enterRaffle` (Pendaftaran Peserta).
- [x] Integrasi Chainlink VRF (Random Number).
- [ ] Integrasi Chainlink Automation (Auto-pick winner).
- [ ] Unit Testing & Integration Testing.
- [ ] Deployment Script ke Testnet (Sepolia).

## 📂 Struktur Proyek

- `src/`: Kontrak utama (Raffle.sol).
- `test/`: Folder pengujian (akan segera diisi).
- `script/`: Script untuk deployment.

## Layout Of Contract

1. license
2. version
3. imports
4. errors
5. interfaces, libraries, contracts
6. Type declarations
7. State variables
8. Events
9. Modifiers
10. Functions

## Layout Of Functions

1. constructor
2. receive function (if exists)
3. fallback function (if exists)
4. external
5. public
6. internal
7. private
8. internal & private view & pure functions
9. external & public view & pure functions

## ⚙️ Cara Menjalankan (Bagi yang Ingin Cek)

1. Build proyek:
   ```bash
   forge build
   ```

## Tests!

1. Write deploy Scripts
   1. Note, these will not work on zkSync
2. write test
   1. Local Chain
   2. Forked Tesnet
   3. Forked Mainnet
