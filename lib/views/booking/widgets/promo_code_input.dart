// lib/views/booking/widgets/promo_code_input.dart
// Komponen input & validasi kode promo checkout (PB-087)

import 'package:flutter/material.dart';
import '../../../models/promo_voucher_model.dart';
import '../../../services/promo_service.dart';
import '../../../utils/app_colors.dart';

class PromoCodeInput extends StatefulWidget {
  final int subtotal;
  final Function(PromoVoucherModel?, int discountAmount) onPromoApplied;

  const PromoCodeInput({
    super.key,
    required this.subtotal,
    required this.onPromoApplied,
  });

  @override
  State<PromoCodeInput> createState() => _PromoCodeInputState();
}

class _PromoCodeInputState extends State<PromoCodeInput> {
  final _promoController = TextEditingController();
  final _service = PromoService();
  PromoVoucherModel? _appliedPromo;
  String? _errorMessage;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyCode() {
    setState(() => _errorMessage = null);
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    final voucher = _service.validatePromoCode(
      code: code,
      subtotal: widget.subtotal,
    );

    if (voucher != null) {
      final discount = voucher.calculateDiscount(widget.subtotal);
      setState(() {
        _appliedPromo = voucher;
      });
      widget.onPromoApplied(voucher, discount);
    } else {
      setState(() {
        _errorMessage = 'Kode promo tidak valid atau syarat belum terpenuhi';
        _appliedPromo = null;
      });
      widget.onPromoApplied(null, 0);
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _promoController.clear();
      _errorMessage = null;
    });
    widget.onPromoApplied(null, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.confirmation_num_outlined,
                  color: AppColors.textSecondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Punya Kode Promo / Kupon?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1),
                  decoration: InputDecoration(
                    hintText: 'Cth: NOBARYUK / WEEKDAY',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _appliedPromo != null ? _removePromo : _applyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _appliedPromo != null
                      ? Colors.white24
                      : AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _appliedPromo != null ? 'Hapus' : 'Terapkan',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 11),
            ),
          ],
          if (_appliedPromo != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_appliedPromo!.title} diterapkan! (-Rp ${_appliedPromo!.calculateDiscount(widget.subtotal)})',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
