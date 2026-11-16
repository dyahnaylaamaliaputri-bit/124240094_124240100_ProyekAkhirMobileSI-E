# 🎬 Cinemate

**Cinemate** adalah aplikasi pemesanan tiket bioskop multi-cinema berbasis AI untuk rekomendasi film sesuai *mood* dan penemuan lokasi bioskop terdekat (*Location-Based Services*), dilengkapi pemesanan tiket & F&B, simulasi pembayaran, serta *e-ticket QR code* yang dapat diakses secara *offline*.

Proyek ini dibangun menggunakan **Dart** & framework **Flutter** dengan arsitektur **GetX OOP**, serta mengacu pada **SRS-CNM-001** dan **PB-CNM-001**.

---

## 🛠️ Tech Stack & Konvensi
- **Framework & SDK:** Flutter (Dart 3.x, Android API 26+)
- **State Management & Routing:** GetX (`GetxController`, `GetPage`, `Bindings`, `Obx`)
- **Desain UI:** Material Design 3 — *Dark Cinema Palette* (`#0A0A0A`, `#E50914`, `#1A1A2E`, `#FFD700`)
- **Backend Online:** Supabase (PostgreSQL Database & Storage) — *Bukan Firebase*
- **HTTP Client:** Dio (Interceptor token, retry 2x, timeout 15s/30s)
- **Local Storage:**
  - `flutter_secure_storage`: Token sesi & user ID (terenkripsi)
  - `hive` & `hive_flutter`: Cache data film, bioskop, F&B, dan e-ticket offline (NoSQL)
  - `get_storage`: Preferensi tema, mata uang, zona waktu, dan login attempt lockout
- **Peta & LBS:** `flutter_map` (OpenStreetMap tile layer gratis & offline friendly), `geolocator`, `latlong2`, `url_launcher`
- **Konversi & Format:** `intl` (locale IDR, USD, SGD, EUR, JPY, GBP) & penyesuaian zona waktu (WIB, WITA, WIT, London GMT/BST)
- **Referensi Modul Praktikum:**
  - Modul 6/7 (Local Storage & Hive): [pertemuan_7_mobile](https://github.com/TheBinKingVII/pertemuan_7_mobile)
  - Modul 7/8 (Notification & LBS): [pertemuan_8_mobile_2026](https://github.com/TheBinKingVII/pertemuan_8_mobile_2026)

---

## 📁 Struktur Folder Proyek
```text
lib/
├── app.dart                    # GetMaterialApp konfigurasi tema & initial route
├── main.dart                   # Inisialisasi binding, dotenv, GetStorage, Hive, Supabase
├── bindings/                   # GetX Bindings (InitialBinding, AuthBinding, DashboardBinding, dll.)
├── controllers/                # GetxController (CinemaController, PreferenceController, FnbController, dll.)
├── models/                     # Data class/model (CinemaModel, ShowtimeModel, FnbItemModel, TicketModel, dll.)
├── repositories/               # Repository pattern (Interface & Implementation)
├── routes/                     # AppRoutes & AppPages
├── services/                   # Service layer (LocationService, CinemaService, FnbService, MoodService, dll.)
├── utils/                      # AppColors, AppTheme, CurrencyHelper, TimezoneHelper, Validators
└── views/                      # Antarmuka UI (splash, auth, dashboard, booking, cinema, fnb, mood, profile, ticket)
assets/
├── .env.example                # Template variabel lingkungan
└── .env                        # Kredensial API (diabaikan oleh git)
docs/
└── supabase_schema.sql         # Skema database & RLS Supabase
```

---

## ✅ Status Pengerjaan (Sprint 1 s/d Sprint 4 — SELESAI 100%)

### 1. Epic Fondasi Teknis (TEK — PB 1)
- [x] **PB-001 (Kerangka Proyek & OOP):** Struktur folder GetX OOP lengkap (`models`, `services`, `repositories`, `controllers`, `bindings`, `views`, `routes`, `utils`). Lolos uji `dart analyze` (0 error).
- [x] **PB-002 (Skema Supabase):** Skema SQL di `docs/supabase_schema.sql` (tabel `users`, `sessions`, `cinemas`, `movies`, `showtimes`, `seat_locks`, `bookings`, `fnb_items`, `fnb_orders`, aturan RLS, dan seed data). Skema telah aktif dan terhubung ke database cloud Supabase.
- [x] **PB-003 (Lapisan HTTP Dio):** `HttpService` berbasis Dio dengan auth interceptor, auto-retry 2x, penanganan error terstandar, dan integrasi `.env`.
- [x] **PB-004 (Lapisan Penyimpanan Lokal):** `StorageService` mengabstraksi Hive (cache data), `flutter_secure_storage` (token sesi), dan `GetStorage` (preferensi).

### 2. Epic Autentikasi (AUT — PB 2)
- [x] **PB-005 (Registrasi Akun):** Halaman register (`register_view.dart`) dengan validasi form lengkap, hashing password aman (*salt + SHA-256*), dan deteksi email duplikat.
- [x] **PB-006 (Login Email & Password):** Halaman login (`login_view.dart`) dengan verifikasi kredensial, pesan error aman, serta fitur **lockout 5 menit setelah 5x gagal** lengkap dengan *countdown timer*.
- [x] **PB-007 (Sesi Persisten):** `splash_view.dart` otomatis memverifikasi token sesi (< 7 hari) dan mengarahkan pengguna ke Dashboard atau Login.
- [x] **PB-008 (Logout):** Tombol logout dengan dialog konfirmasi, menghapus sesi di storage lokal dan tabel `sessions` Supabase.

### 3. Epic Dashboard & Katalog (DSH — PB 3)
- [x] **PB-011 (Navigasi Bawah 5 Menu):** Menu navigasi bawah 5 tab (Dashboard, Tiket, Pesan Makanan, Profil, Logout) dengan `IndexedStack` agar state tiap tab tidak ter-reset. Mengimplementasikan native `Navigator` bawaan Flutter SDK dan passing data antar halaman.
- [x] **PB-012 (Banner, Now Playing, & Coming Soon):** `MovieModel`, `MovieService` terintegrasi TMDB API `/movie/now_playing` & `/movie/upcoming`, Carousel Banner otomatis, Horizontal List poster film, dan Shimmer/Skeleton loading.
- [x] **PB-013 (Cache Film Offline):** Caching data katalog film TMDB ke Hive box `movies_cache` dengan penanda waktu (*TTL 6 jam*). Menampilkan banner indikator "Mode Offline" saat memuat dari cache lokal / tanpa koneksi.
- [x] **PB-014 (Halaman Detail Film):** Halaman `MovieDetailView` lengkap dibuka via `Get.toNamed(Routes.movieDetail, arguments: movie)` menampilkan backdrop, poster, sinopsis, genre chips, estimasi durasi, rating bintang, dan tombol sticky "Beli Tiket".
- [x] **PB-015 (Bioskop Terdekat di Dashboard):** Ringkasan 3 bioskop terdekat di bawah section film pada dashboard dengan kalkulasi jarak akurat (*Haversine Formula*), pengambilan data dari tabel Supabase `cinemas`, cache Hive `cinemas_cache`, skeleton loading, dan fitur ganti titik lokasi acuan LBS interaktif.

### 4. Epic Pemesanan Tiket Bioskop (TKT — PB 4)
- [x] **PB-018 (Alur Booked by Cinema):** Alur pemesanan tiket dari pemilihan bioskop (`BookByCinemaView`) -> film yang sedang tayang -> tanggal penayangan (7 hari ke depan) -> kelas studio (Regular 2D, IMAX with Laser, The Premiere) & jam tayang lengkap dengan indikator sisa kursi dan harga tiket.
- [x] **PB-019 (Alur Booked by Movie):** Alur pemesanan tiket langsung dari film di dashboard/detail (`BookByMovieView`) -> filter otomatis bioskop terdekat yang menayangkan film tersebut -> pilih bioskop, tanggal, studio & jam tayang -> navigasi ke pemilihan kursi (`SelectSeatView`).
- [x] **PB-020 (Ringkasan Pesanan / Order Summary):** Layar `OrderSummaryView` menampilkan informasi pesanan lengkap: poster & judul film, bioskop, tanggal, studio, jam, chip kursi yang dipilih, rincian biaya (tiket x jumlah + biaya layanan aplikasi Rp 3.000), dan total pembayaran.
- [x] **PB-021 (Simulasi Pembayaran):** Layar `PaymentView` dengan pilihan metode (BCA VA, Mandiri VA, BRI VA, GoPay, OVO, Dana, QRIS Dinamis), countdown timer batas bayar 10 menit, serta integrasi tombol "Bayar Sekarang" yang memproses tiket.
- [x] **PB-022 & PB-023 (E-Ticket QR Code & Persistensi Cloud/Local):** `TicketModel` dengan QR code dinamis (`qr_flutter`), kode booking unik (`CNM-XXXXX`), penyimpanan ke Supabase (`bookings` & `booking_seats`) serta persistensi offline ke Hive box `tickets_cache`. Dilengkapi dialog sukses & navigasi instan ke E-Ticket.
- [x] **PB-024 (Akses E-Ticket Offline):** Tiket dapat dibuka secara instan tanpa koneksi internet langsung dari Hive cache. Terdapat indikator visual "Mode Offline (Hive Cache)" dan QR code tetap dapat di-scan oleh petugas bioskop.
- [x] **PB-025 (Daftar Tiket Aktif, Riwayat, & Simulasi Check-in):** Tab `TicketsTab` dengan pemisahan otomatis tiket aktif (jadwal belum lewat) dan riwayat tiket (sudah ditonton / lewat), pencarian live (*search by title, booking code, cinema*), countdown waktu tayang ("Dimulai dalam X jam/menit"), serta tombol simulasi check-in petugas yang memperbarui status tiket secara real-time di Supabase dan Hive.

### 5. Epic Pesan Makanan & Minuman / F&B (FNB — PB 7 Teman)
- [x] **PB-026 (Katalog F&B Offline-First & Hive Cache — Tanpa Supabase):** Model `FnbItemModel` dengan 12 varian menu lengkap, `FnbService` berbasis Hive box `fnb_cache` (100% offline-first murni tanpa ketergantungan Supabase), banner indikator status Hive cache & timestamp sinkronisasi, filter chip kategori dinamis (*Semua*, *Snack*, *Minuman*, *Paket Combo*, *Makanan Berat*) dengan counter kuantitas menu, pencarian real-time dengan tombol clear, shimmer skeleton loading (`FnbListSkeleton`), dan penanganan empty state saat pencarian tidak ditemukan.
- [x] **PB-027 (Keranjang Pesanan F&B / Reactive Cart Management — Tanpa Supabase):** `FnbController` mengelola keranjang belanja reaktif (`cart`), penambahan/pengurangan item, persistensi otomatis ke Hive box `fnb_cache` (`active_cart` & `cart_notes`), instruksi/catatan khusus per menu (`itemNotes`), kalkulasi subtotal, biaya layanan aplikasi Rp 2.000, grand total, floating summary bar interaktif, badge keranjang di AppBar, modal bottom sheet detail keranjang (`FnbCartBottomSheet`), serta dialog konfirmasi pengosongan keranjang.
- [x] **PB-028 (Pilihan Bioskop & Metode Pengambilan F&B — Tanpa Supabase):** Layar `FnbCheckoutView` mendukung pemilihan lokasi bioskop penjualan (`availableCinemas`) dari seed/cache lokal tanpa Supabase, 2 metode pengambilan (*Ambil di Counter Concession* dengan QR voucher mandiri vs *Antar Langsung ke Studio & Kursi* oleh staf bioskop), auto-detection tiket aktif (`detectedActiveTicket`) dari Hive `tickets_cache` / `TicketsController` untuk pre-fill otomatis nama studio & nomor kursi lengkap dengan banner visual informasi tiket, text controller persisten tersinkronisasi, serta validasi form pengantaran studio & kursi sebelum checkout.
- [x] **PB-029 (Simulasi Pembayaran & E-Voucher QR Code F&B):** Integrasi transaksi ke tabel Supabase `fnb_orders` & `fnb_order_items`, penerbitan kode pickup 5 digit (`FNB-XXXXX`), serta QR Code E-Voucher (`qr_flutter`) untuk verifikasi staf bioskop.
- [x] **PB-030 (Riwayat & Pelacakan Status Pesanan F&B):** Sub-tab *"Pesanan Saya"* dengan status stepper dinamis (*Sedang Disiapkan* 🍳 $\rightarrow$ *Siap Diambil* 🍿 $\rightarrow$ *Selesai Diambil* ✅), persistensi offline ke Hive (`fnb_orders_cache`), dan tombol simulasi staf bioskop.

### 6. Epic Rekomendasi Film Berbasis Mood AI (MOD / AIL — PB 8 Teman)
- [x] **PB-031 (Layar Pemilih Mood Interaktif — Tanpa Supabase):** Banner pengantar Mood AI di `HomeTab`, navigasi ke `MoodPickerView` dengan 6 kategori emosi (*Gembira*, *Haru*, *Romantis*, *Tegang*, *Santai*, *Bosan*), visualisasi gradien estetik dinamis, highlight kartu emosi terpilih, `MoodController` reaktif, integrasi binding rute, fallback kurasi offline tanpa Supabase, dan penyimpanan Hive cache lokal.
- [x] **PB-032 (Mood-to-Genre Engine & Filter TMDB Discovery — Tanpa Supabase):** Engine rekomendasi `MoodRecommendationService` memetakan genre ID TMDB dengan filter penemuan discovery cerdas (rating $\ge 7.0$, sorting dinamis *Terpopuler* & *Rating Tertinggi*), fallback kurasi offline berkualitas tinggi dengan TTL di Hive cache tanpa Supabase, serta didukung langkah opsional Tambah Makanan F&B sebelum ringkasan pesanan tiket bioskop (FR-028 / PB-032).
- [x] **PB-033 (Hasil Rekomendasi AI & Aksi Direct Booking — Tanpa Supabase):** Kartu rekomendasi film interaktif dengan persentase kecocokan AI (*88% - 99% MATCH*), badge gradien dinamis, analisis personalisasi berbasis mood emosi pengguna, tombol *"Lihat Sinopsis"* untuk detail lengkap, tombol *"Pesan Tiket"* langsung ke alur *Book by Movie* (`Routes.bookByMovie`), serta didukung alur pemesanan F&B mandiri tanpa tiket dengan kode ambil unik 5 digit `FNB-XXXXX` dan status processing (FR-036 / PB-033).

### 7. Epic Location-Based Services & Peta Bioskop (LBS — PB 9)
- [x] **PB-042 (Deteksi Lokasi Pengguna & Izin GPS):** Service `LocationService` dengan integrasi `geolocator`, pendeteksian koordinat pengguna secara real-time, tombol "Deteksi GPS Otomatis" di `HomeTab` & `CinemaMapView`, penyimpanan koordinat terakhir ke storage lokal (`GetStorage`), dan penanganan prompt perizinan Android & iOS yang aman tanpa crash.
- [x] **PB-043 (Daftar Bioskop Terdekat Terurut Jarak):** Kalkulasi jarak realtime setiap bioskop dari koordinat pengguna dengan formula *Haversine* dan pengurutan ascending (km) yang reaktif di `CinemaController` (`getCinemasSortedByDistance`).
- [x] **PB-044 (Peta Bioskop Interaktif `flutter_map`):** Visualisasi peta interaktif OpenStreetMap (OSM) via `CinemaMapView` (`Routes.cinemaMap`) tanpa API key berbayar, marker posisi user (pin biru dengan efek glowing), dan pin bioskop (merah/emas) yang interaktif memunculkan bottom modal detail bioskop.
- [x] **PB-045 (Filter Radius Jarak Bioskop):** Filter radius dinamis: `1 km`, `3 km`, `5 km`, `10 km`, `25 km`, dan `Semua Jarak`. Penanda peta & daftar bioskop tersaring secara real-time disertai indikator jumlah bioskop yang ditemukan.
- [x] **PB-046 (Rute & Navigasi Eksternal ke Google Maps):** Tombol *"Petunjuk Arah"* pada kartu & peta bioskop yang membuka aplikasi Google Maps eksternal via `url_launcher` dengan koordinat tujuan bioskop dan fallback geo URI.
- [x] **PB-047 (Fallback Offline & Pilihan Lokasi Manual):** Penyedia 10 titik acuan kota manual (Jakarta Pusat, Jakarta Selatan, Jakarta Utara, Depok, Tangerang, Bandung, Surabaya, Yogyakarta, Medan, Bali) agar LBS tetap berfungsi 100% mulus saat offline atau saat izin GPS ditolak.

### 8. Epic Konversi Mata Uang, Zona Waktu, Pintasan F&B & Profil (KNV / PRF / FNB — PB 10)
- [x] **PB-048 (Konversi Mata Uang Dinamis):** Helper `CurrencyHelper` mendukung konversi harga tiket dan F&B ke IDR, USD, SGD, EUR, JPY, dan GBP, lengkap dengan metadata waktu pembaruan kurs (TTL cache 12 jam) dan formatting locale akurat.
- [x] **PB-049 (Penyesuaian Zona Waktu Jam Tayang Film):** Helper `TimezoneHelper` menyesuaikan jadwal tayang film di seluruh aplikasi ke zona waktu pilihan (WIB UTC+7, WITA UTC+8, WIT UTC+9, dan London GMT/BST UTC+0/+1) lengkap dengan konversi jam rollover tengah malam.
- [x] **PB-050 (Selector Preferensi Mata Uang & Waktu di Profil):** `PreferenceController` reaktif dan modal bottom sheet pemilih mata uang & zona waktu di `ProfileTab` yang persisten ke local storage (`GetStorage`) serta pratinjau live konversi.
- [x] **PB-034 (Pintasan Menu F&B dari Halaman Lain):** Tombol pintasan *"Pesan F&B di Bioskop Ini"* di `TicketDetailView` untuk tiket aktif dan card pintasan `+ Tambah Popcorn & Minuman (F&B)` di `OrderSummaryView` yang otomatis mengunci bioskop terpilih.
- [x] **PB-035 (Stepper Pelacakan & Simulasi Status Pesanan F&B):** Layar `FnbOrderDetailView` dengan stepper visual dinamis (*Sedang Disiapkan* 🍳 $\rightarrow$ *Siap Diambil* 🍿 $\rightarrow$ *Selesai Diambil* ✅), E-Voucher QR Code, dan tombol simulasi status staf bioskop.
- [x] **PB-062 (Form Edit Profil Pengguna):** Layar `EditProfileView` (`Routes.editProfile`) dengan form edit nama lengkap, nomor telepon, dan selector lencana avatar anggota (Cinephile, VIP Gold, Director, Popcorn Fan, Sci-Fi Star) yang tersimpan di sesi lokal.

### 9. Epic Pencarian & Filter Multi-Kriteria (SRC — PB 11)
- [x] **PB-051 (Pencarian Multi-Entitas dengan Debounce 300ms):** Controller `AppSearchController` dengan debounce worker 300ms untuk input query tanpa lag, pencarian universal lintas 3 entitas (Film: judul, sinopsis, genre; Bioskop: nama, kota, alamat; F&B: nama menu, deskripsi, kategori), serta shortcut pencarian interaktif di AppBar & Dashboard `HomeTab`.
- [x] **PB-052 (Filter Pencarian Multi-Kriteria):** Filter tab kategori entitas (*Semua*, *Film*, *Bioskop*, *F&B*), filter genre film (Action, Animation, Comedy, Horror, dll.), filter rating tinggi ($\ge 7.0$ bintang), filter batas harga maksimal F&B, filter kota bioskop (Jakarta, Depok, Bandung, Surabaya), active filter chips bar dengan kemampuan hapus per chip, dan tombol *"Reset Filter"*.
- [x] **PB-053 (Pengurutan Hasil Pencarian):** Pilihan sorting hasil dinamis: *Rating Tertinggi* (rating film $\ge 7.0$ di atas), *Paling Populer* (popularity TMDB), *Harga Termurah* (F&B price ascending), *Jarak Terdekat* (bioskop distance ascending), dan *Abjad (A - Z)*.
- [x] **PB-054 (Riwayat 5 Pencarian Terakhir):** Menyimpan hingga 5 riwayat pencarian terakhir secara persisten di storage lokal dengan urutan LIFO, tombol hapus riwayat individual, tombol *"Hapus Semua Riwayat"*, dan aksi klik riwayat untuk langsung mengisi query pencarian.
- [x] **PB-055 (State Kosong, Skeleton Loading & Direct Actions):** Shimmer skeleton loading saat pencarian/filtering berlangsung, tampilan empty state ramah saat hasil tidak ditemukan beserta saran ejaan & tombol reset, kartu film dengan tombol direct *"Pesan Tiket"*, kartu bioskop dengan tombol *"Jadwal"*, serta kartu F&B dengan harga terkonversi.

### 12. Notifikasi Lokal & Pengingat Jadwal (PB 12 / PB-056 s.d. PB-060) [SELESAI ✅]
- [x] **PB-056 (Notifikasi Konfirmasi Pemesanan Tiket & F&B):** Notifikasi lokal instan saat checkout tiket bioskop atau pesanan F&B berhasil, memuat judul film, kode booking (`CNM-XXXXX` / `FNB-XXXXX`), rincian studio, dan payload terstruktur.
- [x] **PB-057 (Notifikasi Pengingat Jadwal Film Terjadwal):** Penjadwalan otomatis alarm notifikasi lokal H-2 jam dan H-30 menit sebelum film dimulai menggunakan `flutter_local_notifications` dan timezone lokal, serta pembatalan alarm otomatis jika tiket dibatalkan.
- [x] **PB-058 (Pengaturan Izin & Preferensi Notifikasi di Profil):** 4 switch toggle interaktif di `ProfileTab` (`notifBooking`, `notifReminder`, `notifFnb`, `notifPromo`) yang tersimpan persisten di local storage / Hive.
- [x] **PB-059 (Notifikasi Pengingat Pesanan F&B Siap Diambil):** Notifikasi lokal instan saat status pesanan F&B berubah menjadi *Ready* di counter concession atau delivery ke kursi studio.
- [x] **PB-060 (Notifikasi Penawaran Promo F&B Mingguan):** Simulasi berkala penawaran diskon combo popcorn & F&B dengan tombol "Kirim Notifikasi Uji Coba" langsung di layar profil pengguna.

### 13. Profil Lanjutan, My Cinemate & Riwayat AI (PB 13 / PB-061 s.d. PB-065) [SELESAI ✅]
- [x] **PB-061 (Unggah Foto Profil Pengguna):** Fitur ganti foto profil dari Kamera atau Galeri perangkat menggunakan `image_picker`, preview avatar interaktif dengan fallback lencana avatar bawaan saat offline atau jika dibatalkan.
- [x] **PB-063 (Halaman Pengaturan Aplikasi Lanjutan):** Layar pengaturan komprehensif (`SettingsView`) untuk preferensi tema aplikasi (*Cinematic Dark*, *Light*, *Mengikuti Sistem*), opsi keamanan login biometrik (Fingerprint / Face ID toggle), ringkasan preferensi aktif, dan pembersihan cache Hive.
- [x] **PB-064 (Layar "My Cinemate" Dashboard Penonton):** Dashboard personal penonton (`MyCinemateView`) yang menampilkan statistik jumlah film yang ditonton, estimasi jam tontonan, total belanja tiket & F&B, sistem badge loyalitas penonton (*Bronze*, *Silver*, *Gold*, *Platinum*), dan multi-select chips preferensi genre favorit yang tersimpan persisten.
- [x] **PB-065 (Riwayat Hasil Profiling AI Mood):** Penyimpanan riwayat hasil rekomendasi mood yang pernah dilakukan beserta tanggal/jam dan film-film yang disarankan secara LIFO di local storage, dengan opsi hapus riwayat individual & hapus semua.

### 14. Sinkronisasi Data & Hardening Kualitas (PB 14 / PB-066 s.d. PB-067) [SELESAI ✅]
- [x] **PB-066 (Sinkronisasi Otomatis Data Lokal & Cloud):** Deteksi konektivitas internet aktif dan reaktif (`connectivity_plus`), listener peralihan offline ke online otomatis, sinkronisasi dua arah Hive-Supabase dengan pencegahan duplikasi (*idempotency key check*), pembaruan status `is_synced: true`, serta sinkronisasi manual langsung dari menu Pengaturan.
- [x] **PB-067 (Optimasi Cold Start & Hardening Kualitas):** Benchmarking cold start inisialisasi aplikasi (< 4 detik / ~10-40 ms terukur), perlindungan crash resistance guard (`executeProtected` $\ge 98\%$), ketahanan terhadap data cache lokal JSON yang korup (*corrupted cache resilience*), penyesuaian layout responsif, dan standarisasi rilis.

---

## 🚀 Panduan Setup untuk Anggota Tim

1. **Clone repository:**
   ```bash
   git clone https://github.com/dyahnaylaamaliaputri-bit/Cinemate.git
   cd Cinemate
   ```
2. **Switch ke branch terbaru atau tarik update dari main:**
   ```bash
   git pull origin main
   ```
3. **Siapkan berkas `.env`:**
   Salin `assets/.env.example` menjadi `assets/.env`:
   ```bash
   cp assets/.env.example assets/.env
   ```
   Isi nilai `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan `TMDB_API_KEY` milik tim.
4. **Unduh dependensi:**
   ```bash
   flutter pub get
   ```
5. **Jalankan pengujian unit (Semua 195 Unit Test Wajib Passed):**
   ```bash
   flutter test
   ```
6. **Jalankan aplikasi di emulator atau HP:**
   ```bash
   flutter run
   ```
   *(Catatan untuk pengguna Windows: Pengaturan `kotlin.incremental=false` sudah diset di `android/gradle.properties` untuk mencegah bug cross-drive).*

---

### 15. Epic Chatbot Asisten AI Cinemate (AIL — PB 15 / PB-039 s.d. PB-041) [SELESAI ✅]
- [x] **PB-039 (Chatbot Interaktif Film, Bioskop, F&B & Jadwal):** Antarmuka CineBot estetik Dark Cinema dengan bubble chat responsif, input text bar, dan asisten cerdas yang menjawab pertanyaan terkait jadwal tayang, lokasi bioskop terdekat, camilan F&B, dan rekomendasi mood.
- [x] **PB-040 (Riwayat Percakapan Chatbot di Hive):** Persistensi riwayat percakapan secara otomatis ke Hive box `chat_history`, dapat dibaca offline, dan dilengkapi tombol konfirmasi bersihkan riwayat chat.
- [x] **PB-041 (Penanganan Error Cerdas & Rate Limiting):** Pembatasan kuota query chat (rate limiting 12 pesan/menit) dengan countdown timer jeda dan tombol retry interaktif saat error terjadi.

### 16. Epic Keamanan Akun & Autentikasi Biometrik (AUT — PB 16 / PB-009 s.d. PB-010) [SELESAI ✅]
- [x] **PB-009 (Login Biometrik Fingerprint & Face ID):** Integrasi `local_auth` perangkat nyata dengan konfigurasi `USE_BIOMETRIC` & `USE_FINGERPRINT` di AndroidManifest dan `FlutterFragmentActivity`. Mendukung quick biometric login di `LoginView` dan switch toggle preferensi di Pengaturan.
- [x] **PB-010 (Layar Ubah Kata Sandi Akun):** Layar `ChangePasswordView` dengan verifikasi hash lama, enkripsi salt + SHA-256 untuk kata sandi baru (minimal 8 karakter kombinasi huruf & angka), indikator kekuatan kata sandi, dan feedback interaktif.

### 17. Epic Rekomendasi AI Dashboard & Quick Access Chatbot (DSH — PB 17 / PB-016 s.d. PB-017) [SELESAI ✅]
- [x] **PB-016 (Widget Rekomendasi AI di Dashboard):** Integrasi kartu rekomendasi personal di `HomeTab` berdasarkan riwayat profiling mood pengguna terakhir lengkap dengan persentase kecocokan (*match score*), alasan rekomendasi AI, dan tombol langsung pesan tiket. Jika belum ada riwayat, otomatis menampilkan kartu ajakan AI interaktif.
- [x] **PB-017 (Akses Cepat Tombol Chatbot FAB & Detail Film):** Floating Action Button (FAB) CineBot di `HomeTab` dan kartu akses konsultasi cerdas *"Tanya CineBot"* di `MovieDetailView` dengan passing argument query otomatis.

### 18. Epic Profiling Mood Lanjutan & LLM Engine (AIL — PB 18 / PB-036 s.d. PB-038) [SELESAI ✅]
- [x] **PB-036 (Layanan LLM Terabstraksi & JSON Validation):** Abstraksi `LlmService` dengan validasi skema JSON ketat, pembangunan prompt terstruktur, dan mesin aturan kurasi offline (*Curated Rule-Based Fallback Engine*) yang sangat tangguh.
- [x] **PB-037 (Formulir Profiling Multi-Kriteria):** Layar `AdvancedProfilingView` dengan 4 kriteria terpadu: suasana hati (Mood), teman menonton (Sendiri, Pasangan, Keluarga, Teman), durasi film ideal, dan batas anggaran tiket (Budget limit).
- [x] **PB-038 (Kartu Hasil Rekomendasi & Alasan AI):** Kartu rekomendasi film terbaik dengan skor kecocokan tinggi (88% - 99%), tag kesesuaian teman menonton, kartu alasan AI mendalam, dan tombol pemesanan langsung tiket bioskop (`Routes.bookByMovie`).

### 19. Epic Pemilihan Kursi Interaktif & Concurrency Locking (SET — PB 19 / PB-027 s.d. PB-029) [SELESAI ✅]
- [x] **PB-027 (Seat Map Interaktif Multi-Studio):** Visualisasi denah kursi dinamis adaptif untuk Regular 2D (56 kursi), IMAX with Laser (120 kursi dengan baris Sweetbox sofa premium), dan The Premiere (24 kursi plush recliner). Pembatasan maksimal 6 kursi per pemesanan anti-calo dan kalkulasi subtotal harga instan.
- [x] **PB-028 (Pencegahan Pemesanan Ganda / Concurrency Collision):** Mekanisme penguncian kursi real-time via `SeatService` (`seat_locks` Supabase & Hive box `seat_locks_cache`). Mendeteksi bentrok saat dua pengguna memilih kursi sama dalam waktu bersamaan dan memuat ulang status kursi terkunci secara otomatis.
- [x] **PB-029 (Temporary Seat Hold Timer 10 Menit):** Penahanan kursi otomatis 10 menit (600 detik) dengan countdown timer visual di layar denah kursi dan auto-release kunci kursi kembali ke status *Available* saat waktu habis atau saat pesanan dibatalkan.

### 20. Epic Validasi E-Ticket, QR Scanner & Siklus Tiket Kedaluwarsa (TKT — PB 20 / PB-026 s.d. PB-026C) [SELESAI ✅]
- [x] **PB-026 (Penandaan Tiket Kedaluwarsa Otomatis):** Deteksi otomatis tiket yang waktu tayangnya telah terlewat (`showDateTime` / `isShowPassed`). Tiket secara otomatis diubah statusnya menjadi `expired` dan dipindahkan dari tab Tiket Aktif ke Riwayat Tontonan di Hive cache & Supabase saat aplikasi dibuka atau tiket dimuat.
- [x] **PB-026B (QR Scanner Check-in Petugas Bioskop):** Layar pemindai staf bioskop `CheckInScannerView` (`/check-in-scanner`) dengan animasi garis laser viewfinder, senter, pemindaian QR Code tiket penonton (`CNM-XXXXX`), validasi keaslian kode booking, pencegahan duplikasi check-in, dan fallback formulir input kode booking manual.
- [x] **PB-026C (Fitur Bagikan Tiket & Undangan Nonton):** Fitur bagikan ringkasan tiket dan undangan nonton bareng terstruktur (film, bioskop, studio, tanggal, jam tayang, nomor kursi, kode booking) di `TicketDetailView` via dialog sistem (`share_plus`) dengan fallback aman ke clipboard.

### 21. Epic Integrasi F&B Terpadu & Multi-Bioskop Concession (FNB — PB 21 / PB-032, PB-033, PB-035) [SELESAI ✅]
- [x] **PB-032 (Langkah Opsional Tambah Makanan Sebelum Checkout):** Integrasi penawaran camilan bioskop bundling hemat diskon Rp 10.000 (Combo Nonton Hemat, Combo Popcorn Duo, Combo Nachos Party) di layar `OrderSummaryView`. Bundling otomatis menyatu ke invoice tiket bioskop, memperbarui total tagihan secara instan, dan menerbitkan pesanan concession saat checkout berhasil.
- [x] **PB-033 (Pemesanan F&B Mandiri Tanpa Tiket Nonton):** Alur pemesanan makanan & minuman langsung dari katalog tanpa kewajiban memiliki tiket bioskop aktif. Pengambilan mandiri di counter concession terdekat dengan penerbitan kode pickup 5 digit `FNB-XXXXX` dan status awal `processing`.
- [x] **PB-035 (Stepper Pelacakan Status & Estimasi Penyiapan):** Stepper pelacakan pesanan dinamis (*Sedang Disiapkan 🍳* $\rightarrow$ *Siap Diambil 🍿* $\rightarrow$ *Selesai Diambil ✅*) di `FnbOrderDetailView` lengkap dengan estimasi menit penyiapan dinamis berdasarkan jumlah item dan tombol simulasi status staf concession.

---

## 🎯 Rekapitulasi Milestone & Pembagian Tugas Tim

> **📊 Status Pengerjaan Terkini:**  
> Seluruh modul **PB 1 s/d PB 21 (total 94+ user stories)** telah tuntas 100% dikerjakan dengan **195 unit tests lolos (100%)** dan 0 issue statis `dart analyze`.

---

## 📋 Catatan Status 4 PB (PB 15 s.d. PB 18) [SELESAI ✅]

Berikut adalah status pencapaian 4 Product Backlog (PB) yang telah diselesaikan:

### 📦 Tugas Rekan 1: Epic Chatbot Asisten AI Cinemate (AIL — PB 15)
*Menuntaskan asisten AI interaktif untuk tanya jawab film, sinopsis, jadwal bioskop, dan panduan tiket (PB-039 s.d. PB-041 / SRS §3.8 FR-043 s.d. FR-045)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria (Given-When-Then) | Status |
| :---: | :---: | :--- | :--- | :---: |
| 1 | **PB-039** | Chatbot Interaktif Film & Jadwal | **Given** pengguna mengetik pertanyaan pada input chat, **When** pesan dikirim, **Then** asisten AI merespons dengan konteks film, studio, dan jadwal bioskop yang relevan. | ✅ SELESAI |
| 2 | **PB-040** | Riwayat Percakapan Chatbot | **Given** percakapan berlangsung, **When** pengguna menutup dan membuka kembali chatbot, **Then** riwayat chat tersimpan di Hive box `chat_history` (dapat dibaca offline) dan dapat dihapus. | ✅ SELESAI |
| 3 | **PB-041** | Penanganan Error Cerdas & Rate Limiting | **Given** koneksi terputus atau batas kuota tercapai, **When** pesan dikirim, **Then** muncul bubble pesan error ramah, countdown waktu tunggu, dan tombol *"Coba Lagi"*. | ✅ SELESAI |

- **Target File yang Dikerjakan:**
  - `lib/services/chatbot_service.dart` (Service API LLM Gemini / heuristic responder dengan context injection jadwal & film)
  - `lib/controllers/chatbot_controller.dart` (Pengelolaan pesan reaktif, streaming typing effect, persistensi Hive)
  - `lib/views/chatbot/chatbot_view.dart` (Antarmuka chat bubble estetik Dark Cinema, input bar, dan scroll-to-bottom otomatis)
  - `test/chatbot_service_test.dart` (Unit test pengujian alur percakapan, parsing intent, dan penanganan fallback)

---

### 📦 Tugas Rekan 2: Epic Keamanan Akun & Autentikasi Biometrik (AUT — PB 16)
*Menuntaskan verifikasi biometrik perangkat nyata dan manajemen keamanan kata sandi pengguna (PB-009, PB-010 / SRS §3.2 FR-009, FR-010)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria (Given-When-Then) | Status |
| :---: | :---: | :--- | :--- | :---: |
| 1 | **PB-009** | Login Biometrik (Fingerprint & Face ID) | **Given** opsi biometrik aktif di preferensi, **When** pengguna membuka login atau verifikasi pembayaran tiket, **Then** sistem memanggil sensor biometrik perangkat (`local_auth`); jika gagal 3x atau dibatalkan, otomatis fallback ke password/PIN. | ✅ SELESAI |
| 2 | **PB-010** | Layar Ubah Password Pengguna | **Given** pengguna sedang login di `ProfileTab`, **When** memasukkan password lama dan password baru (minimal 8 karakter kombinasi), **Then** sistem memverifikasi hash lama, memperbarui password baru di storage/Supabase, dan mencabut sesi lain. | ✅ SELESAI |

- **Target File yang Dikerjakan:**
  - `lib/services/biometric_service.dart` (Integrasi plugin `local_auth`, pemeriksaan ketersediaan hardware, dan autentikasi biometrik)
  - `lib/views/auth/change_password_view.dart` (Layar formulir ganti password lengkap dengan toggle visibility mata dan validasi)
  - `lib/controllers/auth_controller.dart` (Penambahan metode `changePassword` dan `authenticateWithBiometrics`)
  - `test/auth_security_test.dart` (Unit test verifikasi keamanan pergantian password dan validasi biometrik)

---

### 📦 Tugas Rekan 3: Epic Rekomendasi AI Dashboard & Quick Access Chatbot (DSH — PB 17)
*Mengintegrasikan widget rekomendasi AI personal di dashboard dan shortcut akses cepat chatbot (PB-016, PB-017 / SRS §3.3 FR-016, FR-017)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria (Given-When-Then) | Status |
| :---: | :---: | :--- | :--- | :---: |
| 1 | **PB-016** | Widget Rekomendasi AI di Dashboard | **Given** pengguna pernah melakukan mood profiling, **When** Dashboard dibuka, **Then** kartu rekomendasi film terakhir tampil di `HomeTab`; **Given** belum pernah, **Then** tampil kartu ajakan personal interaktif. | ✅ SELESAI |
| 2 | **PB-017** | Akses Cepat Tombol Chatbot (Floating FAB) | **Given** pengguna berada di Dashboard atau Detail Film, **When** menekan tombol chatbot melayang (*Floating Action Button*), **Then** halaman chatbot langsung terbuka dalam 1 ketukan. | ✅ SELESAI |

- **Target File yang Dikerjakan:**
  - `lib/views/dashboard/tabs/home_tab.dart` (Penambahan widget kartu rekomendasi AI personal dan Floating Action Button chatbot)
  - `lib/controllers/home_controller.dart` (Pemeriksaan riwayat rekomendasi AI lokal saat inisialisasi tab home)
  - `test/home_dashboard_ai_test.dart` (Unit test verifikasi render kartu rekomendasi AI dan integrasi tombol cepat)

---

### 📦 Tugas Rekan 4: Epic Profiling Mood Lanjutan & LLM Engine (AIL — PB 18)
*Menuntaskan formulir profiling penonton multi-kriteria dan integrasi prompt engine LLM terstruktur (PB-036 s.d. PB-038 / SRS §3.8 FR-039 s.d. FR-041)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria (Given-When-Then) | Status |
| :---: | :---: | :--- | :--- | :--- | :---: |
| 1 | **PB-036** | Layanan LLM Terabstraksi & JSON Validation | **Given** prompt dan format schema JSON terdefinisi, **When** LLM merespons, **Then** output divalidasi ke data film nyata; jika API gagal, otomatis fallback ke rule-based curated engine. | ✅ SELESAI |
| 2 | **PB-037** | Formulir Profiling Multi-Kriteria | **Given** layar profiling dibuka, **When** pengguna mengisi mood, teman nonton (Sendiri/Pasangan/Keluarga), durasi film, dan batas budget, **Then** input divalidasi dan tombol Cari Film aktif. | ✅ SELESAI |
| 3 | **PB-038** | Kartu Hasil Rekomendasi & Alasan AI | **Given** profiling selesai, **When** hasil ditampilkan, **Then** muncul kartu rekomendasi dengan analisis alasan AI Cinemate serta tombol direct booking tiket bioskop. | ✅ SELESAI |

- **Target File yang Dikerjakan:**
  - `lib/services/llm_service.dart` (Abstraksi pemanggilan model LLM, schema prompt JSON, dan fallback rule engine)
  - `lib/views/mood/advanced_profiling_view.dart` (Formulir interaktif multi-step kriteria penonton)
  - `lib/controllers/mood_controller.dart` (Pengelolaan state formulir profiling lanjutan dan integrasi hasil)
  - `test/llm_profiling_test.dart` (Unit test validasi JSON LLM, fallback rule engine, dan data model hasil profiling)

---

## 📋 Catatan Tugas untuk Rekan Tim (4 PB Lanjutan: PB 19 s.d. PB 22)

Berikut adalah 4 Product Backlog (PB) berikutnya yang dialokasikan secara adil dan terstruktur untuk dikerjakan oleh rekan tim:

### 📦 Tugas Rekan 1: Epic Pemilihan Kursi Interaktif & Concurrency Locking (SET — PB 19) [SELESAI ✅]
*Menuntaskan visualisasi denah kursi bioskop, batas maksimal pemesanan, dan mekanisme penguncian kursi real-time (PB-027 s.d. PB-029 / SRS §3.4 FR-024 s.d. FR-027, NFR-010, NFR-017)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria (Given-When-Then) | Status |
| :---: | :---: | :--- | :--- | :---: |
| 1 | **PB-027** | Seat Map Interaktif Multi-Studio | **Given** jadwal bioskop dan studio dipilih (Regular, IMAX, Premiere), **When** seat map dibuka, **Then** denah kursi interaktif (hingga 200 kursi) menampilkan status *Available*, *Booked*, *Selected*, dan *Locked*; membatasi maksimal 6 kursi per transaksi dan subtotal harga terhitung instan. | ✅ SELESAI |
| 2 | **PB-028** | Pencegahan Pemesanan Ganda (Concurrency Collision) | **Given** dua pengguna memilih kursi yang sama dalam rentang waktu bersamaan, **When** keduanya menekan konfirmasi, **Then** hanya satu pengguna yang berhasil mengunci kursi dan pengguna lain menerima pemberitahuan ramah serta status kursi terkunci dimuat ulang otomatis. | ✅ SELESAI |
| 3 | **PB-029** | Temporary Seat Hold Timer (10 Menit) | **Given** pengguna telah memilih kursi dan melanjutkan ke ringkasan pesanan, **When** proses checkout dimulai, **Then** kursi dikunci sementara selama 10 menit dengan countdown timer visual, dan otomatis dilepas kembali ke status *Available* jika waktu habis atau pesanan dibatalkan. | ✅ SELESAI |

- **File yang Telah Dibuat & Teruji:**
  - `lib/models/seat_lock_model.dart` (Model temporary hold & concurrency lock kursi bioskop)
  - `lib/models/seat_model.dart` (Status locked, seat types sweetbox & recliner)
  - `lib/services/seat_service.dart` (Service manajemen lock kursi, collision detection, auto-release Hive & Supabase)
  - `lib/controllers/booking_seat_controller.dart` (Multi-studio layout, batas 6 kursi, hold timer 10 menit & collision handling)
  - `lib/views/booking/select_seat_view.dart` (Antarmuka seating plan adaptif, banner timer 10 menit, 4 status kursi & legend)
  - `test/seat_selection_concurrency_test.dart` (16 Unit tests lengkap lolos 100%)

---

### 📦 Tugas Rekan 2: Epic Validasi E-Ticket, QR Scanner & Siklus Tiket Kedaluwarsa (TKT — PB 20) [SELESAI ✅]
*Menuntaskan siklus penutupan tiket otomatis, scanner kamera petugas bioskop, dan fitur berbagi tiket (PB-026 / SRS §3.4 FR-023, FR-031 s.d. FR-033)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria (Given-When-Then) | Status |
| :---: | :---: | :--- | :--- | :---: |
| 1 | **PB-026** | Penandaan Tiket Kedaluwarsa Otomatis | **Given** jadwal film telah lewat dari tanggal dan jam tayang saat ini, **When** aplikasi dibuka atau tab Tiket dimuat, **Then** status tiket otomatis berubah menjadi *Expired* dan dipindahkan dari tab Tiket Aktif ke Riwayat Tontonan secara otomatis di Hive & Supabase. | Selesai ✅ |
| 2 | **PB-026B** | QR Scanner Check-in Petugas Bioskop | **Given** petugas bioskop membuka menu Scanner Check-in (`CheckInScannerView`), **When** kamera memindai QR Code e-ticket penonton (`CNM-XXXXX`), **Then** sistem memvalidasi keaslian kode booking, menampilkan data tiket penonton, dan mengubah status menjadi *Checked-in* / *Used* secara offline & online. | Selesai ✅ |
| 3 | **PB-026C** | Fitur Bagikan Tiket & Undangan Nonton | **Given** tiket bioskop aktif terbuka di `TicketDetailView`, **When** pengguna menekan tombol *"Bagikan Tiket"*, **Then** aplikasi membuka dialog share sistem untuk membagikan kartu ringkasan tiket (judul film, bioskop, jam, studio, nomor kursi) ke WhatsApp / media sosial. | Selesai ✅ |

- **Target File yang Dikerjakan:**
  - `lib/views/ticket/check_in_scanner_view.dart` (Layar pemindai QR Code menggunakan kamera atau simulasi scanner staf bioskop)
  - `lib/controllers/tickets_controller.dart` (Logika otomatis filter tiket kedaluwarsa & pembaruan status check-in)
  - `lib/views/ticket/ticket_detail_view.dart` (Penambahan tombol aksi bagikan tiket & status lencana)
  - `test/ticket_lifecycle_scanner_test.dart` (Unit test validasi siklus kedaluwarsa tiket dan pemindaian QR code)

---

### 📦 Tugas Rekan 3: Epic Integrasi F&B Terpadu & Multi-Bioskop Concession (FNB — PB 21) [SELESAI ✅]
*Menuntaskan alur pemesanan makanan bundling tiket bioskop, pemesanan mandiri, dan pelacakan pesanan (PB-032, PB-033, PB-035 / SRS §3.5 FR-028, FR-036 s.d. FR-038)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria (Given-When-Then) | Status |
| :---: | :---: | :--- | :--- | :---: |
| 1 | **PB-032** | Langkah Opsional Tambah Makanan Sebelum Checkout | **Given** pengguna telah memilih kursi dan berada di alur booking tiket, **When** sebelum masuk ringkasan pesanan akhir, **Then** muncul langkah opsional penawaran snack combo F&B diskon Rp 10.000 yang langsung terintegrasi menyatu dengan total pembayaran tiket. | Selesai ✅ |
| 2 | **PB-033** | Pemesanan F&B Mandiri Tanpa Tiket Nonton | **Given** pengguna membuka tab Pesan Makanan, **When** pengguna memilih menu dan bioskop concession terdekat tanpa tiket bioskop aktif, **Then** alur checkout mandiri berjalan lancar dengan opsi ambil di counter concession dan penerbitan kode pickup `FNB-XXXXX`. | Selesai ✅ |
| 3 | **PB-035** | Stepper Pelacakan Status & Estimasi Penyiapan | **Given** pesanan F&B telah dibayar, **When** pengguna membuka layar `FnbOrderDetailView`, **Then** tampil stepper status dinamis (*Sedang Disiapkan* 🍳 $\rightarrow$ *Siap Diambil* 🍿 $\rightarrow$ *Selesai Diambil* ✅), estimasi menit penyiapan, dan tombol simulasi staf concession. | Selesai ✅ |

- **Target File yang Dikerjakan:**
  - `lib/views/booking/order_summary_view.dart` (Integrasi bundling menu F&B ke dalam invoice tiket bioskop)
  - `lib/views/fnb/fnb_checkout_view.dart` & `lib/views/fnb/fnb_order_detail_view.dart` (Penyempurnaan alur pickup mandiri dan stepper)
  - `lib/controllers/fnb_controller.dart` (State management pesanan mandiri, bundling diskon, dan pelacakan stepper)
  - `test/fnb_integration_lifecycle_test.dart` (Unit test alur bundling F&B, pemesanan mandiri, dan stepper status)

---

### 📦 Tugas Rekan 4: Epic Loyalitas Pengguna, Gamifikasi & Rekomendasi Sosial (PRF / DSH — PB 22)
*Menuntaskan sistem penghargaan badge loyalitas penonton, analisis statistik tontonan, dan riwayat AI (PB-064, PB-065 / SRS §3.8 FR-070, FR-071)*

| No | Backlog ID | Nama Fitur / User Story | Cakupan Teknis & Acceptance Criteria (Given-When-Then) | Status |
| :---: | :---: | :--- | :--- | :---: |
| 1 | **PB-064** | Gamifikasi Badge Loyalitas & Statistik Penonton | **Given** pengguna telah menonton film di Cinemate, **When** membuka menu *My Cinemate*, **Then** tampil statistik total film, jam tontonan, pengeluaran, progress bar kenaikan level (*Bronze* $\rightarrow$ *Silver* $\rightarrow$ *Gold* $\rightarrow$ *Platinum Cinema Maestro*), dan grafik donat genre favorit. | ⏳ Siap Dikerjakan |
| 2 | **PB-064B** | Kartu Undangan Nonton Bareng (Watch Party Card) | **Given** pengguna melihat detail film atau jadwal yang diminati, **When** menekan tombol *"Ajak Teman Nobar"*, **Then** aplikasi menghasilkan kartu ajakan estetik berisi judul film, poster, bioskop, dan link deep link untuk dibagikan ke teman. | ⏳ Siap Dikerjakan |
| 3 | **PB-065** | Linimasa Riwayat Profiling AI & Komparasi Mood | **Given** pengguna sering melakukan profiling mood AI, **When** membuka riwayat profiling di Profil, **Then** tampil linimasa riwayat emosi pengguna dari waktu ke waktu (*mood tracker timeline*), perbandingan film yang disarankan, dan filter riwayat berdasarkan tanggal. | ⏳ Siap Dikerjakan |

- **Target File yang Dikerjakan:**
  - `lib/views/profile/my_cinemate_view.dart` (Visualisasi statistik tontonan, progress bar level loyalitas, dan grafik genre)
  - `lib/views/profile/mood_history_view.dart` (Layar linimasa riwayat mood dan perbandingan rekomendasi film)
  - `lib/controllers/profile_controller.dart` (Kalkulasi otomatis poin loyalitas dari tiket aktif & riwayat)
  - `test/loyalty_gamification_test.dart` (Unit test perhitungan badge loyalitas penonton, riwayat AI, dan data statistik)

---

### 🌿 Panduan Branching Git untuk Rekan Tim

Rekan tim dapat langsung menarik kode terbaru dari branch `main` dan membuat branch baru untuk mengerjakan tugas PB 19 s.d. PB 22:

```bash
# 1. Pastikan branch main lokal up-to-date:
git checkout main
git pull origin main

# 2. Buat branch fitur baru untuk pengerjaan 4 PB:
git checkout -b feat/tugas-rekan-pb19-pb22

# Atau jika ingin dikerjakan per modul PB:
git checkout -b feat/pb-027-029-seat-concurrency-locking
git checkout -b feat/pb-026-ticket-scanner-expiry
git checkout -b feat/pb-032-035-fnb-bundling-stepper
git checkout -b feat/pb-064-065-loyalty-watchparty-timeline
```

---

### 📌 Standar Koding & Pengujian Sebelum Pull Request (PR)

1. **Arsitektur GetX OOP & 100% Offline-First:**
   - Pisahkan logika ke `Controller`, data/cache ke `Service`/`Utils`, dan antarmuka ke `View`.
   - Wajib berjalan mulus dalam mode offline dengan fallback data lokal / Hive tanpa Supabase.
   - Gunakan palet warna konsisten dari `AppColors` (*Dark Cinema Palette: `#0A0A0A`, `#E50914`, `#1A1A2E`, `#FFD700`*).
2. **Checklist Wajib Sebelum Commit & Push:**
   ```bash
   # 1. Pastikan tidak ada error atau warning:
   dart analyze lib test

   # 2. Jalankan seluruh unit test (wajib 100% passed):
   flutter test

   # 3. Format kode:
   dart format lib test
   ```
3. **Keamanan Kredensial:**
   - Jangan pernah melakukan commit berkas `assets/.env`.
