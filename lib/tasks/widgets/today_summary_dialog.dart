import 'package:flutter/material.dart';

import '../../app_style.dart';
import '../../class_data.dart';
import '../../services/schedule_controller.dart';
import '../models/task_reminder.dart';
import '../state/task_scope.dart';
import '../task_theme.dart';
import '../utils/smart_deadline.dart';
import 'task_complete_checkbox.dart';
import 'task_countdown_badge.dart';

/// Membuka modal ringkasan kegiatan hari ini dengan animasi
/// scale + fade yang memantul (Curves.easeOutBack).
Future<void> showTodaySummaryDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup ringkasan hari ini',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const _TodaySummaryDialog(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scale = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class _TodaySummaryDialog extends StatelessWidget {
  const _TodaySummaryDialog();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final schedule = ScheduleScope.of(context).schedule;
    final todayIndex = now.weekday - DateTime.monday;
    final hasSchoolToday = todayIndex >= 0 && todayIndex < schedule.length;
    final todaySchedule = hasSchoolToday ? schedule[todayIndex] : null;
    final nearTasks = TaskScope.of(context).tasksDueWithinDays(3);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: Material(
          color: AppColors.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.line),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogHeader(now: now),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(13, 13, 13, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PicketSection(schedule: todaySchedule),
                        const SizedBox(height: 10),
                        _SubjectSection(schedule: todaySchedule),
                        const SizedBox(height: 10),
                        _NearTaskSection(tasks: nearTasks),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sampul navy dialog: tile "!" amber bercahaya, tanggal hari ini,
/// dan tombol tutup.
class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TaskColors.navy,
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TaskColors.amber, TaskColors.amberDeep],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: TaskColors.amber.withValues(alpha: 0.45),
                  blurRadius: 13,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RINGKASAN HARI INI',
                  style: TextStyle(
                    color: TaskColors.cyan,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatFullDate(now),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('today-dialog-close'),
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withValues(alpha: 0.14),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bagian dengan judul kecil bergaris aksen, dipakai berulang.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.accent,
    required this.child,
  });

  final String label;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 3, height: 11, color: accent),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}

class _PicketSection extends StatelessWidget {
  const _PicketSection({required this.schedule});

  final ClassDaySchedule? schedule;

  @override
  Widget build(BuildContext context) {
    if (schedule == null) {
      return _SectionCard(
        label: 'PIKET HARI INI',
        accent: TaskColors.cyanInk,
        child: const _DayOffRow(
          icon: Icons.cleaning_services_outlined,
          message:
              'Hari ini tidak ada jadwal piket. Kelas dipelihara '
              'siswa piket hari kerja.',
        ),
      );
    }

    return _SectionCard(
      label: 'PIKET HARI INI',
      accent: TaskColors.cyanInk,
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final number in schedule!.picketNumbers)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
              decoration: BoxDecoration(
                color: TaskColors.cyanWash,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: TaskColors.cyanInk.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${number.toString().padLeft(2, '0')} · ',
                    style: const TextStyle(
                      color: TaskColors.cyanInk,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    studentByNumber(number).displayName,
                    style: const TextStyle(
                      color: TaskColors.cyanInk,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
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

class _SubjectSection extends StatelessWidget {
  const _SubjectSection({required this.schedule});

  final ClassDaySchedule? schedule;

  @override
  Widget build(BuildContext context) {
    if (schedule == null) {
      return _SectionCard(
        label: 'JADWAL MAPEL HARI INI',
        accent: TaskColors.amberDeep,
        child: const _DayOffRow(
          icon: Icons.weekend_rounded,
          message: 'Hari ini hari libur — tidak ada pelajaran.',
        ),
      );
    }

    return _SectionCard(
      label: 'JADWAL MAPEL HARI INI',
      accent: TaskColors.amberDeep,
      child: Column(
        children: [
          for (var index = 0; index < schedule!.subjects.length; index++)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 7),
              child: Row(
                children: [
                  Container(
                    width: 19,
                    height: 19,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TaskColors.amberWash,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: TaskColors.amberDeep.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: TaskColors.amberDeep,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      schedule!.subjects[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
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

class _NearTaskSection extends StatelessWidget {
  const _NearTaskSection({required this.tasks});

  final List<TaskReminder> tasks;

  @override
  Widget build(BuildContext context) {
    final controller = TaskScope.of(context);

    if (tasks.isEmpty) {
      return _SectionCard(
        label: 'PR & TUGAS TERDEKAT',
        accent: TaskColors.red,
        child: const _DayOffRow(
          icon: Icons.task_alt_rounded,
          message:
              'Tidak ada PR mendesak untuk hari ini dan 3 hari '
              'ke depan. Mantap!',
        ),
      );
    }

    return _SectionCard(
      label: 'PR & TUGAS TERDEKAT',
      accent: TaskColors.red,
      child: Column(
        children: [
          for (var index = 0; index < tasks.length; index++) ...[
            if (index > 0) ...[
              const SizedBox(height: 7),
              const TaskDottedRule(height: 0.8, dash: 3, gap: 3),
              const SizedBox(height: 7),
            ],
            Builder(
              builder: (context) {
                final task = tasks[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TaskCompleteCheckbox(
                      taskId: task.id,
                      value: task.isCompleted,
                      onChanged: (_) => controller.toggleCompleted(task.id),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.taskTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: task.isCompleted
                                  ? AppColors.inkSoft
                                  : AppColors.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2.5),
                          Text(
                            '${task.subjectName} · ${formatFullDate(task.dueDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 8.5,
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
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Baris pesan untuk hari libur atau daftar kosong.
class _DayOffRow extends StatelessWidget {
  const _DayOffRow({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.inkSoft),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 10,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
