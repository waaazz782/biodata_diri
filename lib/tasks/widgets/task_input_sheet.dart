import 'package:flutter/material.dart';

import '../../app_style.dart';
import '../../class_data.dart';
import '../../services/schedule_controller.dart';
import '../models/task_reminder.dart';
import '../state/task_scope.dart';
import '../task_theme.dart';
import '../utils/smart_deadline.dart';

/// Membuka lembar input tugas/PR untuk mata pelajaran [subjectName].
/// Batas waktu terisi otomatis memakai Smart Deadline pertemuan
/// berikutnya, tetap bisa diganti lewat date picker.
Future<void> showTaskInputSheet(
  BuildContext context, {
  required String subjectName,
}) {
  final schedule = ScheduleScope.of(context).schedule;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        TaskInputSheet(subjectName: subjectName, schedule: schedule),
  );
}

class TaskInputSheet extends StatefulWidget {
  const TaskInputSheet({
    required this.subjectName,
    required this.schedule,
    super.key,
  });

  final String subjectName;
  final List<ClassDaySchedule> schedule;

  @override
  State<TaskInputSheet> createState() => _TaskInputSheetState();
}

class _TaskInputSheetState extends State<TaskInputSheet> {
  final TextEditingController _titleController = TextEditingController();
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _dueDate = nextLessonOf(widget.subjectName, schedule: widget.schedule);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  int get _daysLeft => _dueDate.difference(dateOnly(DateTime.now())).inDays;

  /// Teks hitung mundur, mis. "Dikumpulkan 2 hari lagi (Rabu, 18
  /// November 2026)".
  String get _countdownText {
    final days = _daysLeft;
    if (days <= 0) {
      return 'Dikumpulkan hari ini (${formatFullDate(_dueDate)})';
    }
    return 'Dikumpulkan $days hari lagi (${formatFullDate(_dueDate)})';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: dateOnly(now),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih tanggal pengumpulan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null) {
      return;
    }
    setState(() => _dueDate = dateOnly(picked));
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    final controller = TaskScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final dueDate = _dueDate;
    controller.addTask(
      subjectName: widget.subjectName,
      taskTitle: title,
      dueDate: dueDate,
    );
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: TaskColors.navy,
          content: Text(
            'Tugas "$title" dicatat · jatuh tempo ${formatFullDate(dueDate)}.',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canSave = _titleController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: TaskColors.navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: 19,
                        color: TaskColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PENGINGAT TUGAS',
                            style: TextStyle(
                              color: TaskColors.amberDeep,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tambah Tugas/PR: ${widget.subjectName}',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16.5,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                const TaskDottedRule(),
                const SizedBox(height: 15),
                const Text(
                  'NAMA TUGAS / PR',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 7),
                TextField(
                  key: const ValueKey('task-title-field'),
                  controller: _titleController,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (canSave) {
                      _save();
                    }
                  },
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'mis. Mencari Peluang',
                    hintStyle: TextStyle(
                      color: AppColors.inkSoft.withValues(alpha: 0.55),
                      fontSize: 12.5,
                    ),
                    filled: true,
                    fillColor: AppColors.paper.withValues(alpha: 0.45),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: TaskColors.cyanInk,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: TaskColors.cyanWash,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TaskColors.cyanInk.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: TaskColors.navy,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.event_repeat_rounded,
                          size: 17,
                          color: TaskColors.cyan,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BATAS PENGUMPULAN',
                              style: TextStyle(
                                color: TaskColors.cyanInk,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formatFullDate(_dueDate),
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _countdownText,
                              key: const ValueKey('task-countdown-text'),
                              style: const TextStyle(
                                color: TaskColors.cyanInk,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const ValueKey('task-change-date-button'),
                          onTap: _pickDate,
                          customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          splashColor: TaskColors.cyanInk.withValues(
                            alpha: 0.14,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: TaskColors.cyanInk.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 13,
                                  color: TaskColors.cyanInk,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Ubah',
                                  style: TextStyle(
                                    color: TaskColors.cyanInk,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 47,
                  child: FilledButton(
                    key: const ValueKey('task-save-button'),
                    onPressed: canSave ? _save : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: TaskColors.navy,
                      disabledBackgroundColor: AppColors.line,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: AppColors.inkSoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Simpan Tugas',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
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
