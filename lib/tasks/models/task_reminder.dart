/// Memotong jam/menit/detik supaya perbandingan tanggal murni kalender.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Satu catatan PR/tugas per mata pelajaran.
typedef TaskModel = TaskReminder;

class TaskReminder {
  const TaskReminder({
    required this.id,
    required this.subjectName,
    required this.taskTitle,
    required this.createdDate,
    required this.dueDate,
    this.isCompleted = false,
  });

  final String id;
  final String subjectName;
  final String taskTitle;
  final DateTime createdDate;

  /// Tanggal jatuh tempo (deadline) pengumpulan.
  final DateTime dueDate;
  final bool isCompleted;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectName': subjectName,
    'taskTitle': taskTitle,
    'createdDate': createdDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory TaskReminder.fromJson(Map<String, dynamic> json) => TaskReminder(
    id: json['id'] as String,
    subjectName: json['subjectName'] as String,
    taskTitle: json['taskTitle'] as String,
    createdDate: DateTime.parse(json['createdDate'] as String),
    dueDate: DateTime.parse(json['dueDate'] as String),
    isCompleted: json['isCompleted'] as bool? ?? false,
  );

  TaskReminder copyWith({
    String? subjectName,
    String? taskTitle,
    DateTime? createdDate,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return TaskReminder(
      id: id,
      subjectName: subjectName ?? this.subjectName,
      taskTitle: taskTitle ?? this.taskTitle,
      createdDate: createdDate ?? this.createdDate,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Sisa hari menuju jatuh tempo, dihitung per kalender (bukan per jam):
  /// 0 berarti jatuh tempo hari ini, negatif berarti sudah terlambat.
  int get daysLeft =>
      dateOnly(dueDate).difference(dateOnly(DateTime.now())).inDays;

  /// Tugas belum selesai dan jatuh tempo dalam 3 hari (atau lewat).
  bool get needsAttention => !isCompleted && daysLeft <= 3;
}
