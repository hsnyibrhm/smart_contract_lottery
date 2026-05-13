# 🎟️ Smart Contract Lottery (Raffle) - [WIP]

> **⚠️ Note: Proyek ini sedang dalam tahap pengembangan.**
> Repo ini saya gunakan sebagai jurnal belajar harian untuk mendalami pengembangan Smart Contract menggunakan Foundry.

Proyek ini bertujuan untuk membangun sistem undian (lottery) yang sepenuhnya terdesentralisasi, otomatis, dan terbukti adil menggunakan infrastruktur Web3.

## 🛠️ Tech Stack (Learning Path)
* **Solidity**: Logika Smart Contract.
* **Foundry**: Framework pengembangan (Forge, Cast, Anvil).
* **Chainlink VRF**: Untuk angka acak yang adil (Verifiable Randomness).
* **Chainlink Automation**: Untuk eksekusi otomatis tanpa intervensi manual.

## 🚀 Fitur yang Sedang Dikembangkan
- [x] Inisialisasi Project & Struktur Folder.
- [x] Inisialisasi Project & Struktur Folder.
- [x] State Variables & Constructor (Entrance Fee).
- [ ] Fungsi `enterRaffle` (Pendaftaran Peserta).
- [ ] Integrasi Chainlink VRF (Random Number).
- [ ] Integrasi Chainlink Automation (Auto-pick winner).
- [ ] Unit Testing & Integration Testing.
- [ ] Deployment Script ke Testnet (Sepolia).

## 📂 Struktur Proyek
- `src/`: Kontrak utama (Raffle.sol).
- `test/`: Folder pengujian (akan segera diisi).
- `script/`: Script untuk deployment.



## ⚙️ Cara Menjalankan (Bagi yang Ingin Cek)
1. Build proyek:
   ```bash
   forge build