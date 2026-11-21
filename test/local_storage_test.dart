import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helloworld/class_data.dart';
import 'package:helloworld/student_profile.dart';
import 'package:helloworld/tasks/models/task_reminder.dart';
import 'package:helloworld/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('models round-trip through JSON without losing fields', () {
    final task = TaskReminder(
      id: 'task-1',
      subjectName: 'Matematika',
      taskTitle: 'Latihan',
      createdDate: DateTime(2026, 11, 17),
      dueDate: DateTime(2026, 11, 20),
      isCompleted: true,
    );
    expect(TaskReminder.fromJson(task.toJson()).isCompleted, isTrue);
    expect(
      StudentProfile.fromJson(studentProfiles.first.toJson()).name,
      studentProfiles.first.name,
    );
    expect(
      ClassDaySchedule.fromJson(classDaySchedules.first.toJson()).subjects,
      classDaySchedules.first.subjects,
    );
  });

  test(
    'storage starts with empty editable lists and persists preferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      expect(await storage.loadKasData(), isEmpty);
      expect(await storage.loadTasks(), isEmpty);
      expect(await storage.loadDefaultKasNominal(), 5000);
      expect(await storage.loadKasBalanceHidden(), isFalse);
      await storage.saveKasBalanceHidden(true);
      await storage.saveDefaultKasNominal(7500);
      expect(await storage.loadKasBalanceHidden(), isTrue);
      expect(await storage.loadDefaultKasNominal(), 7500);
    },
  );
}
