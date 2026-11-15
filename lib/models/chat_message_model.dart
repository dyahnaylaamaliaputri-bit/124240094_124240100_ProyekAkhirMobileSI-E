// lib/models/chat_message_model.dart
// Model data pesan percakapan asisten chatbot AI Cinemate (PB-039, PB-040)
// Mendukung persistensi offline di Hive dan aksi terintegrasi (deep link film/bioskop).

class ChatMessageModel {
  final String id;
  final String text;
  final String sender; // 'user' atau 'bot'
  final DateTime timestamp;
  final bool isError;
  final List<String> suggestedPrompts;
  final int? relatedMovieId;
  final String? relatedCinemaId;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isError = false,
    this.suggestedPrompts = const [],
    this.relatedMovieId,
    this.relatedCinemaId,
  });

  bool get isUser => sender == 'user';
  bool get isBot => sender == 'bot';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      sender: json['sender'] as String? ?? 'bot',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isError: json['is_error'] as bool? ?? false,
      suggestedPrompts: json['suggested_prompts'] != null
          ? List<String>.from(json['suggested_prompts'] as List)
          : const [],
      relatedMovieId: json['related_movie_id'] as int?,
      relatedCinemaId: json['related_cinema_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      'is_error': isError,
      'suggested_prompts': suggestedPrompts,
      if (relatedMovieId != null) 'related_movie_id': relatedMovieId,
      if (relatedCinemaId != null) 'related_cinema_id': relatedCinemaId,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? text,
    String? sender,
    DateTime? timestamp,
    bool? isError,
    List<String>? suggestedPrompts,
    int? relatedMovieId,
    String? relatedCinemaId,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
      relatedMovieId: relatedMovieId ?? this.relatedMovieId,
      relatedCinemaId: relatedCinemaId ?? this.relatedCinemaId,
    );
  }
}
