import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../class_data.dart';
import '../kas/models/kas_history_log.dart';
import '../kas/models/kas_period.dart';
import '../kas/models/student_payment_status.dart';
import '../student_profile.dart';
import '../tasks/models/task_reminder.dart';

class LocalStorageService {
  static const kasKey = 'saved_kas_list';
  static const tasksKey = 'saved_tasks_list';
  static const studentsKey = 'saved_students_list';
  static const scheduleKey = 'saved_schedule_map';
  static const hiddenKey = 'is_kas_balance_hidden';
  static const defaultNominalKey = 'default_kas_nominal';
  static const _kasHistoryKey = 'saved_kas_history_list';

  Future<List<Map<String, dynamic>>> loadKasData() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(kasKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      return (jsonDecode(encoded) as List<dynamic>)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> saveKasData({
    required List<KasPeriod> periods,
    required Map<String, List<StudentPaymentStatus>> paymentsByPeriod,
    required List<KasHistoryLog> history,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = periods
        .map(
          (period) => {
            ...period.toJson(),
            'payments': (paymentsByPeriod[period.id] ?? const [])
                .map((payment) => payment.toJson())
                .toList(),
          },
        )
        .toList();
    await prefs.setString(kasKey, jsonEncode(entries));
    await prefs.setString(
      _kasHistoryKey,
      jsonEncode(history.map((log) => log.toJson()).toList()),
    );
  }

  Future<List<KasPeriod>> loadKasPeriods() async {
    final entries = await loadKasData();
    return entries.map(KasPeriod.fromJson).toList();
  }

  Future<Map<String, List<StudentPaymentStatus>>> loadKasPayments() async {
    final entries = await loadKasData();
    return {
      for (final entry in entries)
        entry['id'] as String: (entry['payments'] as List<dynamic>? ?? const [])
            .map(
              (item) => StudentPaymentStatus.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
    };
  }

  Future<List<KasHistoryLog>> loadKasHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_kasHistoryKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      return (jsonDecode(encoded) as List<dynamic>)
          .map(
            (item) =>
                KasHistoryLog.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on Object {
      return [];
    }
  }

  Future<List<TaskReminder>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(tasksKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      return (jsonDecode(encoded) as List<dynamic>)
          .map(
            (item) =>
                TaskReminder.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> saveTasks(List<TaskReminder> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      tasksKey,
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
  }

  Future<List<StudentProfile>> loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(studentsKey);
    if (encoded == null || encoded.isEmpty) return studentProfiles;
    try {
      return (jsonDecode(encoded) as List<dynamic>)
          .map(
            (item) =>
                StudentProfile.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on Object {
      return studentProfiles;
    }
  }

  Future<void> saveStudents(List<StudentProfile> students) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      studentsKey,
      jsonEncode(students.map((student) => student.toJson()).toList()),
    );
  }

  Future<List<ClassDaySchedule>> loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(scheduleKey);
    if (encoded == null || encoded.isEmpty) return classDaySchedules;
    try {
      return (jsonDecode(encoded) as List<dynamic>)
          .map(
            (item) => ClassDaySchedule.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on Object {
      return classDaySchedules;
    }
  }

  Future<void> saveSchedule(List<ClassDaySchedule> schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      scheduleKey,
      jsonEncode(schedule.map((day) => day.toJson()).toList()),
    );
  }

  Future<bool> loadKasBalanceHidden() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hiddenKey) ?? false;
  }

  Future<void> saveKasBalanceHidden(bool hidden) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hiddenKey, hidden);
  }

  Future<int> loadDefaultKasNominal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(defaultNominalKey) ?? 5000;
  }

  Future<void> saveDefaultKasNominal(int nominal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(defaultNominalKey, nominal);
  }

  Future<void> resetKasAndTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kasKey);
    await prefs.remove(_kasHistoryKey);
    await prefs.remove(tasksKey);
  }
}
