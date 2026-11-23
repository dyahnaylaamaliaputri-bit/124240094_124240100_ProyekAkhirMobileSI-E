# 🎬 Cinemate — Aplikasi Pemesanan Tiket Bioskop Berbasis AI

> **Proyek Mobile Programming — Flutter/Dart**  
> Referensi: SRS-CNM-001 · PB-CNM-001 · Modul II–VII

---

## 📋 Daftar Isi

1. [Tentang Proyek](#tentang-proyek)
2. [Setup Lingkungan Pengembangan](#setup-lingkungan-pengembangan)
3. [Konfigurasi API Keys](#konfigurasi-api-keys)
4. [Arsitektur Proyek](#arsitektur-proyek)
5. [Fitur yang Sudah Selesai](#fitur-yang-sudah-selesai)
6. [⚠️ Tugas Selanjutnya (4 PB Tersisa)](#tugas-selanjutnya)
7. [Panduan Kontribusi](#panduan-kontribusi)
8. [Troubleshooting](#troubleshooting)

---

## Tentang Proyek

**Cinemate** adalah aplikasi pemesanan tiket bioskop berbasis Flutter dengan fitur AI (rekomendasi film berdasarkan mood, chatbot asisten, dan split bill). Dibangun di atas:

| Layer | Teknologi |
|---|---|
| State Management | GetX (`GetxController`, `Obx`, `Bindings`) |
| Database Cloud | Supabase (Custom Auth di tabel `public.users`) |
| Database Lokal | Hive + GetStorage + flutter_secure_storage |
| HTTP Client | Dio (interceptor, timeout, retry) |
| Data Film Real-time | TMDB API v3 (Now Playing + Coming Soon) |
| Peta | Flutter Map + OpenStreetMap |
| Notifikasi | flutter_local_notifications (immediate + scheduled) |
| AI/LLM | Abstraksi `LlmService` (OpenRouter/Gemini) |

---

## Setup Lingkungan Pengembangan

### Prasyarat

```bash
flutter --version   # Butuh Flutter >= 3.19.0
dart --version      # Butuh Dart >= 3.3.0
```

### Langkah Setup

```bash
# 1. Clone repository
git clone <URL_REPO> && cd Cinemate

# 2. Install dependencies
flutter pub get

# 3. Generate Hive TypeAdapters (wajib setelah pull pertama)
dart run build_runner build --delete-conflicting-outputs

# 4. Salin file environment
cp assets/.env.example assets/.env
# Lalu isi API keys di assets/.env (lihat bagian Konfigurasi)

# 5. Jalankan aplikasi
flutter run
```

---

## Konfigurasi API Keys

Edit file **`assets/.env`**:

```env
# ─── Supabase ─────────────────────────────────────────────────────────────────
SUPABASE_URL=https://<project-id>.supabase.co
SUPABASE_ANON_KEY=<anon-key-mu>

# ─── TMDB (Film Real-time) ────────────────────────────────────────────────────
TMDB_API_KEY=<api-key-mu>          # ← WAJIB diisi untuk data film terbaru
TMDB_BASE_URL=https://api.themoviedb.org/3

# ─── LLM (Opsional untuk Chatbot & Mood AI) ───────────────────────────────────
# LLM_API_KEY=<openrouter-or-gemini-key>
```

### 🎬 Cara Mendapatkan TMDB API Key (Gratis)

1. Daftar di **https://www.themoviedb.org/signup**
2. Login → buka **Settings → API**
3. Klik **"Create"** → pilih **"Developer"**
4. Isi formulir (gunakan info proyek/pribadi)
5. Copy **"API Key (v3 auth)"**
6. Paste ke `TMDB_API_KEY=` di `assets/.env`

> ℹ️ Tanpa TMDB API key, aplikasi tetap berjalan dengan data film contoh (mock data) yang sudah tersimpan di cache Hive.

### ☁️ Cara Resume Supabase (jika project di-pause)

> Project Supabase yang tidak aktif selama 7 hari akan di-pause otomatis oleh Supabase (Free tier).

1. Buka **https://supabase.com/dashboard**
2. Pilih project **"cinemate"**
3. Klik tombol **"Resume project"**
4. Tunggu ~1–2 menit hingga status berubah menjadi **"Active"**

> ℹ️ Jika Supabase di-pause, aplikasi otomatis beralih ke **Mode Offline** — registrasi dan login tetap berfungsi menggunakan penyimpanan lokal perangkat (GetStorage). Data akan tersinkronisasi ke Supabase saat koneksi pulih via `SyncService`.

---

## Arsitektur Proyek

```
lib/
├── main.dart                  # Entry point: init Supabase, Hive, GetStorage, dotenv
├── app.dart                   # CinemateApp: tema, routes, initial binding
├── routes/
│   └── app_routes.dart        # Semua nama route (string constants)
├── models/                    # Data class + fromJson/toJson (Modul III)
├── services/                  # Logic layer: API calls, local storage, auth
│   ├── auth_service.dart      # Custom auth (hash SHA-256 + salt, offline fallback)
│   ├── movie_service.dart     # TMDB API + Hive cache TTL 6 jam
│   ├── sync_service.dart      # Offline → Supabase auto-sync (PB-066)
│   ├── notification_service.dart  # Local notifications immediate + scheduled
│   └── ...
├── repositories/              # Abstraksi akses data (interface + implementasi)
├── controllers/               # GetxController: state management (Modul III)
├── views/                     # UI: semua halaman & widget
│   ├── auth/                  # Login, Register, Change Password
│   ├── dashboard/             # Home, Tiket, F&B, Profil (IndexedStack)
│   ├── booking/               # Alur pemesanan tiket (6 langkah)
│   ├── ticket/                # E-ticket, QR scan check-in, In-Theater Mode
│   └── ...
├── bindings/                  # GetX Dependency Injection per route
└── utils/                     # Konstanta, warna, validator, helper
```

---

## Fitur yang Sudah Selesai

| PB | Fitur | Status |
|---|---|---|
| PB-001 | Setup arsitektur (GetX, Hive, GetStorage, Dio) | ✅ |
| PB-002 | Skema database Supabase | ✅ |
| PB-003 | HTTP Service terpusat (Dio + interceptor + retry) | ✅ |
| PB-004 | Inisialisasi storage 3 lapis (Hive + GetStorage + SecureStorage) | ✅ |
| PB-005 | Registrasi akun (validasi + hash SHA-256 + offline fallback) | ✅ |
| PB-006 | Login + lockout 5 menit setelah 5x gagal | ✅ |
| PB-007 | Auto-login (sesi persisten) | ✅ |
| PB-008 | Logout + konfirmasi dialog + hapus sesi | ✅ |
| PB-009 | Login biometrik (fingerprint/face) | ✅ |
| PB-010 | Layar splash | ✅ |
| PB-011 | Bottom Navigation Bar 5 tab (IndexedStack) | ✅ |
| PB-012 | Daftar film Now Playing & Coming Soon (TMDB API) | ✅ |
| PB-013 | Cache film Hive TTL 6 jam + offline fallback | ✅ |
| PB-014 | Halaman detail film (poster, sinopsis, genre, cast) | ✅ |
| PB-015–PB-023 | Alur pemesanan tiket (pilih bioskop/film → kursi → pembayaran) | ✅ |
| PB-024 | E-ticket offline (QR code, disimpan Hive) | ✅ |
| PB-025 | Daftar tiket pengguna | ✅ |
| PB-026 | Halaman detail tiket + ekspor PDF | ✅ |
| PB-027 | Seat map interaktif (real-time lock via Supabase) | ✅ |
| PB-028–PB-034 | Fitur F&B (katalog, keranjang, checkout, riwayat pesanan) | ✅ |
| PB-035–PB-041 | AI Mood & Chatbot | ✅ |
| PB-042–PB-047 | LBS: lokasi pengguna, bioskop terdekat, peta OSM | ✅ |
| PB-048–PB-053 | Preferensi (mata uang, timezone, notifikasi) | ✅ |
| PB-054–PB-055 | Profil pengguna (edit, avatar, ganti password) | ✅ |
| PB-056–PB-058 | Notifikasi lokal (konfirmasi + scheduled 2 jam & 30 menit) | ✅ |
| PB-059–PB-065 | Promo/voucher, review, split bill, check-in QR, in-theater mode | ✅ |
| PB-066 | Sync offline → Supabase (auto-sync saat online kembali) | ✅ |
| PB-067 | Cold start benchmark + crash resistance guard | ✅ |

---

## ⚠️ Tugas Selanjutnya

> Berikut adalah **4 PB yang masih perlu diselesaikan** oleh tim berikutnya. Semua struktur kode, model, dan service sudah disiapkan — tinggal implementasi UI dan integrasi final.

---

### 📌 PB-068 — Cinema Rewind (Riwayat Tahunan Sinematik)

**Deskripsi:**  
Halaman "Cinema Rewind" yang menampilkan rekap tontonan tahunan pengguna (ala Spotify Wrapped) — total film ditonton, genre favorit, bioskop favorit, waktu total di bioskop.

**File yang perlu dibuat/dimodifikasi:**
- `lib/views/cinema_rewind/cinema_rewind_view.dart` — **[BUAT BARU]** UI animatif halaman rewind
- `lib/controllers/cinema_rewind_controller.dart` — **[BUAT BARU]** agregasi data dari tiket lokal
- Route sudah ada: `Routes.cinemaRewind = '/cinema-rewind'`

**Panduan implementasi:**
```dart
// 1. Ambil semua tiket dari StorageService().getCachedTickets()
// 2. Filter berdasarkan tahun (DateTime.now().year)
// 3. Hitung: totalMovies, genreMap (terbanyak = favorit), cinemaCount, totalMinutes
// 4. Tampilkan dengan animasi PageView card demi card (mirip Spotify Wrapped)
```

**Acceptance Criteria:**
- [ ] Menampilkan minimal 4 statistik: total film, genre favorit, bioskop favorit, total durasi
- [ ] Ada animasi transisi antar statistik (AnimatedContainer / PageView)
- [ ] Tombol share (bisa pakai `screenshot` package untuk share ke media sosial)
- [ ] Bisa diakses dari halaman Profil

---

### 📌 PB-069 — My Cinemate (Loyalty & Badge System)

**Deskripsi:**  
Halaman "My Cinemate" yang menampilkan level loyalty pengguna (Bronze → Silver → Gold → Platinum) berdasarkan total pembelian, serta koleksi badge yang sudah diperoleh.

**File yang perlu dibuat/dimodifikasi:**
- `lib/views/profile/my_cinemate_view.dart` — **[BUAT BARU]** (route `/my-cinemate` sudah ada)
- `lib/models/loyalty_badge_model.dart` — sudah ada, tinggal digunakan
- `lib/controllers/profile_controller.dart` — tambahkan `fetchLoyaltyData()`

**Panduan implementasi:**
```dart
// Model LoyaltyBadgeModel sudah ada di lib/models/loyalty_badge_model.dart
// Level berdasarkan total_spending:
//   Bronze:   0 – 499.999
//   Silver:   500.000 – 1.499.999
//   Gold:     1.500.000 – 4.999.999
//   Platinum: >= 5.000.000
//
// Badge diperoleh otomatis (contoh):
//   "First Timer"    → tiket pertama
//   "Night Owl"      → nonton > 21:00
//   "Binge Watcher"  → 5+ film dalam sebulan
//   "Foodie"         → pesan F&B 3x berturut-turut
```

**Acceptance Criteria:**
- [ ] Progress bar level dengan animasi fill
- [ ] Grid badge (locked/unlocked visual berbeda)
- [ ] Total poin dan total pengeluaran ditampilkan
- [ ] Bisa diakses dari tab Profil

---

### 📌 PB-070 — Voucher Catalog (Promo & Kode Kupon)

**Deskripsi:**  
Halaman katalog voucher/promo yang dapat diklaim oleh pengguna berdasarkan level loyalty. Voucher diterapkan di halaman Order Summary saat checkout.

**File yang perlu dibuat/dimodifikasi:**
- `lib/views/profile/voucher_catalog_view.dart` — **[BUAT BARU]** (route `/voucher-catalog` sudah ada)
- `lib/services/promo_service.dart` — **sudah ada**, tinggal lengkapi method `claimVoucher()`
- `lib/models/promo_voucher_model.dart` — sudah ada

**Panduan implementasi:**
```dart
// PromoService sudah ada di lib/services/promo_service.dart
// Tambahkan method:
//   Future<List<PromoVoucherModel>> getAvailableVouchers(String userId)
//   Future<bool> claimVoucher(String userId, String voucherId)
//
// Data voucher bisa dari:
//   - Supabase tabel 'promos' (jika online)
//   - Mock data hardcode (jika offline)
//
// Contoh mock vouchers:
//   - CINEMA10: diskon 10% (min. transaksi 50.000)
//   - POPCORN: gratis popcorn M (dengan beli tiket)
//   - GOLD20: diskon 20% khusus member Gold+
```

**Acceptance Criteria:**
- [ ] Daftar voucher tersedia dengan detail (kode, diskon, min. transaksi, exp. date)
- [ ] Tombol "Klaim" per voucher (dengan feedback loading)
- [ ] Voucher yang sudah diklaim tampil berbeda (badge "Diklaim")
- [ ] Input kode manual voucher juga tersedia
- [ ] Voucher terklaim bisa dipilih di Order Summary

---

### 📌 PB-071 — Advanced Search & Filter Film

**Deskripsi:**  
Penyempurnaan fitur Search dengan filter lanjutan: genre, rating, bioskop, tanggal tayang, dan urutan (terbaru/terpopuler/terdekat).

**File yang perlu dimodifikasi:**
- `lib/views/search/search_view.dart` — tambahkan bottom sheet filter
- `lib/controllers/search_controller.dart` — tambahkan `applyFilters()` dan state filter aktif
- `lib/services/movie_service.dart` — tambahkan method `searchMovies(query, {filters})`

**Panduan implementasi:**
```dart
// SearchController sudah ada di lib/controllers/search_controller.dart
// Tambahkan state filter:
//   final selectedGenres = <String>[].obs;
//   final minRating = 0.0.obs;
//   final sortBy = 'popularity'.obs; // 'popularity', 'release_date', 'rating'
//
// TMDB Search API: GET /search/movie?query=<q>&with_genres=<id>&sort_by=<s>
// Genre IDs TMDB: Action=28, Drama=18, Comedy=35, Horror=27, Romance=10749
//
// Filter genre, rating, sortBy dikirimkan sebagai query param ke TMDB
```

**Acceptance Criteria:**
- [ ] Filter genre (multi-select chips)
- [ ] Filter rating minimum (slider 0–10)
- [ ] Sort: Terpopuler / Terbaru / Rating tertinggi
- [ ] Chip filter aktif ditampilkan di atas hasil pencarian
- [ ] Tombol "Reset Filter" tersedia
- [ ] Jumlah hasil pencarian ditampilkan ("X hasil ditemukan")

---

## Panduan Kontribusi

### Alur Kerja Git

```bash
# Buat branch baru untuk setiap PB
git checkout -b feature/PB-068-cinema-rewind

# Setelah selesai, push dan buat Pull Request
git push origin feature/PB-068-cinema-rewind
```

### Konvensi Penamaan

| Jenis File | Konvensi | Contoh |
|---|---|---|
| View | `snake_case_view.dart` | `cinema_rewind_view.dart` |
| Controller | `snake_case_controller.dart` | `cinema_rewind_controller.dart` |
| Service | `snake_case_service.dart` | `promo_service.dart` |
| Model | `snake_case_model.dart` | `loyalty_badge_model.dart` |

### Checklist Sebelum PR

- [ ] `dart analyze` → No issues found
- [ ] Widget baru menggunakan warna dari `AppColors` (bukan hardcode)
- [ ] Semua teks menggunakan `TextStyle(color: AppColors.textPrimary/Secondary)`
- [ ] Ada state loading, empty, error (sesuai PB-055)
- [ ] Controller di-dispose dengan benar (`onClose()`)
- [ ] Tidak ada API key atau kredensial hardcode di kode

### Menjalankan Lint & Test

```bash
# Lint
dart analyze

# Test
flutter test

# Format kode
dart format lib/
```

---

## Troubleshooting

### ❌ Error: `ClientException with SocketFailed host lookup`

**Penyebab:** Supabase project di-pause  
**Solusi:**  
1. Buka https://supabase.com/dashboard → Resume project "cinemate"  
2. Atau biarkan saja — aplikasi otomatis beralih ke **Mode Offline** dan tetap bisa digunakan

### ❌ Error: `compileSdk requires 37`

**Solusi:** Sudah diperbaiki di `android/app/build.gradle.kts` (`compileSdk = 37`)

### ❌ Error: `core library desugaring to be enabled`

**Solusi:** Sudah diperbaiki — `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4`

### ❌ Data film tidak berubah (masih mock data)

**Penyebab:** `TMDB_API_KEY` di `assets/.env` masih placeholder  
**Solusi:** Daftar di https://themoviedb.org, dapatkan API key gratis, isi di `.env`

### ❌ Hive error saat pertama run

**Solusi:**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter clean && flutter run
```

---

## Referensi

- [SRS Cinemate (SRS-CNM-001)](docs/SRS-Cinemate.pdf)
- [Product Backlog (PB-CNM-001)](docs/ProductBacklog-Cinemate.pdf)
- [TMDB API Docs](https://developer.themoviedb.org/docs)
- [Supabase Flutter Docs](https://supabase.com/docs/reference/dart/introduction)
- [GetX Documentation](https://pub.dev/packages/get)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
