// lib/services/split_bill_service.dart
// Service kalkulasi dan manajemen patungan tiket (PB-080)

import 'dart:math';
import 'package:hive/hive.dart';
import '../models/split_bill_model.dart';

class SplitBillService {
  static const String boxSplitBills = 'split_bills_cache';
  static final Map<String, Map<String, dynamic>> _memoryFallback = {};

  Box? _getBox() {
    try {
      if (Hive.isBoxOpen(boxSplitBills)) {
        return Hive.box(boxSplitBills);
      }
    } catch (_) {}
    return null;
  }

  /// Kalkulasi dan buat rencana split bill baru
  SplitBillModel createSplitBill({
    required String bookingCode,
    required String movieTitle,
    required int totalAmount,
    required List<String> participantNames,
    List<String>? seatLabels,
  }) {
    if (participantNames.isEmpty) {
      throw ArgumentError('Partisipan tidak boleh kosong');
    }

    final totalCount = participantNames.length;
    // Pembagian rata dengan pembulatan ke atas kelipatan 100 rupiah agar tidak rugi pecahan
    final baseAmount = (totalAmount / totalCount).ceil();
    final billId = 'SPLIT-${Random().nextInt(90000) + 10000}';

    final participants = List.generate(totalCount, (index) {
      final name = participantNames[index].trim();
      final seat = (seatLabels != null && index < seatLabels.length)
          ? seatLabels[index]
          : null;
      return SplitBillParticipant(
        id: 'p-$index',
        name: name.isEmpty ? 'Teman ${index + 1}' : name,
        amount: baseAmount,
        isPaid: index == 0, // Pembuat pesanan defaultnya sudah bayar
        seat: seat,
      );
    });

    final model = SplitBillModel(
      id: billId,
      bookingCode: bookingCode,
      movieTitle: movieTitle,
      totalAmount: totalAmount,
      totalParticipants: totalCount,
      amountPerPerson: baseAmount,
      participants: participants,
      createdAt: DateTime.now(),
    );

    saveSplitBill(model);
    return model;
  }

  /// Simpan ke Hive cache lokal atau memory fallback
  Future<void> saveSplitBill(SplitBillModel model) async {
    final box = _getBox();
    if (box != null) {
      await box.put(model.id, model.toJson());
    } else {
      _memoryFallback[model.id] = model.toJson();
    }
  }

  /// Ambil split bill berdasarkan ID
  SplitBillModel? getSplitBill(String id) {
    final box = _getBox();
    if (box != null) {
      final data = box.get(id);
      if (data is Map) {
        return SplitBillModel.fromJson(Map<String, dynamic>.from(data));
      }
    }
    final mem = _memoryFallback[id];
    if (mem != null) {
      return SplitBillModel.fromJson(mem);
    }
    return null;
  }

  /// Tandai peserta telah membayar
  Future<SplitBillModel?> markParticipantPaid({
    required String billId,
    required String participantId,
    bool isPaid = true,
  }) async {
    final bill = getSplitBill(billId);
    if (bill == null) return null;

    final updatedParticipants = bill.participants.map((p) {
      if (p.id == participantId) {
        return p.copyWith(isPaid: isPaid);
      }
      return p;
    }).toList();

    final updated = SplitBillModel(
      id: bill.id,
      bookingCode: bill.bookingCode,
      movieTitle: bill.movieTitle,
      totalAmount: bill.totalAmount,
      totalParticipants: bill.totalParticipants,
      amountPerPerson: bill.amountPerPerson,
      participants: updatedParticipants,
      createdAt: bill.createdAt,
    );

    await saveSplitBill(updated);
    return updated;
  }
}
