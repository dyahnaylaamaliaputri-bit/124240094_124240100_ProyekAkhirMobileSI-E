// lib/views/ticket/check_in_scanner_view.dart
// Layar Pemindai QR Code Check-in Petugas Bioskop (PB-026B)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/tickets_controller.dart';
import '../../models/ticket_model.dart';
import '../../utils/app_colors.dart';

class CheckInScannerView extends StatefulWidget {
  const CheckInScannerView({super.key});

  @override
  State<CheckInScannerView> createState() => _CheckInScannerViewState();
}

class _CheckInScannerViewState extends State<CheckInScannerView>
    with SingleTickerProviderStateMixin {
  late final TicketsController _ticketsController;
  final TextEditingController _codeController = TextEditingController();
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  bool _isTorchOn = false;
  bool _isFrontCamera = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _ticketsController = Get.isRegistered<TicketsController>()
        ? Get.find<TicketsController>()
        : Get.put(TicketsController());

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _laserAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Eksekusi validasi check-in tiket
  Future<void> _processCheckIn(String rawCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Haptic feedback simulasi scan
    HapticFeedback.mediumImpact();

    final result =
        await _ticketsController.validateAndCheckInBookingCode(rawCode);

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result.success && result.ticket != null) {
      _showSuccessDialog(result.ticket!, result.message);
      _codeController.clear();
    } else {
      _showErrorDialog(result.message, result.ticket);
    }
  }

  /// Dialog Sukses Check-in
  void _showSuccessDialog(TicketModel ticket, String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF131326),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Animated icon sukses
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 52,
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'CHECK-IN BERHASIL!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Akses Masuk Studio Diizinkan (PB-026B)',
                style: TextStyle(color: AppColors.success, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Detail Kartu Tiket
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ticket.movieTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            ticket.bookingCode,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      Icons.movie_creation_rounded,
                      'Bioskop & Studio',
                      '${ticket.cinemaName} • ${ticket.hallName}',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.schedule_rounded,
                      'Jadwal Penayangan',
                      '${ticket.formattedShowDate} • ${ticket.showTime} WIB',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.event_seat_rounded,
                      'Nomor Kursi',
                      '${ticket.seatsLabel} (${ticket.seatCount} Kursi)',
                      highlightValue: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const Text(
                    'Pindai Tiket Berikutnya',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dialog Check-in Gagal / Ditolak
  void _showErrorDialog(String reason, TicketModel? ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF131326),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Animated icon error
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error, width: 2),
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  color: AppColors.error,
                  size: 52,
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'CHECK-IN DITOLAK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Akses Masuk Tidak Diizinkan',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      reason,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (ticket != null) ...[
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.divider, height: 1),
                      const SizedBox(height: 10),
                      Text(
                        'Film: ${ticket.movieTitle}\nKode Booking: ${ticket.bookingCode}',
                        style: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E2E3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup / Coba Lagi',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value,
      {bool highlightValue = false}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 16),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(color: AppColors.textDisabled, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: highlightValue ? AppColors.gold : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scanner Check-in Bioskop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pindai QR Code e-ticket penonton (PB-026B)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? AppColors.gold : Colors.white70,
            ),
            tooltip: 'Senter Kamera',
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.cameraswitch_rounded,
              color: _isFrontCamera ? AppColors.gold : Colors.white70,
            ),
            tooltip: 'Ganti Kamera',
            onPressed: () {
              setState(() => _isFrontCamera = !_isFrontCamera);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Viewfinder Scanner Area
              _buildViewfinderSection(),

              const SizedBox(height: 20),

              // Bagian Manual Input Booking Code (PB-026B)
              _buildManualInputSection(),

              const SizedBox(height: 16),

              // Quick Test Chips (Memudahkan pengujian jika ada tiket aktif di controller)
              _buildQuickTestSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Viewfinder Scanner dengan Animasi Laser
  Widget _buildViewfinderSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Grid background simulasi kamera
            CustomPaint(
              size: const Size(double.infinity, 280),
              painter: _CameraGridPainter(),
            ),

            // Target Frame Pembidik
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Siku-siku bingkai (Corner Brackets)
                  ..._buildCornerBrackets(),

                  // Garis laser scanning bergerak
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 200 * _laserAnimation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Hint teks di bawah bingkai
            Positioned(
              bottom: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        color: AppColors.gold, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Arahkan kamera ke QR Code e-ticket',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Indikator Loading Processing
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.gold),
                      SizedBox(height: 12),
                      Text(
                        'Memvalidasi Tiket...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const size = 20.0;
    const thickness = 3.5;
    const color = AppColors.gold;

    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
    ];
  }

  /// Bagian Form Manual Input Booking Code (PB-026B Fallback)
  Widget _buildManualInputSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.keyboard_rounded,
                  color: AppColors.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'Input Manual Kode Booking (Fallback)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Gunakan jika kamera perangkat rusak, QR Code penonton tidak terbaca, atau testing di emulator.',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
          ),
          const SizedBox(height: 14),

          // Input field
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'CONTOH: CNM-12345',
              hintStyle: const TextStyle(
                color: AppColors.textDisabled,
                letterSpacing: 1,
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.confirmation_number_outlined,
                  color: AppColors.gold, size: 20),
              suffixIcon: _codeController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Colors.white70, size: 18),
                      onPressed: () {
                        setState(() => _codeController.clear());
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.card,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                _processCheckIn(val.trim());
              }
            },
          ),
          const SizedBox(height: 12),

          // Tombol Validasi & Check-in
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.how_to_reg_rounded, size: 18),
              label: const Text(
                'Validasi & Check-in Petugas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _codeController.text.trim().isEmpty || _isProcessing
                  ? null
                  : () => _processCheckIn(_codeController.text.trim()),
            ),
          ),
        ],
      ),
    );
  }

  /// Pintasan Tiket Aktif untuk Memudahkan Pengujian
  Widget _buildQuickTestSection() {
    return Obx(() {
      final active = _ticketsController.activeTickets;
      if (active.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141420),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app_rounded, color: AppColors.gold, size: 16),
                SizedBox(width: 6),
                Text(
                  'Uji Coba Cepat (Tiket Aktif Tersedia)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: active.take(3).map((t) {
                return ActionChip(
                  backgroundColor: AppColors.card,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5)),
                  avatar: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.gold, size: 16),
                  label: Text(
                    '${t.bookingCode} (${t.movieTitle})',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  onPressed: () {
                    _codeController.text = t.bookingCode;
                    _processCheckIn(t.bookingCode);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}

/// Painter garis-garis halus untuk viewfinder kamera
class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const step = 35.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
