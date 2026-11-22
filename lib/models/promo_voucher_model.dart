// lib/models/promo_voucher_model.dart
// Model untuk kupon promo & voucher reward loyalitas (PB-086, PB-087)

class PromoVoucherModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final int discountAmount; // Potongan rupiah langsung (misal 15000)
  final double discountPercent; // Potongan persentase (misal 0.15 = 15%)
  final int minSpend; // Syarat minimal transaksi
  final int pointsCost; // Biaya poin untuk menukar voucher
  final String category; // 'ticket', 'fnb', 'all'
  final bool isRedeemed;
  final DateTime expiresAt;

  const PromoVoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    this.discountAmount = 0,
    this.discountPercent = 0.0,
    this.minSpend = 0,
    this.pointsCost = 0,
    this.category = 'all',
    this.isRedeemed = false,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Hitung potongan harga berdasarkan subtotal pesanan
  int calculateDiscount(int subtotal) {
    if (subtotal < minSpend || isExpired) return 0;

    int discount = discountAmount;
    if (discountPercent > 0) {
      discount = (subtotal * discountPercent).round();
    }
    // Diskon tidak boleh melebihi subtotal
    return discount > subtotal ? subtotal : discount;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'description': description,
        'discountAmount': discountAmount,
        'discountPercent': discountPercent,
        'minSpend': minSpend,
        'pointsCost': pointsCost,
        'category': category,
        'isRedeemed': isRedeemed,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory PromoVoucherModel.fromJson(Map<String, dynamic> json) =>
      PromoVoucherModel(
        id: json['id'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        discountAmount: json['discountAmount'] as int? ?? 0,
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
        minSpend: json['minSpend'] as int? ?? 0,
        pointsCost: json['pointsCost'] as int? ?? 0,
        category: json['category'] as String? ?? 'all',
        isRedeemed: json['isRedeemed'] as bool? ?? false,
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 30)),
      );

  PromoVoucherModel copyWith({bool? isRedeemed}) => PromoVoucherModel(
        id: id,
        code: code,
        title: title,
        description: description,
        discountAmount: discountAmount,
        discountPercent: discountPercent,
        minSpend: minSpend,
        pointsCost: pointsCost,
        category: category,
        isRedeemed: isRedeemed ?? this.isRedeemed,
        expiresAt: expiresAt,
      );
}
