# 🎬 Cinemate — Aplikasi Pemesanan Tiket Bioskop

> **Proyek Akhir Praktikum Pemrograman Mobile — Flutter & Dart**  
> Mengimplementasikan Materi **Modul II s.d. Modul VIII**  
> Panduan lengkap setup tim baru: lihat [PANDUAN_SETUP_TIM.md](PANDUAN_SETUP_TIM.md)

---

## 📋 Daftar Isi

1. [Tentang Proyek](#tentang-proyek)
2. [Pemetaan Materi Modul Praktikum](#pemetaan-materi-modul-praktikum)
3. [Setup Lingkungan Pengembangan](#setup-lingkungan-pengembangan)
4. [Konfigurasi Environment](#konfigurasi-environment)
5. [Fitur Utama Aplikasi](#fitur-utama-aplikasi)
6. [Struktur Folder](#struktur-folder)
7. [Pengujian & Verifikasi](#pengujian--verifikasi)

---

## 📖 Tentang Proyek

**Cinemate** adalah aplikasi pemesanan tiket bioskop modern berbasis Flutter dengan arsitektur terstruktur. Aplikasi ini mengintegrasikan katalog film real-time dari REST API TMDB, backend cloud PostgreSQL via Supabase dengan proteksi mode offline lokal (Hive & GetStorage), penentuan bioskop terdekat via GPS (LBS), serta sistem pengingat jadwal tiket film dengan notifikasi lokal.

| Layer | Teknologi |
|---|---|
| **State Management & Routing** | GetX (`GetxController`, `Obx`, `Bindings`, Named Routes) |
| **Database Cloud** | Supabase PostgreSQL (`https://hbdhwsofkjkurewqnixk.supabase.co`) |
| **Database Lokal (Offline-first)** | Hive + GetStorage + flutter_secure_storage |
| **HTTP Request** | Dio (Singleton, interceptor, timeout, retry) |
| **Katalog Film Real-time** | TMDB REST API v3 (*Now Playing* & *Coming Soon*) |
| **LBS & Peta Bioskop** | Geolocator (GPS) + Flutter Map + OpenStreetMap |
| **Notifikasi Lokal** | flutter_local_notifications (Tiket & Jadwal Tayang) |

---

## 📚 Pemetaan Materi Modul Praktikum

Aplikasi telah diselaraskan dengan kurikulum praktikum:

- **Modul II (Widget & Layout):** Komponen kartu film (`MovieCard`), kartu bioskop (`CinemaCard`), Carousel Banner, Shimmer skeleton loading, Custom AppBar, dan Bottom Navigation Bar.
- **Modul III (State & Data):** Reactive State Management GetX (`RxBool`, `RxList`, `Obx(() => ...)`).
- **Modul IV (Navigation):** Named Routes GetX (`Get.toNamed`, parameter passing, Bindings).
- **Modul V (HTTP Request):** REST API TMDB (*Now Playing* & *Upcoming*) & Supabase REST, parsing JSON dengan `factory fromJson()`.
- **Modul VI (Local Storage):** Hive box caching (`movies_cache`, `tickets_cache`, `cinemas_cache`) dengan TTL 6 jam & GetStorage untuk sesi login.
- **Modul VII (Notification & LBS):** Perhitungan jarak bioskop terdekat via `Geolocator` dan notifikasi jadwal film via `flutter_local_notifications`.
- **Modul VIII (Flutter Lanjutan & GetX):** Arsitektur MVC terstruktur: Controller, Service, Binding, dan Repository pattern.

---

## ⚙️ Setup Lingkungan Pengembangan

### Prasyarat
- **Flutter SDK:** `>= 3.19.0`
- **Dart SDK:** `>= 3.3.0`
- **Java JDK:** JDK 17 atau JDK 21

### Langkah Instalasi
```bash
# 1. Clone repository
git clone https://github.com/dyahnaylaamaliaputri-bit/Cinemate.git
cd Cinemate

# 2. Unduh dependensi
flutter pub get

# 3. Generate TypeAdapter Hive (Wajib setelah clone)
dart run build_runner build --delete-conflicting-outputs

# 4. Jalankan aplikasi
flutter run
```

---

## 🔑 Konfigurasi Environment

File `assets/.env` sudah disetel dengan backend Supabase aktif:

```env
SUPABASE_URL=https://hbdhwsofkjkurewqnixk.supabase.co
SUPABASE_REST_URL=https://hbdhwsofkjkurewqnixk.supabase.co/rest/v1/
SUPABASE_ANON_KEY=sb_publishable_ps6_m_mcmw-Qe3fCokDJ2w_hUumridC
TMDB_API_KEY=YOUR_TMDB_API_KEY_HERE
TMDB_BASE_URL=https://api.themoviedb.org/3
```

> **Mode Offline:** Jika perangkat tidak terhubung ke internet atau Supabase mengalami gangguan, sistem otomatis beralih ke penyimpanan lokal perangkat sehingga pengguna tetap bisa mendaftar, login, dan melihat tiket.

---

## 🎯 Fitur Utama Aplikasi

1. **Autentikasi:** Registrasi, login, logout, dan ganti password.
2. **Katalog Film:** Film sedang tayang (*Now Playing*), film akan datang (*Coming Soon*), dan pencarian film.
3. **Pemesanan Tiket:**
   - Pemilihan bioskop dan studio (Regular, IMAX, Premiere).
   - Pemilihan kursi interaktif real-time.
   - Ringkasan pemesanan & simulasi pembayaran.
4. **Food & Beverages (F&B):** Pemesanan cemilan & minuman bioskop.
5. **Tiket Saya:** Tiket aktif & riwayat pemesanan tersimpan di Hive (akses offline dengan kode barcode/QR).
6. **LBS & Peta Bioskop:** Deteksi lokasi GPS pengguna dan pengurutan bioskop dari jarak terdekat.
7. **Notifikasi:** Pengingat jadwal penayangan film dan konfirmasi tiket.
8. **Profil Pengguna:** Edit profil, ganti foto, mode dark cinema, dan kelola preferensi.

---

## 🧪 Pengujian & Verifikasi

```bash
# Analisis sintaks Dart (0 issues)
dart analyze lib

# Menjalankan unit tests
flutter test

# Kompilasi debug APK
flutter build apk --debug
```
*Hasil APK berada di: `build/app/outputs/flutter-apk/app-debug.apk`*
