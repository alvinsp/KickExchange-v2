# ==============================================================================
# KickExchange v2 - Automated GitHub Issues Creator
# ==============================================================================
# Usage:
#   1. Make sure GitHub CLI is authenticated:
#      gh auth login
#   2. Run this script:
#      .\scripts\create_github_issues.ps1
# ==============================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   KickExchange v2 - GitHub Issues Automated Creator      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check if gh CLI is installed
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] GitHub CLI ('gh') is not installed." -ForegroundColor Red
    Write-Host "Please install it from https://cli.github.com/ or run: winget install GitHub.cli" -ForegroundColor Yellow
    exit 1
}

# 2. Check if logged in
gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] You are not logged into GitHub CLI." -ForegroundColor Yellow
    Write-Host "Please log in first by running: gh auth login" -ForegroundColor Green
    Write-Host "Then re-run this script: .\scripts\create_github_issues.ps1" -ForegroundColor Cyan
    exit 1
}

$repo = "alvinsp/KickExchange-v2"
Write-Host "[INFO] Target Repository: $repo" -ForegroundColor Green

$issues = @(
    @{
        Title = "[Core/Architecture] Feature-First Clean Architecture Foundation & Dependency Injection"
        Labels = "architecture,core,enhancement"
        Body = @"
## 📌 Deskripsi Fitur / Fondasi
Membangun fondasi arsitektur **Feature-First Clean Architecture** pada Flutter mobile application untuk memisahkan domain enterprise, data persistence, dan presentation layer dengan prinsip *Inversion of Control* & *Dependency Injection*.

## 🎯 Deliverables & Kriteria Penerimaan
- [x] Struktur direktori `lib/core` (constants, network, theme tokens 8px, error failures/exceptions, usecase base contract).
- [x] Service Locator via `get_it` di `lib/core/di/injection_container.dart`.
- [x] Resilient HTTP Client via `DioClient` dengan network interceptor & logger.
- [x] Secure Storage integration (`flutter_secure_storage`) dengan safe fallback.
- [x] Setup `AppTheme` dengan Google Fonts Outfit & Space Grotesk, 8px spatial rhythm tokens.

## 📁 Referensi File
- `lib/core/`
- `lib/core/di/injection_container.dart`
- `lib/core/network/dio_client.dart`
- `lib/core/theme/app_theme.dart`
"@
    },
    @{
        Title = "[Payment/Fintech] Dynamic QRIS & Bank VA Idempotent Settlement with 3-Digit Verification Suffix"
        Labels = "fintech,payment,security"
        Body = @"
## 📌 Deskripsi Fitur
Implementasi sistem checkout dan gateway pembayaran terintegrasi Xendit & Simulator Lokal dengan dukungan QRIS Dinamis (EMVCo) serta Virtual Account (BCA, Mandiri, BNI, BRI) yang dilengkapi *Idempotency Guard* dan kode unik verifikasi 3 digit (*random suffix*).

## 🎯 Deliverables & Kriteria Penerimaan
- [x] Entitas `TransactionEntity` & `PaymentInfoEntity` dengan status: `PENDING_PAYMENT`, `SETTLED`, `EXPIRED`, `CANCELLED`.
- [x] Algoritma 3-digit unique suffix code (Rp 100 - Rp 999) untuk verifikasi transfer bank manual & VA.
- [x] Header `Idempotency-Key` (UUIDv4) pada setiap request transaksi untuk mencegah *double-charging* dan *double-spend*.
- [x] Countdown timer real-time (15 menit untuk QRIS, 24 jam untuk Virtual Account).
- [x] Simulator & Webhook Settlement handler di backend API (`/api/v1/payments/simulate-settlement`).

## 📁 Referensi File
- `lib/features/transactions/`
- `api/src/routes/paymentRoutes.js`
- `api/src/services/paymentService.js`
"@
    },
    @{
        Title = "[Offline/Sync] SQLite Offline-First Engine & Background Mutex Synchronization Queue"
        Labels = "database,offline-first,sync"
        Body = @"
## 📌 Deskripsi Fitur
Engine penyimpanan lokal berbasis SQLite relasional dengan antrean sinkronisasi offline (`sync_queue`) yang menjamin pengguna dapat melakukan browsing katalog, menyimpan penawaran barter, dan membuat pesanan saat offline tanpa kehilangan data.

## 🎯 Deliverables & Kriteria Penerimaan
- [x] `AppDatabase` dengan tabel: `users`, `products`, `trades`, `transactions`, dan `sync_queue`.
- [x] Cross-platform compatibility (Android, iOS, Windows, macOS, Web via `sqflite_common_ffi_web`).
- [x] `SyncBloc` dengan `bloc_concurrency: droppable()` / Mutex Lock untuk mencegah *race condition* saat berpindah jaringan.
- [x] Exponential backoff retry counter (`retry_count`) pada antrean transaksi yang tertunda.
- [x] Visual offline indicator banner saat perangkat terputus dari internet.

## 📁 Referensi File
- `lib/core/database/app_database.dart`
- `lib/features/sync/presentation/bloc/sync_bloc.dart`
- `lib/features/sync/presentation/widgets/offline_indicator_banner.dart`
"@
    },
    @{
        Title = "[Trade/Barter] Sneaker Barter System with Dynamic Cash Adjustment Settlement"
        Labels = "feature,marketplace,trade"
        Body = @"
## 📌 Deskripsi Fitur
Fitur pertukaran sepatu (Barter/Trade) sneaker-to-sneaker yang dilengkapi kalkulasi kompensasi selisih nilai pasar (*cash adjustment / diff*) secara otomatis dan transparan.

## 🎯 Deliverables & Kriteria Penerimaan
- [x] Entitas `TradeEntity` & kalkulasi kompensasi nilai selisih (`cashAdjustment = targetProduct.price - offeredProduct.price`).
- [x] Status trade lifecycle: `PENDING`, `ACCEPTED`, `REJECTED`, `NEGOTIATING`, `CANCELLED`.
- [x] Formulir pengajuan trade dengan foto kondisi sneaker, ukuran sepatu, dan catatan penawaran.
- [x] Integrasi pembayaran otomatis jika ada kekurangan tunai (*cash top-up required*).
- [x] Unit test komprehensif untuk `SubmitTradeOfferUseCase` dan `CalculateTradeDiffUseCase`.

## 📁 Referensi File
- `lib/features/trade/domain/entities/trade_entity.dart`
- `lib/features/trade/domain/usecases/submit_trade_offer_usecase.dart`
- `lib/features/trade/presentation/bloc/trade_bloc.dart`
"@
    },
    @{
        Title = "[Security/Compliance] UU PDP Personal Data Protection & PII Masking Implementation"
        Labels = "compliance,security,uu-pdp"
        Body = @"
## 📌 Deskripsi Fitur
Kepatuhan privasi data sesuai Undang-Undang Perlindungan Data Pribadi (UU PDP No. 27 Tahun 2022) dengan mekanisme masking PII (*Personally Identifiable Information*) pada seluruh layer aplikasi & log backend.

## 🎯 Deliverables & Kriteria Penerimaan
- [x] `PiiMasker` utilitas: Masking nomor telepon (`0812****8901`), email (`jo***@domain.com`), dan nomor rekening/VA (`1234 **** **** 7890`).
- [x] Penyimpanan token JWT, refresh token, dan database encryption key pada platform native Keystore/Keychain.
- [x] Parameterized SQL Queries (`?`) untuk mencegah SQL Injection pada layer SQLite.
- [x] Header sanitization & masking pada HTTP request/response logger.

## 📁 Referensi File
- `lib/core/security/pii_masker.dart`
- `lib/core/security/secure_storage_helper.dart`
- `api/src/routes/authRoutes.js`
"@
    },
    @{
        Title = "[Backend/API] Lightweight Node.js REST API with SQLite WAL Mode & Webhook Dispatcher"
        Labels = "backend,api,nodejs"
        Body = @"
## 📌 Deskripsi Fitur
Penyediaan backend REST API mandiri berbasis Node.js murni (Express + `node:sqlite` WAL mode) untuk melayani sinkronisasi katalog sepatu, otentikasi JWT, kalkulasi barter, dan simulator payment gateway.

## 🎯 Deliverables & Kriteria Penerimaan
- [x] Endpoints Auth: `/api/v1/auth/register`, `/api/v1/auth/login`, `/api/v1/auth/me`.
- [x] Endpoints Products: `/api/v1/products` (Search, Filter, Detail, Category).
- [x] Endpoints Trade: `/api/v1/trades` (Submit offer, List user trades, Update status).
- [x] Endpoints Payments: `/api/v1/payments/create-qris`, `/api/v1/payments/create-va`, `/api/v1/payments/webhook`, `/api/v1/payments/simulate-settlement`.
- [x] Unit/Integration tests: 6/6 test suites passing via `npm test`.

## 📁 Referensi File
- `api/src/server.js`
- `api/src/db/database.js`
- `api/src/db/seed.js`
- `api/tests/api.test.js`
"@
    }
)

foreach ($issue in $issues) {
    Write-Host "[CREATING] $($issue.Title)..." -ForegroundColor Yellow
    gh issue create --repo $repo --title $issue.Title --body $issue.Body --label $issue.Labels
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  -> [SUCCESS] Created successfully!" -ForegroundColor Green
    } else {
        Write-Host "  -> [FAILED] Could not create issue via CLI." -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 500
}

Write-Host "`nAll issues processed!" -ForegroundColor Cyan
