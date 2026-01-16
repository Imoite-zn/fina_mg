/// Tracks imported messages to prevent duplicates
class ImportHistory {
  int? id;
  String source; // 'sms' or 'email'
  String sourceId; // Unique identifier from source (SMS ID or Email Message-ID)
  int? paymentId; // ID of created payment
  DateTime importedAt;
  String rawContent; // Original message content

  ImportHistory({
    this.id,
    required this.source,
    required this.sourceId,
    this.paymentId,
    DateTime? importedAt,
    required this.rawContent,
  }) : importedAt = importedAt ?? DateTime.now();

  factory ImportHistory.fromJson(Map<String, dynamic> json) {
    return ImportHistory(
      id: json['id'],
      source: json['source'],
      sourceId: json['source_id'],
      paymentId: json['payment_id'],
      importedAt: DateTime.parse(json['imported_at']),
      rawContent: json['raw_content'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'source_id': sourceId,
        'payment_id': paymentId,
        'imported_at': importedAt.toIso8601String(),
        'raw_content': rawContent,
      };

  /// Check if this message has already been imported
  bool get isImported => paymentId != null;
}
