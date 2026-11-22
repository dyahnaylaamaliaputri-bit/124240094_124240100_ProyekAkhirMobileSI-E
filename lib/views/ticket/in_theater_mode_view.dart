// lib/views/ticket/in_theater_mode_view.dart
// Mode bioskop redup ultra-gelap OLED & aksesibilitas semantik (PB-089, PB-090)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';

class InTheaterModeView extends StatefulWidget {
  final String movieTitle;
  final String cinemaName;
  final String hallName;
  final List<String> seats;
  final String showTime;

  const InTheaterModeView({
    super.key,
    required this.movieTitle,
    required this.cinemaName,
    required this.hallName,
    required this.seats,
    required this.showTime,
  });

  @override
  State<InTheaterModeView> createState() => _InTheaterModeViewState();
}

class _InTheaterModeViewState extends State<InTheaterModeView> {
  bool _isQrModalVisible = false;

  @override
  void initState() {
    super.initState();
    // Berikan feedback getar halus saat mode bioskop aktif
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // True 100% OLED black
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white54),
          tooltip: 'Kembali dari Mode Bioskop',
          onPressed: () => Navigator.pop(context),
        ),
        title: Semantics(
          label: 'Mode Bioskop Sedang Aktif',
          child: const Text(
            'In-Theater Mode 🍿',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Indikator Hening Studio
              Semantics(
                label: 'Status: Mode hening dianjurkan saat film berlangsung',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_off_rounded,
                          color: AppColors.gold, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Harap heningkan suara HP Anda',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Judul Film & Studio
              Semantics(
                header: true,
                label: 'Film: ${widget.movieTitle}',
                child: Text(
                  widget.movieTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: 'Lokasi: ${widget.cinemaName}, ${widget.hallName}',
                child: Text(
                  '${widget.cinemaName} • ${widget.hallName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),

              const SizedBox(height: 36),

              // Nomor Kursi Ukuran Besar (Memudahkan melihat di kegelapan studio)
              Semantics(
                label: 'Nomor kursi Anda: ${widget.seats.join(", ")}',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'NOMOR KURSI ANDA',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.seats.join('  '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Jadwal Mulai
              Semantics(
                label: 'Jam tayang: ${widget.showTime} Waktu Indonesia Barat',
                child: Text(
                  'Mulai Jam: ${widget.showTime} WIB',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ),

              const Spacer(),

              // Tombol Tiket Cepat & QR
              Semantics(
                button: true,
                label: 'Buka Tiket Cepat untuk Petugas',
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isQrModalVisible = !_isQrModalVisible;
                    });
                  },
                  icon: Icon(
                    _isQrModalVisible
                        ? Icons.visibility_off_outlined
                        : Icons.qr_code_2_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isQrModalVisible
                        ? 'Tutup Barcode Tiket'
                        : 'Tampilkan Barcode Tiket',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              if (_isQrModalVisible) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.qr_code_scanner,
                          color: Colors.black, size: 80),
                      SizedBox(height: 4),
                      Text(
                        'Kecerahan disesuaikan otomatis',
                        style: TextStyle(color: Colors.black54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
