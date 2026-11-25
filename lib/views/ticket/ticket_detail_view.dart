// lib/views/ticket/ticket_detail_view.dart
// Halaman Detail E-Ticket bioskop dengan QR Code & Akses Offline (PB-022, PB-024, PB-025)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/fnb_controller.dart';
import '../../controllers/ticket_detail_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';

class TicketDetailView extends GetView<TicketDetailController> {
  const TicketDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
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
              'E-Ticket Bioskop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Tunjukkan kode QR saat masuk studio',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            tooltip: 'Bagikan Tiket',
            onPressed: controller.shareTicket,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Badge Mode Offline Ready (PB-024)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_pin_rounded,
                        color: AppColors.success, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tersimpan Offline di Perangkat (Offline Ready)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Kartu E-Ticket Utama
              _buildETicketCard(),

              // Tombol Bagikan E-Ticket / Ajak Teman Nonton (PB-026C)
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.card,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded,
                        color: AppColors.textPrimary, size: 18),
                    label: const Text(
                      'Bagikan E-Ticket / Ajak Nonton',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: controller.shareTicket,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Pintasan Pesan Makanan & Minuman di Bioskop Ini (PB-034)
              Obx(() {
                final ticket = controller.ticket.value;
                if (ticket.isTicketHistory) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.fastfood_rounded, size: 18),
                      label: Text(
                        'Pesan F&B di ${ticket.cinemaName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        if (Get.isRegistered<FnbController>()) {
                          final fnbCtrl = Get.find<FnbController>();
                          final match =
                              fnbCtrl.availableCinemas.firstWhereOrNull(
                            (c) =>
                                c.name.toLowerCase() ==
                                ticket.cinemaName.toLowerCase(),
                          );
                          if (match != null) {
                            fnbCtrl.selectedCinema.value = match;
                          }
                        }
                        if (Get.isRegistered<DashboardController>()) {
                          Get.find<DashboardController>().changeTab(2);
                          Get.until((route) =>
                              route.settings.name == Routes.dashboard);
                        } else {
                          Get.toNamed(Routes.fnbCheckout);
                        }
                      },
                    ),
                  ),
                );
              }),

              // Tombol Navigasi Bawah
              Obx(() {
                final isHistory = controller.ticket.value.isTicketHistory;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Get.until((route) =>
                              route.settings.name == Routes.dashboard);
                        },
                        child: const Text('Ke Beranda',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isHistory
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Pesan Lagi',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Get.toNamed(Routes.bookByCinema);
                              },
                            )
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon:
                                  const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Unduh PDF',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Get.snackbar(
                                  'Unduh Berhasil',
                                  'E-ticket ${controller.ticket.value.bookingCode} berhasil disimpan ke dokumen.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.card,
                                  colorText: Colors.white,
                                  icon: const Icon(Icons.check_circle_rounded,
                                      color: AppColors.success),
                                );
                              },
                            ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu E-Ticket Fisik Digital
  Widget _buildETicketCard() {
    return Obx(() {
      final ticket = controller.ticket.value;
      final isHistory = ticket.isTicketHistory;

      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Header Bioskop & Pengalaman Studio
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.movie_rounded,
                          color: AppColors.textPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        ticket.cinemaName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      ticket.experience,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Film
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 65,
                      height: 90,
                      color: AppColors.card,
                      child: ticket.posterUrl.isNotEmpty
                          ? Image.network(
                              ticket.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.movie_creation_rounded,
                                color: AppColors.textDisabled,
                                size: 32,
                              ),
                            )
                          : const Icon(Icons.movie_creation_rounded,
                              color: AppColors.textDisabled),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.movieTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket.cinemaAddress,
                          style: const TextStyle(
                              color: AppColors.textDisabled, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(
                                Icons.meeting_room_rounded, ticket.hallName),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.event_seat_rounded,
                                'Kursi: ${ticket.seatsLabel}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Baris Jadwal (Tanggal & Waktu)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('TANGGAL',
                          style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 10,
                              letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        ticket.showDate,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 26, color: AppColors.divider),
                  Column(
                    children: [
                      const Text('JAM TAYANG',
                          style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 10,
                              letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.showTime} WIB',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 26, color: AppColors.divider),
                  Column(
                    children: [
                      const Text('TOTAL TIKET',
                          style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 10,
                              letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.seatCount} Kursi',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sobekan Perforasi Tiket
            _buildTicketPerforation(),

            // Bagian QR Code (PB-022)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // QR Code Box
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Opacity(
                          opacity: isHistory ? 0.35 : 1.0,
                          child: QrImageView(
                            data: ticket.qrData,
                            version: QrVersions.auto,
                            size: 190.0,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0A0A0A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                      ),
                      if (isHistory)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                ticket.historyStatusLabel.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Kode Booking Unik
                  const Text(
                    'KODE BOOKING',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ticket.bookingCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: AppColors.textPrimary, size: 18),
                        onPressed: controller.copyBookingCode,
                        tooltip: 'Salin Kode Booking',
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    isHistory
                        ? 'Tiket ini telah digunakan untuk menonton atau masa berlakunya telah berakhir.'
                        : 'Pindai kode QR ini pada gerbang masuk bioskop untuk cetak tiket fisik atau langsung masuk studio.',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 12),

                  // Detail Transaksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        ticket.formattedPrice,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status Tiket',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      Builder(builder: (_) {
                        final bool isActive = ticket.status != 'used' &&
                            ticket.status != 'expired' &&
                            !ticket.isShowPassed &&
                            ticket.status != 'cancelled';
                        final String badgeText;
                        if (ticket.status == 'used') {
                          badgeText = 'SUDAH CHECK-IN';
                        } else if (ticket.status == 'expired' ||
                            ticket.isShowPassed) {
                          badgeText = 'KEDALUWARSA';
                        } else if (ticket.status == 'cancelled') {
                          badgeText = 'DIBATALKAN';
                        } else {
                          badgeText = 'AKTIF (SIAP PAKAI)';
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.16)
                                : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary.withValues(alpha: 0.45)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 12),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Efek lekukan sobekan perforasi tiket khas bioskop
  Widget _buildTicketPerforation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const circleSize = 20.0;
        final dashWidth = 6.0;
        final dashSpace = 4.0;
        final totalWidth = constraints.maxWidth - (circleSize * 2);
        final dashCount = (totalWidth / (dashWidth + dashSpace)).floor();

        return SizedBox(
          height: circleSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Garis Putus-putus
              Positioned(
                left: circleSize,
                right: circleSize,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (_) => Container(
                      width: dashWidth,
                      height: 1.5,
                      color: AppColors.divider,
                    ),
                  ),
                ),
              ),

              // Lekukan Kiri
              Positioned(
                left: -(circleSize / 2),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Lekukan Kanan
              Positioned(
                right: -(circleSize / 2),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
