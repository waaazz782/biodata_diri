import 'package:flutter_test/flutter_test.dart';

import 'package:helloworld/tasks/models/task_reminder.dart';
import 'package:helloworld/tasks/state/task_controller.dart';
import 'package:helloworld/tasks/utils/smart_deadline.dart';

void main() {
  group('nextLessonOf (Smart Deadline)', () {
    test('Matematika pada Selasa jatuh tempo Rabu berikutnya (+1)', () {
      final due = nextLessonOf('Matematika', from: DateTime(2026, 11, 17));
      expect(due, DateTime(2026, 11, 18));
    });

    test('Bahasa Indonesia pada Selasa menunggu Selasa depan (+7)', () {
      final due = nextLessonOf('Bahasa Indonesia', from: DateTime(2026, 11, 17));
      expect(due, DateTime(2026, 11, 24));
    });

    test('Upacara hanya Senin: dari Senin menunggu satu pekan penuh', () {
      final due = nextLessonOf('Upacara', from: DateTime(2026, 11, 16));
      expect(due, DateTime(2026, 11, 23));
    });

    test('Kejuruan RPL dari Jumat melewati akhir pekan ke Senin', () {
      final due = nextLessonOf('Kejuruan RPL', from: DateTime(2026, 11, 13));
      expect(due, DateTime(2026, 11, 16));
    });

    test('Bahasa Inggris dari Sabtu mendarat di Kamis berikutnya', () {
      final due = nextLessonOf('Bahasa Inggris', from: DateTime(2026, 11, 14));
      expect(due, DateTime(2026, 11, 19));
    });

    test('Mobile Programming dari Rabu kembali pada Senin', () {
      final due = nextLessonOf('Mobile Programming', from: DateTime(2026, 11, 18));
      expect(due, DateTime(2026, 11, 23));
    });

    test('hasil pengembalian selalu hari kerja setelah tanggal mulai', () {
      final due = nextLessonOf('PPKN', from: DateTime(2026, 11, 17));
      expect(due.isAfter(DateTime(2026, 11, 17)), isTrue);
      expect(due.weekday, lessThan(DateTime.saturday));
    });
  });

  group('format tanggal Indonesia', () {
    test('formatFullDate memakai nama hari dan bulan Indonesia', () {
      expect(formatFullDate(DateTime(2026, 11, 17)), 'Selasa, 17 November 2026');
      expect(dayName(DateTime(2026, 11, 14)), 'Sabtu');
      expect(monthName(12), 'Desember');
    });
  });

  group('TaskReminder', () {
    test('daysLeft menghitung per kalender, bukan per jam', () {
      final now = DateTime.now();
      final task = TaskReminder(
        id: 't',
        subjectName: 'Matematika',
        taskTitle: 'Latihan',
        createdDate: now,
        dueDate: dateOnly(now).add(const Duration(days: 2)),
      );
      expect(task.daysLeft, 2);
    });

    test('daysLeft mengabaikan jam pada hari yang sama', () {
      final now = DateTime.now();
      final task = TaskReminder(
        id: 't',
        subjectName: 'Matematika',
        taskTitle: 'Latihan',
        createdDate: now,
        dueDate: DateTime(now.year, now.month, now.day, 23, 59),
      );
      expect(task.daysLeft, 0);
    });

    test('needsAttention benar untuk tugas mendekati jatuh tempo', () {
      final now = DateTime.now();
      final soon = TaskReminder(
        id: 'soon',
        subjectName: 'Matematika',
        taskTitle: 'Latihan',
        createdDate: now,
        dueDate: dateOnly(now).add(const Duration(days: 3)),
      );
      final far = TaskReminder(
        id: 'far',
        subjectName: 'Matematika',
        taskTitle: 'Latihan',
        createdDate: now,
        dueDate: dateOnly(now).add(const Duration(days: 7)),
      );
      final done = soon.copyWith(isCompleted: true);
      expect(soon.needsAttention, isTrue);
      expect(far.needsAttention, isFalse);
      expect(done.needsAttention, isFalse);
    });
  });

  group('TaskController', () {
    test('seed relatif terhadap now', () {
      final controller = TaskController.seeded(now: DateTime(2026, 11, 11));
      final tasks = controller.sortedTasks;
      expect(tasks, hasLength(3));
      expect(tasks[0].dueDate, DateTime(2026, 11, 11));
      expect(tasks[1].dueDate, DateTime(2026, 11, 13));
      expect(tasks[2].dueDate, DateTime(2026, 11, 17));
      expect(controller.urgentCount, 1);
      expect(controller.hasUrgentTasks, isTrue);
      expect(controller.pendingCountForSubject('Matematika'), 1);
      expect(controller.sortedTasks.first.taskTitle, 'Latihan Barisan & Deret');
    });

    test('addTask menambah tugas baru di urutan jatuh tempo', () {
      final controller = TaskController(now: DateTime(2026, 11, 11));
      controller
        ..addTask(
          subjectName: 'Matematika',
          taskTitle: 'Mencari Peluang',
          dueDate: DateTime(2026, 11, 18),
        )
        ..addTask(
          subjectName: 'Bahasa Indonesia',
          taskTitle: 'Menulis Puisi',
          dueDate: DateTime(2026, 11, 12),
        );
      expect(controller.tasks, hasLength(2));
      expect(controller.sortedTasks.first.taskTitle, 'Menulis Puisi');
      expect(controller.pendingCountForSubject('Matematika'), 1);
    });

    test('toggleCompleted menandai selesai dan menurunkan urgensi', () {
      final controller = TaskController.seeded(now: DateTime(2026, 11, 11));
      controller.toggleCompleted('task-seed-1');
      expect(controller.urgentCount, 0);
      expect(controller.hasUrgentTasks, isFalse);
      expect(
        controller.tasks.firstWhere((t) => t.id == 'task-seed-1').isCompleted,
        isTrue,
      );
    });

    test('tasksDueWithinDays memuat hari ini, H-2, dan yang terlambat', () {
      final controller = TaskController(now: DateTime(2026, 11, 11));
      controller
        ..addTask(
          subjectName: 'Matematika',
          taskTitle: 'Terlambat',
          dueDate: DateTime(2026, 11, 9),
        )
        ..addTask(
          subjectName: 'Kejuruan RPL',
          taskTitle: 'Hari ini',
          dueDate: DateTime(2026, 11, 11),
        )
        ..addTask(
          subjectName: 'Bahasa Inggris',
          taskTitle: 'Dalam jangkauan',
          dueDate: DateTime(2026, 11, 13),
        )
        ..addTask(
          subjectName: 'PPKN',
          taskTitle: 'Jauh',
          dueDate: DateTime(2026, 11, 25),
        );

      final near = controller.tasksDueWithinDays(3);
      expect(near.map((t) => t.taskTitle), [
        'Terlambat',
        'Hari ini',
        'Dalam jangkauan',
      ]);
      expect(
        controller.tasksDueWithinDays(3, includeCompleted: false),
        hasLength(3),
      );

      controller.toggleCompleted('task-3');
      expect(
        controller.tasksDueWithinDays(3, includeCompleted: false).length,
        2,
      );
      expect(controller.tasksDueWithinDays(3).length, 3);
    });
  });
}
