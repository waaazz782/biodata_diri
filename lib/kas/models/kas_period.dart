enum KasType { monthly, custom }

class KasPeriod {
  const KasPeriod({
    required this.id,
    required this.monthYear,
    required this.title,
    required this.targetPerStudent,
    required this.isActive,
    this.type = KasType.monthly,
    double? totalClassTarget,
  }) : totalClassTarget = totalClassTarget ?? targetPerStudent * 47;

  final String id;
  final String monthYear;
  final String title;
  final double targetPerStudent;
  final bool isActive;
  final KasType type;
  final double totalClassTarget;

  bool get isCustom => type == KasType.custom;

  String get kindLabel => isCustom ? 'Kegiatan' : 'Kas Bulanan';

  KasPeriod copyWith({
    String? id,
    String? monthYear,
    String? title,
    double? targetPerStudent,
    bool? isActive,
    KasType? type,
    double? totalClassTarget,
  }) => KasPeriod(
    id: id ?? this.id,
    monthYear: monthYear ?? this.monthYear,
    title: title ?? this.title,
    targetPerStudent: targetPerStudent ?? this.targetPerStudent,
    isActive: isActive ?? this.isActive,
    type: type ?? this.type,
    totalClassTarget: totalClassTarget ?? this.totalClassTarget,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'monthYear': monthYear,
    'title': title,
    'targetPerStudent': targetPerStudent,
    'isActive': isActive,
    'type': type.name,
    'totalClassTarget': totalClassTarget,
  };

  factory KasPeriod.fromJson(Map<String, dynamic> json) => KasPeriod(
    id: json['id'] as String,
    monthYear: json['monthYear'] as String,
    title: json['title'] as String,
    targetPerStudent: (json['targetPerStudent'] as num).toDouble(),
    isActive: json['isActive'] as bool? ?? false,
    type: KasType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => KasType.monthly,
    ),
    totalClassTarget: (json['totalClassTarget'] as num?)?.toDouble(),
  );
}
