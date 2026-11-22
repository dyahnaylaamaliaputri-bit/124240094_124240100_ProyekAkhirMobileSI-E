// test/promo_voucher_redemption_test.dart
// Unit tests untuk Epic Promo Engine, Dynamic Voucher & Loyalty Redemption (PB 29: PB-086, PB-087, PB-088)

import 'package:flutter_test/flutter_test.dart';
import 'package:cinemate/models/promo_voucher_model.dart';
import 'package:cinemate/services/promo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PromoService promoService;

  setUp(() {
    promoService = PromoService();
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-086: Katalog Penukaran Poin Loyalitas & Voucher Reward
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-086: Katalog Reward & Penukaran Poin', () {
    test('getRewardCatalog mengembalikan daftar reward poin aktif', () {
      final catalog = promoService.getRewardCatalog();
      expect(catalog.isNotEmpty, isTrue);
      expect(catalog.any((v) => v.pointsCost > 0), isTrue);
      expect(catalog.first.pointsCost, equals(100));
      expect(catalog.first.discountAmount, equals(10000));
    });

    test('calculateDiscount menghitung potongan nominal tetap dengan benar',
        () {
      final voucher = PromoVoucherModel(
        id: 'v-test-1',
        code: 'TEST10',
        title: 'Diskon 10rb',
        description: 'Potongan 10rb',
        discountAmount: 10000,
        minSpend: 30000,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      // Subtotal memenuhi syarat minSpend
      expect(voucher.calculateDiscount(50000), equals(10000));

      // Subtotal di bawah minSpend -> diskon 0
      expect(voucher.calculateDiscount(20000), equals(0));
    });

    test('calculateDiscount menghitung potongan persentase dengan benar', () {
      final voucher = PromoVoucherModel(
        id: 'v-test-2',
        code: 'TEST20PCT',
        title: 'Diskon 20%',
        description: 'Potongan 20%',
        discountPercent: 0.20,
        minSpend: 50000,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      // Subtotal 100.000 * 20% = 20.000
      expect(voucher.calculateDiscount(100000), equals(20000));
    });

    test('Voucher kedaluwarsa tidak memberikan potongan harga', () {
      final expiredVoucher = PromoVoucherModel(
        id: 'v-expired',
        code: 'EXPIRED',
        title: 'Expired Voucher',
        description: 'Voucher basi',
        discountAmount: 25000,
        minSpend: 0,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(expiredVoucher.isExpired, isTrue);
      expect(expiredVoucher.calculateDiscount(100000), equals(0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-087: Validasi Kode Promo di Alur Checkout
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-087: Validasi Kode Promo Checkout', () {
    test(
        'validatePromoCode menerima kode promo default NOBARYUK jika subtotal cukup',
        () {
      final result = promoService.validatePromoCode(
        code: 'NOBARYUK',
        subtotal: 100000, // minSpend 80.000
      );

      expect(result, isNotNull);
      expect(result!.code, equals('NOBARYUK'));
      expect(result.discountAmount, equals(20000));
    });

    test('validatePromoCode menolak kupon jika subtotal di bawah minSpend', () {
      final result = promoService.validatePromoCode(
        code: 'NOBARYUK',
        subtotal: 50000, // di bawah minSpend 80.000
      );

      expect(result, isNull);
    });

    test(
        'validatePromoCode bersifat case-insensitive dan membersihkan whitespace',
        () {
      final result = promoService.validatePromoCode(
        code: '  nobaryuk  ',
        subtotal: 100000,
      );

      expect(result, isNotNull);
      expect(result!.code, equals('NOBARYUK'));
    });

    test('validatePromoCode menolak kode fiktif atau kosong', () {
      expect(
          promoService.validatePromoCode(code: '', subtotal: 100000), isNull);
      expect(
          promoService.validatePromoCode(code: 'KODEASAL123', subtotal: 100000),
          isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-088: Penanda Flash Sale & Diskon Jadwal Tertentu
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-088: Flash Sale & Diskon Jadwal Tertentu', () {
    test(
        'isFlashSaleEligible bernilai true untuk jadwal siang sebelum jam 15:00',
        () {
      expect(promoService.isFlashSaleEligible(showTime: '11:30'), isTrue);
      expect(promoService.isFlashSaleEligible(showTime: '13:00'), isTrue);
      expect(promoService.isFlashSaleEligible(showTime: '14:45'), isTrue);
    });

    test('isFlashSaleEligible bernilai false untuk jadwal sore dan malam', () {
      expect(promoService.isFlashSaleEligible(showTime: '15:00'), isFalse);
      expect(promoService.isFlashSaleEligible(showTime: '19:00'), isFalse);
      expect(promoService.isFlashSaleEligible(showTime: '21:30'), isFalse);
    });

    test('calculateFlashSalePrice memberikan potongan 10% dari tarif normal',
        () {
      const normalPrice = 50000;
      final flashPrice = promoService.calculateFlashSalePrice(normalPrice);

      expect(flashPrice, equals(45000)); // 50.000 - 5.000 (10%)
    });
  });
}
