# KickExchange v2 👟🔄
### Enterprise Re-Engineered Sneaker Marketplace: Buy, Sell, and Trade (Barter)
*Powered by Feature-First Clean Architecture, BLoC State Management, Offline-First SQLite Engine, and Idempotent Payments (Dynamic QRIS & Bank VA)*

[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-brightgreen.svg)](#)
[![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-blue.svg)](#)
[![Dart](https://img.shields.io/badge/Dart-3.4%2B-blue.svg)](#)
[![Node.js](https://img.shields.io/badge/Node.js-22.13%2B%20ESM-green.svg)](#)
[![Payment](https://img.shields.io/badge/Payment-Xendit%20%26%20Simulator-orange.svg)](#)
[![UU PDP](https://img.shields.io/badge/Compliance-UU%20PDP%20PII%20Masking-blueviolet.svg)](#)

---

## 📌 Daftar Isi
1. [Ringkasan Eksekutif & Analisis Komparatif (v1 vs v2)](#1-ringkasan-eksekutif--analisis-komparatif-v1-vs-v2)
2. [Ekosistem & Arsitektur Teknologi](#2-ekosistem--arsitektur-teknologi)
3. [Fitur Utama: Trinitas Sneakerhead](#3-fitur-utama-trinitas-sneakerhead)
   - [3.1 Beli Langsung (Direct Purchase)](#31-beli-langsung-direct-purchase)
   - [3.2 Jual Sneaker (Listing Inventori)](#32-jual-sneaker-listing-inventori)
   - [3.3 Barter / Tukar Tambah (Trade with Cash Adjustment)](#33-barter--tukar-tambah-trade-with-cash-adjustment)
4. [Sistem Transaksi, Idempotensi & 3-Digit Verification Code](#4-sistem-transaksi-idempotensi--3-digit-verification-code)
5. [Mesin Offline-First & Sinkronisasi Latar Belakang (Sync Queue)](#5-mesin-offline-first--sinkronisasi-latar-belakang-sync-queue)
6. [Keamanan Data & Kepatuhan UU PDP (Indonesia)](#6-keamanan-data--kepatuhan-uu-pdp-indonesia)
7. [Struktur Direktori Komprehensif](#7-struktur-direktori-komprehensif)
   - [7.1 Flutter Mobile App (`/app`)](#71-flutter-mobile-app-app)
   - [7.2 Node.js REST API (`/api`)](#72-nodejs-rest-api-api)
8. [Panduan Menjalankan Sistem (Getting Started)](#8-panduan-menjalankan-sistem-getting-started)
   - [8.1 Menjalankan Backend API](#81-menjalankan-backend-api)
   - [8.2 Menjalankan Mobile App Flutter](#82-menjalankan-mobile-app-flutter)
9. [Hasil Pengujian Otomatis (Test Suite)](#9-hasil-pengujian-otomatis-test-suite)

---

## 1. Ringkasan Eksekutif & Analisis Komparatif (v1 vs v2)

KickExchange v2 merupakan perancangan ulang total (*total re-engineering*) dari repositori legasi [alvinsp/KickExchange](https://github.com/alvinsp/KickExchange). Arsitektur lama yang berbasis MVC monolitik dan UI dependen telah dirombak menjadi **Feature-First Clean Architecture** dengan pemisahan tanggung jawab yang independen:

| Parameter Arsitektural | KickExchange v1 (Legacy) | KickExchange v2 (Re-Engineered) |
| :--- | :--- | :--- |
| **Pola Arsitektur** | Flat MVC tanpa pemisahan domain layer. Controller langsung memanipulasi HTTP Dio dan mutable UI. | **Feature-First Clean Architecture** (Domain, Data, Presentation) dengan Inversion of Control & Dependency Injection (`get_it`). |
| **State Management** | Multi-Provider sederhana tanpa finite-state safety. Rawan memory leaks dan race condition. | **BLoC (Business Logic Component)** berbasis event streams immutable dengan transformer `bloc_concurrency: droppable()`. |
| **Penyimpanan Lokal** | Hanya `shared_preferences` untuk menyimpan session mentah. Tidak ada database relasional lokal. | **SQLite (sqflite / sqflite_common_ffi)** dengan tabel terindeks, transaction savepoints, dan `sync_queue`. |
| **Kemampuan Offline** | Aplikasi crash atau blank saat sinyal terputus. Tidak ada mekanisme antrean lokal. | **Full Offline-First Engine**. Transaksi, katalog, dan penawaran tukar disimpan lokal dan tersinkronisasi otomatis saat online. |
| **Fitur Bisnis** | Jual & Beli katalog standar tanpa mekanisme barter/trade. | **Trinitas Sneaker: Buy, Sell, and Trade (Barter)** dilengkapi kalkulasi penyesuaian selisih tunai (*cash adjustment*). |
| **Sistem Pembayaran** | Mockup statis tanpa payment gateway nyata. | **Dual-Mode Payment Gateway (Xendit)**: Dynamic QRIS & Virtual Account (BCA, Mandiri, BNI, BRI) + Local Simulator instant settlement. |
| **Pencegahan Double-Spend** | Tidak ada proteksi jaringan. Re-submit form bisa menghasilkan dobel order. | **Unique Nonce & Idempotency Key** (`IDEM-TRX-...`) + **3-Digit Verification Suffix** acak (Rp 100 - 999). |
| **Keamanan Data** | Plaintext session token, data PII sensitif terekspos tanpa enkripsi. | **AES-256 Storage & Keystore/Keychain Ready**, Token JWT HS256, PII Masking (UU PDP) untuk rekening, no. HP, dan email. |

---

## 2. Ekosistem & Arsitektur Teknologi

```
KickExchange v2
├── Mobile Client (Flutter 3.22+ / Dart 3.4+)
│   ├── Presentation: flutter_bloc ^8.1.6, Google Fonts Outfit, qr_flutter ^4.1.0
│   ├── Domain: dartz ^0.10.1 (Either<Failure, Success>), Pure Entities & Use Cases
│   ├── Data: sqflite & sqflite_common_ffi, dio ^5.4.3, flutter_secure_storage
│   └── Dependency Injection: get_it ^7.7.0
│
└── Backend Server (Node.js 22.13+ ESM Native)
    ├── Framework: Express.js 4.21+
    ├── Database: node:sqlite (native synchronous SQLite with WAL mode & Foreign Keys)
    ├── Validation: Zod schemas dengan sanitasi input anti-injection
    ├── Security: jsonwebtoken (JWT HS256), crypto (SHA-256 idempotency hash, UU PDP masking)
    └── Payment Provider: Dual-Mode (Xendit REST API & Local EMVCo Dynamic QRIS/VA Simulator)
```

---

## 3. Fitur Utama: Trinitas Sneakerhead

### 3.1 Beli Langsung (Direct Purchase)
- Katalog sneaker terlengkap dengan filter instan berdasarkan brand (Nike, Jordan, Adidas, New Balance, Salomon, Asics, Converse), ukuran US, rentang harga, dan kondisi.
- Informasi produk transparan mencakup grading kondisi: `BNIB` (*Brand New In Box*), `BNWD` (*Brand New With Defect*), `USED_VERY_GOOD` (*VNDS*), dan `USED_GOOD`.
- Struk pesanan mencakup data penjual terverifikasi dengan proteksi masking PII.

### 3.2 Jual Sneaker (Listing Inventori)
- Pasang sepatu baru dalam hitungan detik dengan dukungan mode **Offline-First**. Jika pengguna berada di area tanpa sinyal, listing tersimpan di SQLite lokal dan otomatis dipublikasikan begitu koneksi terdeteksi.
- Fleksibilitas transaksi: Penjual dapat membuka opsi **Dijual Langsung**, **Barter / Trade**, atau keduanya sekaligus.

### 3.3 Barter / Tukar Tambah (Trade with Cash Adjustment)
- Pengguna dapat mengajukan tukar tambah sneaker miliknya dengan sneaker target pengguna lain.
- **Kalkulasi Selisih Tunai (*Cash Adjustment*)**:
  - `Cash Diff > 0`: Penawar membayar uang tambahan ke pemilik sepatu target.
  - `Cash Diff < 0`: Pemilik sepatu target membayar selisih ke penawar.
  - `Cash Diff = 0`: Tukar lepas (*Even Trade*).
- Manajemen tawaran lengkap: Penerima dapat memilih **Terima Tawaran** atau **Tolak**, sedangkan pengirim dapat melakukan **Batalkan Tawaran**.
- Jika tawaran barter disetujui dan terdapat selisih uang, aplikasi secara cerdas menampilkan tombol pembayaran tagihan yang terhubung langsung ke gateway transaksi.

---

## 4. Sistem Transaksi, Idempotensi & 3-Digit Verification Code

Untuk menjamin kepatuhan enterprise-grade fintech dan mencegah *double-spending*:

```
[ Pengguna Menekan Checkout ]
         │
         ├── 1. Generate Idempotency Key: IDEM-TRX-{timestamp}-{randomPart}
         ├── 2. Generate 3-Digit Unique Verification Code: (cth: Rp 3.500.000 + 419 = Rp 3.500.419)
         ├── 3. Simpan Transaksi di SQLite Lokal (Status: PENDING_PAYMENT, is_synced: 0)
         │
         ▼
[ Jaringan Online ] ──► POST /api/v1/transactions (Header: X-Idempotency-Key)
         │
         ├─────────────────────────────────────────────────┐
         │ Server memeriksa Idempotency Key di Database    │
         ├─────────────────────────────────────────────────┤
         │ KEY PERNAH DIPROSES?                            │
         │ - YA: Kembalikan cached response (NO-OP)        │
         │ - TIDAK: Buat tagihan Xendit / Simulator QRIS/VA│
         └─────────────────────────────────────────────────┘
         │
         ▼
[ Halaman Pembayaran (PaymentDetailPage) ]
         ├── QRIS Dinamis (Rendered via qr_flutter dengan validasi CRC16 EMVCo)
         ├── Bank Virtual Account (BCA, Mandiri, BNI, BRI) dengan 1-Tap Salin Nomor VA
         ├── Countdown Timer 15 Menit
         └── Tombol "SIMULASI BAYAR SEKARANG" untuk Instant Settlement Sandbox
```

---

## 5. Mesin Offline-First & Sinkronisasi Latar Belakang (Sync Queue)

KickExchange v2 mengimplementasikan paradigma **Offline-First / Cache-First**:
1. Setiap mutasi data (pembuatan listing, tawaran barter, pembuatan transaksi) terlebih dahulu disimpan ke database lokal SQLite dan diberi tanda `is_synced = 0`.
2. Jika perangkat sedang luring (*offline*), mutasi didaftarkan ke tabel `sync_queue` dengan payload JSON deterministik.
3. Banner mengambang `SyncStatusBanner` menginformasikan jumlah antrean yang belum tersinkronisasi.
4. Ketika koneksi internet pulih, `SyncBloc` secara atomik mengeksekusi sinkronisasi antrean via batch sync endpoint `/api/v1/sync/batch`.

---

## 6. Keamanan Data & Kepatuhan UU PDP (Indonesia)

Sistem mematuhi regulasi perlindungan data pribadi (UU PDP):
- **Nomor Rekening**: Disamarkan menjadi `5391 **** **** 8821`
- **Nomor Handphone**: Disamarkan menjadi `0812-****-4912`
- **Alamat Email**: Disamarkan menjadi `al***@example.com`
- **Database Lokal**: SQLite dienkripsi dan token JWT disimpan dalam secure storage (Android Keystore / iOS Keychain).

---

## 7. Struktur Direktori Komprehensif

### 7.1 Flutter Mobile App (`/app`)
```
app/
├── lib/
│   ├── app.dart                                # MultiBlocProvider & AppRootNavigator
│   ├── main.dart                               # Inversion of Control & entrypoint
│   ├── main_navigation_shell.dart              # BottomNavigationBar (Katalog, Barter, Transaksi, Profil)
│   ├── injection_container.dart                # GetIt Service Locator Dependency Injection
│   │
│   ├── core/
│   │   ├── constants/                          # AppColors (Dark Sneakerhead), AppDimens (8px grid)
│   │   ├── database/                           # AppDatabase (Cross-platform SQLite & FFI)
│   │   ├── errors/                             # Exceptions & Failures
│   │   ├── network/                            # DioClient (Bearer JWT interceptor) & NetworkInfo
│   │   ├── security/                           # DataMasking & SecureStorageHelper
│   │   ├── theme/                              # AppTheme (Dark Minimalist Outfit Typography)
│   │   ├── usecase/                            # Generic contract UseCase<Type, Params>
│   │   └── utils/                              # CurrencyFormatter (IDR) & DateFormatter
│   │
│   └── features/
│       ├── auth/                               # Otentikasi, Login, Register, Profile, PII Masking
│       ├── products/                           # Katalog Sneaker, Filter, Detail, Add/Edit Listing
│       ├── trade/                              # Tawaran Barter (Incoming/Outgoing), Cash Adjustment
│       ├── transactions/                       # Checkout, Payment Detail (QRIS/VA), Order History
│       └── sync/                               # Offline Sync Queue Engine & Status Banner
```

### 7.2 Node.js REST API (`/api`)
```
api/
├── package.json                                # Node.js >=22.13.0 ESM scripts
├── src/
│   ├── app.js                                  # Express setup, middleware, route mounting
│   ├── server.js                               # HTTP Server entrypoint (Port 3000)
│   ├── config/env.js                           # Environment config & dynamic JWT fallback
│   ├── db/
│   │   ├── database.js                         # node:sqlite WAL mode & transaction runner
│   │   ├── schema.js                           # DDL: users, products, trades, transactions, idempotency
│   │   └── seed.js                             # Seed 3 users dan 5 sneaker otentik
│   ├── middlewares/                            # auth.js, errorHandler.js, idempotency.js
│   ├── utils/                                  # codes.js (CRC16, 3-digit suffix), masking.js
│   ├── validation/schemas.js                   # Strict Zod validation schemas
│   └── modules/
│       ├── auth/                               # Registrasi, Login, Profile
│       ├── products/                           # REST CRUD Sneakers & Optimistic Concurrency
│       ├── trades/                             # REST Barter & Settlement
│       ├── transactions/                       # Checkout, 3-Digit Suffix Code, Verification
│       ├── payments/                           # Xendit QRIS / VA Provider & Simulator Settlement
│       └── sync/                               # Offline-to-Online Batch Sync
└── test/
    └── api.test.js                             # Comprehensive 6-suite Integration Tests
```

---

## 8. Panduan Menjalankan Sistem (Getting Started)

### 8.1 Menjalankan Backend API
Prasyarat: Node.js versi `>= 22.13.0`

```bash
# 1. Masuk ke direktori backend
cd e:/projects/kick-exchange-v2/api

# 2. Pasang dependensi
npm install

# 3. Jalankan seeding database awal (3 user & 5 sneaker)
npm run seed

# 4. Jalankan pengujian integrasi (API Integration Tests)
npm test

# 5. Jalankan server backend (Port 3000)
npm run dev
```

*Server API akan berjalan pada `http://localhost:3000/api/v1`.*

### 8.2 Menjalankan Mobile App Flutter
Prasyarat: Flutter SDK versi `>= 3.22.0`

```bash
# 1. Masuk ke direktori mobile app
cd e:/projects/kick-exchange-v2/app

# 2. Unduh dependensi Flutter
flutter pub get

# 3. Jalankan linter dan analisis kode Clean Architecture
flutter analyze

# 4. Jalankan pengujian unit (Unit Tests)
flutter test

# 5. Jalankan aplikasi pada emulator atau perangkat fisik
flutter run
```

---

## 9. Hasil Pengujian Otomatis (Test Suite)

### Backend API (`npm test`)
```
✔ Health check returns ok
✔ User registration and login flow
✔ Catalog search and filter
✔ Idempotent product creation
✔ Checkout with 3-digit unique verification code and settlement
✔ Batch offline synchronization processes pending mutations
ℹ tests 6
ℹ pass 6
ℹ fail 0
```

### Flutter Mobile App (`flutter test` & `flutter analyze`)
```
Analyzing app...
No issues found! (ran in 4.8s)

00:01 +6: All tests passed!
```

---
*Dikembangkan dengan standar arsitektur perangkat lunak enterprise untuk KickExchange v2.*
