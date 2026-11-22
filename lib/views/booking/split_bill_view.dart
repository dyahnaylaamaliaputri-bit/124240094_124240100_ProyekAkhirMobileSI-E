// lib/views/booking/split_bill_view.dart
// Layar kalkulator & pelacakan split bill patungan tiket (PB-080)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/split_bill_model.dart';
import '../../services/split_bill_service.dart';
import '../../utils/app_colors.dart';

class SplitBillController extends GetxController {
  final SplitBillService _service = SplitBillService();

  final Rx<SplitBillModel?> activeBill = Rx<SplitBillModel?>(null);
  final participantControllers = <TextEditingController>[].obs;
  final totalAmount = 0.obs;
  final bookingCode = ''.obs;
  final movieTitle = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      totalAmount.value = args['totalAmount'] as int? ?? 100000;
      bookingCode.value = args['bookingCode'] as String? ?? 'CNM-SPLIT';
      movieTitle.value = args['movieTitle'] as String? ?? 'Film Bioskop';
    } else {
      totalAmount.value = 100000;
      bookingCode.value = 'CNM-SPLIT';
      movieTitle.value = 'Avatar: Fire & Ash';
    }

    // Default 2 partisipan awal
    addParticipant('Saya (Pemesan)');
    addParticipant('Teman 1');
    recalculateSplit();
  }

  void addParticipant([String initialName = '']) {
    participantControllers.add(TextEditingController(text: initialName));
    recalculateSplit();
  }

  void removeParticipant(int index) {
    if (participantControllers.length > 2) {
      participantControllers.removeAt(index);
      recalculateSplit();
    } else {
      Get.snackbar('Perhatian', 'Minimal harus ada 2 partisipan patungan');
    }
  }

  void recalculateSplit() {
    final names = participantControllers.map((c) => c.text.trim()).toList();
    activeBill.value = _service.createSplitBill(
      bookingCode: bookingCode.value,
      movieTitle: movieTitle.value,
      totalAmount: totalAmount.value,
      participantNames: names,
    );
  }

  Future<void> togglePaid(String participantId) async {
    final current = activeBill.value;
    if (current == null) return;
    final p = current.participants.firstWhere((e) => e.id == participantId);
    final updated = await _service.markParticipantPaid(
      billId: current.id,
      participantId: participantId,
      isPaid: !p.isPaid,
    );
    if (updated != null) {
      activeBill.value = updated;
    }
  }

  void shareBill() {
    final bill = activeBill.value;
    if (bill != null) {
      // ignore: deprecated_member_use
      Share.share(bill.shareMessage,
          subject: 'Patungan Tiket ${bill.movieTitle}');
    }
  }

  @override
  void onClose() {
    for (final c in participantControllers) {
      c.dispose();
    }
    super.onClose();
  }
}

class SplitBillView extends StatelessWidget {
  const SplitBillView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SplitBillController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Split Bill Tiket',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        final bill = controller.activeBill.value;
        if (bill == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kartu Ringkasan Split Bill
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.card, const Color(0xFF1F1D2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: bill.isFullyPaid ? AppColors.gold : AppColors.primary,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bill.movieTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bill.isFullyPaid
                              ? Colors.green.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bill.isFullyPaid ? 'Lunas ✅' : 'Belum Lunas ⏳',
                          style: TextStyle(
                            color: bill.isFullyPaid
                                ? Colors.greenAccent
                                : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Kode Booking: ${bill.bookingCode}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan:',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('Rp ${bill.totalAmount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Per Orang (${bill.totalParticipants} partisipan):',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      Text('Rp ${bill.amountPerPerson}',
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Header Daftar Teman
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Partisipan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => controller.addParticipant(),
                  icon: const Icon(Icons.person_add,
                      color: AppColors.primary, size: 18),
                  label: const Text('Tambah Teman',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // List Partisipan
            ...List.generate(bill.participants.length, (index) {
              final participant = bill.participants[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: participant.isPaid
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: participant.isPaid
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.white12,
                      child: Icon(
                        participant.isPaid ? Icons.check : Icons.person_outline,
                        color: participant.isPaid
                            ? Colors.greenAccent
                            : Colors.white70,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            participant.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          Text(
                            'Rp ${participant.amount} • ${participant.isPaid ? "Sudah Bayar" : "Belum Bayar"}',
                            style: TextStyle(
                              color: participant.isPaid
                                  ? Colors.greenAccent
                                  : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        participant.isPaid
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: participant.isPaid
                            ? Colors.greenAccent
                            : Colors.white38,
                      ),
                      onPressed: () => controller.togglePaid(participant.id),
                    ),
                    if (index > 0)
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white30, size: 18),
                        onPressed: () => controller.removeParticipant(index),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Tombol Bagikan Pesan Patungan
            ElevatedButton.icon(
              onPressed: () => controller.shareBill(),
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Bagikan Tagihan ke WhatsApp / Medsos',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      }),
    );
  }
}
