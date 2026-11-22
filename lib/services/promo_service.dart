// lib/services/promo_service.dart
// Service mesin promo, penukaran poin, dan validasi voucher (PB-086, PB-087, PB-088)

import '../models/promo_voucher_model.dart';

class PromoService {
  /// Daftar promo kode bawaan sistem
  static final List<PromoVoucherModel> defaultCoupons = [
    PromoVoucherModel(
      id: 'cup-01',
      code: 'NOBARYUK',
      title: 'Diskon Nobar Rp 20.000',
      description: 'Potongan Rp 20.000 untuk minimal transaksi Rp 80.000',
      discountAmount: 20000,
      minSpend: 80000,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    ),
    PromoVoucherModel(
      id: 'cup-02',
      code: 'WEEKDAYHEMAT',
      title: 'Hemat Weekday 15%',
      description: 'Diskon 15% untuk jadwal tayang Senin-Kamis',
      discountPercent: 0.15,
      minSpend: 40000,
      expiresAt: DateTime.now().add(const Duration(days: 45)),
    ),
    PromoVoucherModel(
      id: 'cup-03',
      code: 'CINEMATEHEMAT',
      title: 'Potongan Tiket Rp 10.000',
      description: 'Potongan langsung Rp 10.000 tanpa batas minimum',
      discountAmount: 10000,
      minSpend: 0,
      expiresAt: DateTime.now().add(const Duration(days: 60)),
    ),
  ];

  /// Daftar voucher yang dapat ditukar dengan poin loyalitas
  List<PromoVoucherModel> getRewardCatalog() {
    return [
      PromoVoucherModel(
        id: 'rew-01',
        code: 'REW-TIKET10',
        title: 'Voucher Tiket Rp 10.000',
        description: 'Potongan Rp 10.000 untuk semua jenis studio',
        discountAmount: 10000,
        pointsCost: 100,
        minSpend: 35000,
        category: 'ticket',
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      ),
      PromoVoucherModel(
        id: 'rew-02',
        code: 'REW-TIKET25',
        title: 'Voucher Tiket VIP Rp 25.000',
        description: 'Potongan Rp 25.000 untuk studio IMAX / Premiere',
        discountAmount: 25000,
        pointsCost: 250,
        minSpend: 75000,
        category: 'ticket',
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      ),
      PromoVoucherModel(
        id: 'rew-03',
        code: 'REW-FNB15',
        title: 'Voucher Diskon Snack Rp 15.000',
        description: 'Potongan Rp 15.000 untuk pembelian popcorn & minuman',
        discountAmount: 15000,
        pointsCost: 150,
        minSpend: 30000,
        category: 'fnb',
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      ),
    ];
  }

  /// Validasi kode promo di checkout (PB-087)
  PromoVoucherModel? validatePromoCode({
    required String code,
    required int subtotal,
  }) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;

    // Cek di kupon default
    final allCoupons = [...defaultCoupons, ...getRewardCatalog()];
    for (final c in allCoupons) {
      if (c.code.toUpperCase() == cleanCode && !c.isExpired) {
        if (subtotal >= c.minSpend) {
          return c;
        }
      }
    }
    return null;
  }

  /// Cek apakah suatu jadwal memenuhi kriteria Flash Sale Weekday Siang (PB-088)
  bool isFlashSaleEligible({
    required String showTime, // misal "13:00"
    String? dayName, // misal "Senin", "Selasa", dll.
  }) {
    try {
      final hour = int.tryParse(showTime.split(':').first) ?? 19;
      // Jadwal siang sebelum jam 15:00
      if (hour < 15) return true;
    } catch (_) {}
    return false;
  }

  /// Hitung harga setelah diskon flash sale (10% potongan)
  int calculateFlashSalePrice(int originalPrice) {
    return (originalPrice * 0.9).round();
  }
}
