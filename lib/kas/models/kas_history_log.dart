class KasHistoryLog {
  const KasHistoryLog({
    required this.transactionId,
    required this.monthYear,
    required this.studentName,
    required this.amount,
    required this.timestamp,
    required this.note,
    this.noAbsen = 0,
    this.periodId = '',
    this.periodTitle = '',
  });

  final String transactionId;
  final String monthYear;
  final String studentName;
  final double amount;
  final DateTime timestamp;
  final String note;
  final int noAbsen;
  final String periodId;
  final String periodTitle;

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'monthYear': monthYear,
    'studentName': studentName,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
    'noAbsen': noAbsen,
    'periodId': periodId,
    'periodTitle': periodTitle,
  };

  factory KasHistoryLog.fromJson(Map<String, dynamic> json) => KasHistoryLog(
    transactionId: json['transactionId'] as String,
    monthYear: json['monthYear'] as String,
    studentName: json['studentName'] as String,
    amount: (json['amount'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    note: json['note'] as String,
    noAbsen: json['noAbsen'] as int? ?? 0,
    periodId: json['periodId'] as String? ?? '',
    periodTitle: json['periodTitle'] as String? ?? '',
  );
}
