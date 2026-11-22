// lib/models/split_bill_model.dart
// Model untuk fitur patungan tiket (PB-080)

class SplitBillParticipant {
  final String id;
  final String name;
  final int amount;
  final bool isPaid;
  final String? seat;

  const SplitBillParticipant({
    required this.id,
    required this.name,
    required this.amount,
    this.isPaid = false,
    this.seat,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'isPaid': isPaid,
        'seat': seat,
      };

  factory SplitBillParticipant.fromJson(Map<String, dynamic> json) =>
      SplitBillParticipant(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: json['amount'] as int,
        isPaid: json['isPaid'] as bool? ?? false,
        seat: json['seat'] as String?,
      );

  SplitBillParticipant copyWith({bool? isPaid, int? amount, String? name}) =>
      SplitBillParticipant(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        isPaid: isPaid ?? this.isPaid,
        seat: seat,
      );
}

class SplitBillModel {
  final String id;
  final String bookingCode;
  final String movieTitle;
  final int totalAmount;
  final int totalParticipants;
  final int amountPerPerson;
  final List<SplitBillParticipant> participants;
  final DateTime createdAt;

  const SplitBillModel({
    required this.id,
    required this.bookingCode,
    required this.movieTitle,
    required this.totalAmount,
    required this.totalParticipants,
    required this.amountPerPerson,
    required this.participants,
    required this.createdAt,
  });

  bool get isFullyPaid =>
      participants.isNotEmpty && participants.every((p) => p.isPaid);

  int get paidCount => participants.where((p) => p.isPaid).length;

  int get remainingAmount =>
      participants.where((p) => !p.isPaid).fold(0, (sum, p) => sum + p.amount);

  String get shareMessage => '🎬 *Patungan Tiket Nonton Cinemate*\n'
      'Film: $movieTitle\n'
      'Kode Booking: $bookingCode\n'
      'Total: Rp $totalAmount ($totalParticipants orang)\n'
      'Tagihan Per Orang: Rp $amountPerPerson\n'
      'Yuk segera transfer bagianmu di aplikasi Cinemate! 🍿';

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingCode': bookingCode,
        'movieTitle': movieTitle,
        'totalAmount': totalAmount,
        'totalParticipants': totalParticipants,
        'amountPerPerson': amountPerPerson,
        'participants': participants.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SplitBillModel.fromJson(Map<String, dynamic> json) => SplitBillModel(
        id: json['id'] as String,
        bookingCode: json['bookingCode'] as String,
        movieTitle: json['movieTitle'] as String,
        totalAmount: json['totalAmount'] as int,
        totalParticipants: json['totalParticipants'] as int,
        amountPerPerson: json['amountPerPerson'] as int,
        participants: (json['participants'] as List? ?? [])
            .map((p) => SplitBillParticipant.fromJson(
                Map<String, dynamic>.from(p as Map)))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
