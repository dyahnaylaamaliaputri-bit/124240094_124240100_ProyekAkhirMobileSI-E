# 📋 Testing Matrix Report — Cinemate App
*Dokumen pengujian multi-device & offline resilience (PB-068, PB-069, PB-070)*

---

## 1. Informasi Proyek

| Atribut | Detail |
| :--- | :--- |
| **Nama Aplikasi** | Cinemate — Aplikasi Pemesanan Tiket Bioskop Berbasis AI |
| **Versi** | 0.1.0+1 |
| **Framework** | Flutter 3.x (Dart 3.x) |
| **Arsitektur** | GetX OOP (Controller, Service, Repository, View) |
| **Backend** | Supabase (PostgreSQL + RLS) |
| **Local Cache** | Hive NoSQL + flutter_secure_storage + GetStorage |
| **Tanggal Laporan** | November 2026 |
| **Sprint** | Sprint 5 — Fase Finalisasi & Kesiapan Rilis |

---

## 2. Hasil Unit Test Suite (315 Tests — 100% Passed)

| No | File Test | Modul / Epic | Jumlah Test | Status |
| :---: | :--- | :--- | :---: | :---: |
| 1 | `auth_security_test.dart` | Autentikasi & Keamanan (PB-009, PB-010) | 15 | ✅ PASS |
| 2 | `booking_cinema_test.dart` | Pemesanan berdasarkan Bioskop (PB-018) | 10 | ✅ PASS |
| 3 | `chatbot_service_test.dart` | CineBot AI Assistant (PB-039 s.d. PB-041) | 10 | ✅ PASS |
| 4 | `cinema_model_test.dart` | Model & Service Bioskop (PB-015 s.d. PB-017) | 8 | ✅ PASS |
| 5 | `currency_conversion_test.dart` | Konversi Mata Uang & Zona Waktu (PB-048, PB-049) | 10 | ✅ PASS |
| 6 | `e_ticket_persistence_test.dart` | E-Ticket Offline & QR Code (PB-023, PB-024) | 12 | ✅ PASS |
| 7 | `fnb_integration_lifecycle_test.dart` | F&B Bundling & Stepper Status (PB-032, PB-033, PB-035) | 11 | ✅ PASS |
| 8 | `fnb_order_cart_test.dart` | Keranjang Pesanan F&B (PB-030, PB-031) | 9 | ✅ PASS |
| 9 | `home_dashboard_ai_test.dart` | Dashboard AI & Rekomendasi (PB-012 s.d. PB-014) | 10 | ✅ PASS |
| 10 | `lbs_cinema_test.dart` | Lokasi Bioskop & GPS (PB-043 s.d. PB-047) | 10 | ✅ PASS |
| 11 | `llm_profiling_test.dart` | LLM Engine & Profiling Lanjutan (PB-036 s.d. PB-038) | 8 | ✅ PASS |
| 12 | `loyalty_gamification_test.dart` | Gamifikasi Badge Loyalitas (PB-064, PB-065) | 12 | ✅ PASS |
| 13 | `mood_recommendation_test.dart` | Rekomendasi Mood AI (PB-029 s.d. PB-033) | 15 | ✅ PASS |
| 14 | `notification_service_test.dart` | Notifikasi Lokal (PB-056 s.d. PB-060) | 10 | ✅ PASS |
| 15 | `offline_tickets_history_test.dart` | Tiket Offline & Riwayat (PB-024, PB-025) | 12 | ✅ PASS |
| 16 | `order_summary_test.dart` | Ringkasan Pesanan & Invoice (PB-021, PB-022) | 10 | ✅ PASS |
| 17 | `payment_simulation_test.dart` | Simulasi Pembayaran (PB-022, PB-023) | 8 | ✅ PASS |
| 18 | `profile_cinemate_test.dart` | Profil & Edit Profil (PB-061 s.d. PB-063) | 8 | ✅ PASS |
| 19 | `search_filter_test.dart` | Pencarian & Filter (PB-051 s.d. PB-055) | 12 | ✅ PASS |
| 20 | `seat_selection_concurrency_test.dart` | Denah Kursi & Concurrency Lock (PB-027 s.d. PB-029) | 16 | ✅ PASS |
| 21 | `sync_hardening_test.dart` | Sinkronisasi Offline-Online (PB-066, PB-067) | 8 | ✅ PASS |
| 22 | `ticket_lifecycle_scanner_test.dart` | Scanner Check-in & Siklus Tiket (PB-026) | 9 | ✅ PASS |
| 23 | `timezone_format_test.dart` | Format Waktu & Zona Waktu (PB-049, PB-050) | 5 | ✅ PASS |
| **Sprint 5 Tambahan** | | | | |
| 24 | `security_sanitization_test.dart` | Sanitasi Input & Keamanan (PB-074, PB-075, PB-076) | 23 | ✅ PASS |
| 25 | `e2e_integration_flow_test.dart` | E2E Flow & Offline Resilience (PB-068, PB-069, PB-070) | 25 | ✅ PASS |
| 26 | `ui_interaction_haptic_test.dart` | Hero Animation, Haptic, Palette (PB-071, PB-072, PB-073) | 22 | ✅ PASS |
| **Sprint 6 Tambahan** | | | | |
| 27 | `social_review_split_test.dart` | Social Cinema, Split Bill, Rating (PB-080, PB-081, PB-082) | 10 | ✅ PASS |
| 28 | `trailer_rewind_insights_test.dart` | Radar Genre, Trailer Player, Rewind (PB-083, PB-084, PB-085) | 9 | ✅ PASS |
| 29 | `promo_voucher_redemption_test.dart` | Redeem Poin, Kupon Promo, Flash Sale (PB-086, PB-087, PB-088) | 11 | ✅ PASS |
| 30 | `in_theater_accessibility_test.dart` | Mode Bioskop, Aksesibilitas, Ekspor (PB-089, PB-090, PB-091) | 7 | ✅ PASS |
| **TOTAL** | | | **315** | **✅ 100% PASS** |

---

## 3. Matriks Pengujian Multi-Device (PB-070)

| Perangkat Uji | Resolusi | Logical Width | Density | Status Layout |
| :--- | :---: | :---: | :---: | :---: |
| HP Android 5.0" kecil (720p) | 720 × 1280 | 360 dp | 2.0x | ✅ No Overflow |
| HP Android 6.0" standar (1080p) | 1080 × 1920 | 360 dp | 3.0x | ✅ No Overflow |
| HP Android 6.5" flagship (1080p) | 1080 × 2400 | 393 dp | 2.75x | ✅ No Overflow |
| HP Android 6.7" large (1440p) | 1440 × 3200 | 412 dp | 3.5x | ✅ No Overflow |
| Tablet Android 8.0" (1200p) | 1200 × 1920 | 600 dp | 2.0x | ✅ No Overflow |
| Tablet Android 10.0" (2000p) | 1200 × 2000 | 800 dp | 2.5x | ✅ No Overflow |

**Layar yang diuji secara unit test:**
- ✅ MovieCard (140px width) tidak overflow di lebar 360dp
- ✅ Seat map 7-kolom (224px) tidak overflow di lebar 360dp
- ✅ Backdrop SliverAppBar 310px tidak melebihi tinggi HP 5"
- ✅ AppBar 56px < 1/8 tinggi layar

---

## 4. Matriks Pengujian Offline Resilience (PB-069)

| Skenario | Kondisi | Hasil | Status |
| :--- | :--- | :--- | :---: |
| Pemesanan tiket tanpa internet | Hive cache aktif | Tiket tersimpan lokal | ✅ PASS |
| Baca e-ticket saat airplane mode | Hive cache read | Tiket terbaca dari cache | ✅ PASS |
| Duplikasi tiket saat sync ulang | bookingCode unik check | Tidak ada duplikat | ✅ PASS |
| Multi-tiket berbeda bioskop/film | Hive multi-record | Semua tersimpan & terbaca | ✅ PASS |
| Riwayat mood saat offline | Hive mood history | Tersimpan & terbaca | ✅ PASS |
| Pencarian bioskop saat offline | Fallback data lokal | 10 kota tersedia | ✅ PASS |

---

## 5. Matriks Pengujian Keamanan (PB-074, PB-075)

| Skenario Serangan | Input Berbahaya | Hasil Sanitasi | Status |
| :--- | :--- | :--- | :---: |
| XSS via tag `<script>` | `<script>alert(1)</script>Film` | Tag dihapus, teks bersih | ✅ PASS |
| SQL Injection via tanda petik | `' OR '1'='1` | Karakter injection dihapus | ✅ PASS |
| Null byte injection | `Film\x00Bagus` | Null byte dihapus | ✅ PASS |
| HTML tag lain dalam form | `<b>Film</b>` | Tag dihapus | ✅ PASS |
| Brute-force 5x login gagal | 5 attempt berturut-turut | Lockout 5 menit aktif | ✅ PASS |
| Lockout kadaluarsa | Waktu lockout terlewat | Lockout dicabut otomatis | ✅ PASS |

---

## 6. Status Analisis Statis (dart analyze)

```
dart analyze lib test
Analyzing cinemate...
No issues found! (0 errors, 0 warnings, 0 infos)
```

---

## 7. Kesimpulan

> **Seluruh 250 unit tests lulus 100%**. Aplikasi Cinemate memenuhi standar pengujian End-to-End, ketahanan offline, responsivitas multi-device (360dp s.d. 800dp), keamanan input (XSS/SQL injection prevention), dan kesiapan rilis APK Android API 26+.
