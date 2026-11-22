// lib/views/profile/voucher_catalog_view.dart
// Katalog penukaran poin loyalitas & daftar voucher aktif (PB-086)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/promo_voucher_model.dart';
import '../../services/promo_service.dart';
import '../../utils/app_colors.dart';

class VoucherCatalogController extends GetxController {
  final PromoService _service = PromoService();

  final pointsBalance = 350.obs;
  final catalogList = <PromoVoucherModel>[].obs;
  final myVouchers = <PromoVoucherModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    catalogList.assignAll(_service.getRewardCatalog());
  }

  void redeemVoucher(PromoVoucherModel voucher) {
    if (pointsBalance.value < voucher.pointsCost) {
      Get.snackbar(
        'Poin Tidak Cukup',
        'Kamu butuh ${voucher.pointsCost} poin untuk menukar voucher ini',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    pointsBalance.value -= voucher.pointsCost;
    final redeemed = voucher.copyWith(isRedeemed: true);
    myVouchers.add(redeemed);

    Get.snackbar(
      'Voucher Berhasil Ditukar! 🎉',
      'Kode ${voucher.code} siap digunakan saat checkout.',
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }
}

class VoucherCatalogView extends StatelessWidget {
  const VoucherCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VoucherCatalogController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Katalog Reward & Voucher',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Tukar Poin'),
              Tab(text: 'Voucher Saya'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Banner Saldo Poin
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.card, const Color(0xFF252233)],
                ),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded,
                        color: AppColors.gold, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo Cinemate Points',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        Obx(() => Text(
                              '${controller.pointsBalance.value} Poin',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab View
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Katalog Penukaran
                  Obx(() {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.catalogList.length,
                      itemBuilder: (context, index) {
                        final voucher = controller.catalogList[index];
                        final canRedeem = controller.pointsBalance.value >=
                            voucher.pointsCost;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      voucher.title,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      voucher.description,
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.stars,
                                            color: AppColors.gold, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${voucher.pointsCost} Poin',
                                          style: const TextStyle(
                                              color: AppColors.gold,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: canRedeem
                                    ? () => controller.redeemVoucher(voucher)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canRedeem
                                      ? AppColors.primary
                                      : Colors.white12,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                ),
                                child: Text(
                                  canRedeem ? 'Tukar' : 'Kurang Poin',
                                  style: TextStyle(
                                    color: canRedeem
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),

                  // Tab 2: Voucher Saya
                  Obx(() {
                    if (controller.myVouchers.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada voucher yang ditukar.\nTukar poinmu di tab sebelah!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.myVouchers.length,
                      itemBuilder: (context, index) {
                        final v = controller.myVouchers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.title,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Kode: ${v.code}',
                                      style: const TextStyle(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Siap Pakai ✅',
                                    style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
