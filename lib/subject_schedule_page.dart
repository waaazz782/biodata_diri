import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_style.dart';
import 'class_data.dart';
import 'services/schedule_controller.dart';
import 'tasks/models/task_reminder.dart';
import 'tasks/state/task_scope.dart';
import 'tasks/task_theme.dart';
import 'tasks/utils/smart_deadline.dart';
import 'tasks/widgets/task_complete_checkbox.dart';
import 'tasks/widgets/task_countdown_badge.dart';
import 'tasks/widgets/task_input_sheet.dart';

class SubjectSchedulePage extends StatelessWidget {
  const SubjectSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final days = ScheduleScope.of(context).schedule;
    final totalSubjects = days.fold<int>(
      0,
      (total, day) => total + day.subjects.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pelajaran'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(Icons.menu_book_outlined, size: 21),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: PaperBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageIntro(
                      eyebrow: 'Jadwal Pelajaran',
                      title: 'Senin sampai Jumat',
                      description:
                          'Tiga pelajaran tiap hari. Ketuk salah satu '
                          'pelajaran di bawah untuk mencatat tugas atau '
                          'PR-nya.',
                      trailing: ClassStamp(),
                    ),
                    const SizedBox(height: 22),
                    _Timetable(days: days),
                    const SizedBox(height: 12),
                    Text(
                      '$totalSubjects jam pelajaran · 3 pelajaran per hari',
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Jadwal bisa berubah. Pantau info terbaru dari wali kelas.',
                      style: TextStyle(
                        color: AppColors.inkSoft.withValues(alpha: 0.8),
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const _TaskBoard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Timetable extends StatelessWidget {
  const _Timetable({required this.days});

  final List<ClassDaySchedule> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(54),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: AppColors.line),
          verticalInside: BorderSide(color: AppColors.line),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFE9E0D0)),
            children: [
              _HeadCell('Hari'),
              _HeadCell('Pelajaran 1'),
              _HeadCell('Pelajaran 2'),
              _HeadCell('Pelajaran 3'),
            ],
          ),
          for (var index = 0; index < days.length; index++)
            TableRow(
              decoration: index.isOdd
                  ? BoxDecoration(
                      color: AppColors.paper.withValues(alpha: 0.42),
                    )
                  : null,
              children: [
                _DayCell(day: days[index].day, accent: dayAccents[index]),
                for (final subject in days[index].subjects)
                  _SubjectCell(subject: subject, accent: dayAccents[index]),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  const _HeadCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.inkSoft,
          fontSize: 8,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.accent});

  final String day;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
      color: accent.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 14, height: 2, color: accent),
          const SizedBox(height: 7),
          Text(
            day.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sel mata pelajaran yang bisa diketuk untuk mencatat tugas/PR.
/// Badge amber di pojok menunjukkan jumlah tugas mapel itu yang
/// belum selesai.
class _SubjectCell extends StatelessWidget {
  const _SubjectCell({required this.subject, required this.accent});

  final String subject;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final pendingCount = TaskScope.of(context).pendingCountForSubject(subject);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          showTaskInputSheet(context, subjectName: subject);
        },
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        splashColor: TaskColors.cyan.withValues(alpha: 0.16),
        highlightColor: TaskColors.cyan.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subject,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 10,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (pendingCount > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: TaskColors.amberDeep,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bagian "Tugas & PR" di bawah jadwal: daftar semua catatan tugas
/// dengan kotak centang cepat dan badge hitung mundur.
class _TaskBoard extends StatelessWidget {
  const _TaskBoard();

  @override
  Widget build(BuildContext context) {
    final controller = TaskScope.of(context);
    final tasks = controller.sortedTasks;
    final pendingCount = tasks.where((task) => !task.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(width: 3, height: 15, color: TaskColors.amberDeep),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tugas & PR',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: TaskColors.cyanWash,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: TaskColors.cyanInk.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.task_alt_rounded,
                    size: 10,
                    color: TaskColors.cyanInk,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pendingCount belum selesai',
                    style: const TextStyle(
                      color: TaskColors.cyanInk,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          const _EmptyTaskCard()
        else
          for (var index = 0; index < tasks.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _TaskRow(task: tasks[index]),
          ],
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final TaskReminder task;

  @override
  Widget build(BuildContext context) {
    final controller = TaskScope.read(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          TaskCompleteCheckbox(
            taskId: task.id,
            value: task.isCompleted,
            onChanged: (_) => controller.toggleCompleted(task.id),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: task.isCompleted ? AppColors.inkSoft : AppColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${task.subjectName} · ${formatFullDate(task.dueDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TaskCountdownBadge(
            daysLeft: task.daysLeft,
            isCompleted: task.isCompleted,
          ),
        ],
      ),
    );
  }
}

class _EmptyTaskCard extends StatelessWidget {
  const _EmptyTaskCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit_note_rounded,
            size: 19,
            color: TaskColors.amberDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Belum ada tugas',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ketuk salah satu pelajaran pada jadwal di atas untuk '
                  'mencatat PR atau tugas baru.',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
