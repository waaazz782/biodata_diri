import 'package:flutter/foundation.dart';

import '../models/task_reminder.dart';
import '../../services/local_storage_service.dart';

/// Menyimpan dan memutar daftar PR/tugas per mata pelajaran.
class TaskController extends ChangeNotifier {
  TaskController({
    DateTime? now,
    List<TaskReminder> tasks = const [],
    LocalStorageService? storage,
  }) : _now = dateOnly(now ?? DateTime.now()),
       _tasks = List<TaskReminder>.of(tasks),
       _storage = storage ?? LocalStorageService();

  /// New installations start without sample homework.
  factory TaskController.seeded({DateTime? now}) => TaskController(now: now);

  TaskController.restored({
    DateTime? now,
    required List<TaskReminder> tasks,
    LocalStorageService? storage,
  }) : this(now: now, tasks: tasks, storage: storage);

  final DateTime _now;
  final List<TaskReminder> _tasks;
  final LocalStorageService _storage;
  int _sequence = 0;

  List<TaskReminder> get tasks => List.unmodifiable(_tasks);

  void addTask({
    required String subjectName,
    required String taskTitle,
    required DateTime dueDate,
  }) {
    _sequence += 1;
    _tasks.add(
      TaskReminder(
        id: 'task-${DateTime.now().microsecondsSinceEpoch}-$_sequence',
        subjectName: subjectName,
        taskTitle: taskTitle,
        createdDate: DateTime.now(),
        dueDate: dateOnly(dueDate),
      ),
    );
    _save();
    notifyListeners();
  }

  void toggleCompleted(String id) {
    for (var index = 0; index < _tasks.length; index++) {
      if (_tasks[index].id == id) {
        _tasks[index] = _tasks[index].copyWith(
          isCompleted: !_tasks[index].isCompleted,
        );
        _save();
        notifyListeners();
        return;
      }
    }
  }

  void updateTask(
    String id, {
    required String title,
    required DateTime dueDate,
  }) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0 || title.trim().isEmpty) return;
    _tasks[index] = _tasks[index].copyWith(
      taskTitle: title.trim(),
      dueDate: dateOnly(dueDate),
    );
    _save();
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    _save();
    notifyListeners();
  }

  void clearTasks() {
    _tasks.clear();
    _save();
    notifyListeners();
  }

  void _save() => _storage.saveTasks(_tasks);

  int _daysLeft(TaskReminder task) =>
      dateOnly(task.dueDate).difference(_now).inDays;

  /// Tugas belum selesai yang jatuh tempo hari ini atau sudah lewat;
  /// dipakai untuk efek denyut pada tombol peringatan "!".
  int get urgentCount =>
      _tasks.where((task) => !task.isCompleted && _daysLeft(task) <= 0).length;

  bool get hasUrgentTasks => urgentCount > 0;

  int pendingCountForSubject(String subjectName) => _tasks
      .where((task) => !task.isCompleted && task.subjectName == subjectName)
      .length;

  /// Semua tugas: yang belum selesai ditampilkan dulu, lalu diurutkan
  /// berdasarkan jatuh tempo terdekat.
  List<TaskReminder> get sortedTasks {
    final sorted = List<TaskReminder>.of(_tasks);
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final byDue = a.dueDate.compareTo(b.dueDate);
      if (byDue != 0) {
        return byDue;
      }
      return a.createdDate.compareTo(b.createdDate);
    });
    return sorted;
  }

  /// Tugas yang jatuh tempo dalam [days] hari ke depan, termasuk yang
  /// sudah lewat. Tugas selesai tetap disertai agar bisa dilihat
  /// sebagai riwayat singkat di ringkasan hari ini.
  List<TaskReminder> tasksDueWithinDays(
    int days, {
    bool includeCompleted = true,
  }) {
    final near = _tasks
        .where(
          (task) =>
              (includeCompleted || !task.isCompleted) &&
              _daysLeft(task) <= days,
        )
        .toList();
    near.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.dueDate.compareTo(b.dueDate);
    });
    return near;
  }
}
