# 🎬 Panduan Sinkronisasi & Penyetelan Sistem Proyek Cinemate
**Dokumen Standar Pengembangan Tim — Proyek Akhir Praktikum Pemrograman Mobile**  
*Terakhir diperbarui: 24 November 2026*

---

> [!IMPORTANT]
> Dokumen ini disusun khusus agar rekan tim yang melakukan *clone* ulang (akibat laptop ter-reset atau file hilang) dapat langsung menyamakan lingkungan kerja, memahami fitur yang disederhanakan, serta menjalankan proyek tanpa *error* konfigurasi.

---

## 📌 1. Informasi Repository & Kloning

- **Remote Git:** `https://github.com/dyahnaylaamaliaputri-bit/Cinemate.git`  
  *(atau mirror repositori: `https://github.com/dyahnaylaamaliaputri-bit/124240094_124240100_ProyekAkhirMobileSI-E.git`)*
- **Branch Utama:** `main`

### Langkah Kloning di Terminal:
```bash
# 1. Masuk ke direktori kerja (misal: Downloads atau Documents)
cd d:\DirektoriPilihan

# 2. Clone repository
git clone https://github.com/dyahnaylaamaliaputri-bit/Cinemate.git

# 3. Masuk ke folder proyek
cd Cinemate

# 4. Pastikan berada di branch main terbaru
git checkout main
git pull origin main
```

---

## ⚙️ 2. Prasyarat Lingkungan Pengembangan (Prerequisites)

Pastikan spesifikasi tool di laptop sudah memenuhi standar berikut:

| Komponen | Versi Minimal | Keterangan |
|---|---|---|
| **Flutter SDK** | `>= 3.19.0` (disarankan `3.24.x` ke atas) | Cek via `flutter --version` |
| **Dart SDK** | `>= 3.3.0` | Otomatis terpasang bersama Flutter |
| **Java JDK** | JDK 17 atau JDK 21 | Dibutuhkan untuk Gradle 8.x / 9.x |
| **Android SDK** | `compileSdk 37`, `minSdk 24` | Sudah disetel di `android/app/build.gradle.kts` |
| **IDE** | VS Code / Android Studio | Ekstensi wajib: **Flutter** & **Dart** |

---

## 🚀 3. Langkah Setup & Instalasi Dependensi

Jalankan perintah berikut secara berurutan di dalam folder `Cinemate`:

```bash
# 1. Unduh seluruh package yang tertera di pubspec.yaml
flutter pub get

# 2. Generate kode TypeAdapter Hive (wajib setelah clone pertama)
dart run build_runner build --delete-conflicting-outputs
```

> [!NOTE]
> Jika ada peringatan konflik file saat menjalankan `build_runner`, opsi `--delete-conflicting-outputs` akan otomatis menimpa file adapter generated lama dengan yang valid.

---

## 🔑 4. Konfigurasi Environment (`assets/.env`)

File konfigurasi berada di `assets/.env`. Kredensial Supabase aktif sudah disetel secara otomatis di dalam repository:

```env
# ─── Supabase PostgreSQL Backend (Aktif) ──────────────────────────────────────
SUPABASE_URL=https://hbdhwsofkjkurewqnixk.supabase.co
SUPABASE_REST_URL=https://hbdhwsofkjkurewqnixk.supabase.co/rest/v1/
SUPABASE_ANON_KEY=sb_publishable_ps6_m_mcmw-Qe3fCokDJ2w_hUumridC

# ─── TMDB REST API (Katalog Film Bioskop) ─────────────────────────────────────
TMDB_API_KEY=YOUR_TMDB_API_KEY_HERE
TMDB_BASE_URL=https://api.themoviedb.org/3
```

### Penjelasan Sistem Koneksi:
1. **Supabase Cloud:**
   - Proyek Supabase sudah di-resume dan aktif di `hbdhwsofkjkurewqnixk.supabase.co`.
   - Menggunakan custom authentication di tabel `public.users`.
2. **Mode Offline Fallback:**
   - Sistem sudah dilengkapi fallback otomatis. Jika laptop tidak terhubung ke internet, autentikasi dan tiket otomatis dialihkan ke local storage (GetStorage/Hive) sehingga aplikasi **tidak akan crash**.
3. **TMDB API (Film):**
   - Jika `TMDB_API_KEY` belum diisi akun pribadi, aplikasi otomatis memuat seed data film populer (*Dune 2, Deadpool & Wolverine*, dll) dari cache Hive.
   - Jika ingin memuat film bioskop live hari ini, masukkan API key gratis dari [themoviedb.org](https://www.themoviedb.org/settings/api).

---

## 🎯 5. Penyederhanaan Fitur (Sesuai Arahan Modul Praktikum)

Aplikasi telah disederhanakan agar fokus dan relevan dengan materi **Modul II s.d. Modul VIII**.

### ❌ Fitur yang Telah Dihapus (JANGAN DIBUAT ULANG):
1. **Fitur Chatbot AI (CineBot):**
   - Seluruh view chatbot, service dialog, model message, dan floating action button telah dihapus.
2. **Fitur Mood / Profiling AI:**
   - Layar mood picker, questionnaire profiling, model rekomendasi emosi, dan history profiling telah dihapus.
3. **Fitur Scan Tiket Petugas (QR Scanner Check-in):**
   - Halaman scanner QR kamera petugas di tab tiket telah dihapus (tampilan barcode/QR tiket untuk penonton tetap ada).

### ✅ Fitur Inti yang Aktif & Teruji:
1. **Autentikasi Pengguna:** Register, Login, Logout, Validasi Sesi, Ganti Password (online Supabase + offline fallback).
2. **Katalog Film (Home Tab):** Banner carousel auto-scroll, daftar film *Now Playing*, film *Coming Soon*, dan pencarian judul film.
3. **Pemesanan Tiket Bioskop:**
   - Pemilihan bioskop & studio (Regular, IMAX, Premiere).
   - Pemilihan kursi interaktif (kursi terisi/tersedia/terpilih).
   - Ringkasan pemesanan (Order Summary) & simulasi pembayaran.
4. **Food & Beverages (F&B):** Pemesanan cemilan popcorn & minuman bioskop.
5. **Tiket Saya:** Tab tiket aktif & riwayat tiket yang tersimpan di Hive (dapat dibuka kapan saja secara offline).
6. **LBS & Peta Bioskop (Modul VII):** Deteksi lokasi GPS pengguna, penghitungan jarak bioskop terdekat via `Geolocator`, dan visualisasi peta via `flutter_map` (OpenStreetMap).
7. **Notifikasi Lokal (Modul VII):** Notifikasi instan konfirmasi pembelian tiket dan pengingat jadwal film via `flutter_local_notifications`.
8. **Profil & Pengaturan:** Ganti avatar profil, ubah nama, toggle login biometrik, dark theme palette, dan hapus cache aplikasi.

---

## 📚 6. Pemetaan Modul Praktikum ke Kode Proyek

Berikut acuan jika dosen atau asisten praktikum menanyakan implementasi tiap modul:

| Modul | Topik Materi | Lokasi Implementasi di Kode |
|---|---|---|
| **Modul II** | Widget & Layout | `lib/views/widgets/` (`movie_card.dart`, `cinema_card.dart`, `shimmer_loading.dart`, BottomNavigationBar di `dashboard_view.dart`) |
| **Modul III** | State & Data | GetX Reactive State: `RxBool`, `RxList`, `Obx(() => ...)` di seluruh view dan `lib/controllers/` |
| **Modul IV** | Navigation | Named Routing GetX: `lib/routes/app_routes.dart` dan `lib/routes/app_pages.dart` (`Get.toNamed()`, argument passing) |
| **Modul V** | HTTP Request (API) | `lib/services/movie_service.dart` (REST API TMDB) & `lib/services/http_service.dart` (Dio GET/POST request, timeout, error handling) |
| **Modul VI** | Local Storage | `lib/services/storage_service.dart` (Hive boxes `movies_cache`, `tickets_cache`, `cinemas_cache`, GetStorage, & FlutterSecureStorage) |
| **Modul VII** | Notification & LBS | `lib/services/location_service.dart` (`Geolocator` hitung jarak bioskop) dan `lib/services/notification_service.dart` (`flutter_local_notifications` pengingat tiket) |
| **Modul VIII** | Flutter Lanjutan & GetX | Arsitektur MVC terstruktur: `lib/controllers/`, `lib/bindings/`, `lib/services/`, dependency injection `Get.lazyPut()`, & `BindingsBuilder` |

---

## 🧪 7. Perintah Pengujian & Verifikasi

Sebelum melakukan *push* atau mempresentasikan ke dosen, jalankan perintah berikut untuk memastikan kode bersih:

```bash
# 1. Cek analisis statis Dart (harus 0 errors)
dart analyze lib

# 2. Jalankan seluruh unit testing (harus All tests passed)
flutter test

# 3. Jalankan aplikasi di emulator atau HP Android
flutter run

# 4. Buat APK debug
flutter build apk --debug
# Hasil APK: build/app/outputs/flutter-apk/app-debug.apk
```

---

## 💡 8. Troubleshooting Umum

1. **Error `SocketFailed host lookup: 'your_project_id.supabase.co'`:**  
   *Penyebab:* Masih terpasang build lama di HP. Pastikan sudah melakukan `git pull origin main` dan build APK ulang.
2. **Error `Target of URI doesn't exist: '*.g.dart'`:**  
   *Solusi:* Jalankan `dart run build_runner build --delete-conflicting-outputs`.
3. **Peta Bioskop Tidak Muncul di Peta:**  
   *Penyebab:* Izin lokasi perangkat belum diizinkan. Berikan izin akses lokasi (*Location Permission*) di pengaturan HP.
