import 'package:flutter/widgets.dart';

import '../class_data.dart';
import '../services/local_storage_service.dart';

class ScheduleController extends ChangeNotifier {
  ScheduleController({
    required List<ClassDaySchedule> schedule,
    LocalStorageService? storage,
  }) : _schedule = List.of(schedule),
       _storage = storage ?? LocalStorageService();

  final List<ClassDaySchedule> _schedule;
  final LocalStorageService _storage;

  List<ClassDaySchedule> get schedule => List.unmodifiable(_schedule);

  void updateSubject(int dayIndex, int subjectIndex, String value) {
    final subject = value.trim();
    if (subject.isEmpty || dayIndex < 0 || dayIndex >= _schedule.length) return;
    final subjects = List<String>.of(_schedule[dayIndex].subjects);
    if (subjectIndex < 0 || subjectIndex >= subjects.length) return;
    subjects[subjectIndex] = subject;
    _schedule[dayIndex] = _schedule[dayIndex].copyWith(subjects: subjects);
    _storage.saveSchedule(_schedule);
    notifyListeners();
  }

  void updatePicket(int dayIndex, List<int> studentNumbers) {
    if (dayIndex < 0 || dayIndex >= _schedule.length) return;
    _schedule[dayIndex] = _schedule[dayIndex].copyWith(picketNumbers: List.of(studentNumbers));
    _storage.saveSchedule(_schedule);
    notifyListeners();
  }
}

class ScheduleScope extends InheritedNotifier<ScheduleController> {
  const ScheduleScope({
    required ScheduleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ScheduleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ScheduleScope>();
    assert(scope != null, 'ScheduleScope tidak ditemukan.');
    return scope!.notifier!;
  }
}
