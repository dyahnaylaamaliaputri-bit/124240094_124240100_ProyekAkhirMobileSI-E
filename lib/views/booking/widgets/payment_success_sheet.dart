// lib/views/booking/widgets/payment_success_sheet.dart
// Bottom sheet konfirmasi pembayaran berhasil bergaya dark cinema editorial (tanpa emot/outlier warna)

import 'package:flutter/material.dart';
import '../../../models/booking_order_model.dart';
import '../../../utils/app_colors.dart';

class PaymentSuccessSheet extends StatelessWidget {
  final BookingOrderModel order;
  final VoidCallback onGoHome;
  final VoidCallback onViewTicket;

  const PaymentSuccessSheet({
    super.key,
    required this.order,
    required this.onGoHome,
    required this.onViewTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),

              // Ikon konfirmasi netral tanpa outline hijau mencolok
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.textPrimary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Pembayaran Berhasil',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tiket Anda sudah aktif dan siap dipindai di gerbang studio.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Kartu ringkasan transaksi netral charcoal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _ReceiptRow(
                      label: 'No. Referensi',
                      value: order.paymentReference ?? '-',
                    ),
                    const SizedBox(height: 10),
                    _ReceiptRow(label: 'Film', value: order.movie.title),
                    const SizedBox(height: 10),
                    _ReceiptRow(label: 'Bioskop', value: order.cinema.name),
                    const SizedBox(height: 10),
                    _ReceiptRow(
                      label: 'Kursi (${order.seatCount})',
                      value: order.seatsLabel,
                    ),
                    const SizedBox(height: 10),
                    _ReceiptRow(
                      label: 'Metode Bayar',
                      value: order.paymentMethod ?? '-',
                    ),
                    const Divider(color: AppColors.divider, height: 22),
                    _ReceiptRow(
                      label: 'Total Dibayar',
                      value: order.formattedTotalAmount,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol aksi sejajar (1 sekunder netral + 1 CTA primer merah)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onGoHome,
                      child: const Text(
                        'Ke Beranda',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 19),
                      label: const Text(
                        'Lihat E-Ticket',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: onViewTicket,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: isTotal ? 13 : 12,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTotal ? 16 : 12,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
