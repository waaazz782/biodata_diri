import 'package:flutter/material.dart';

import 'app_style.dart';
import 'class_data.dart';
import 'services/schedule_controller.dart';
import 'student_profile.dart';

class CleaningSchedulePage extends StatelessWidget {
  const CleaningSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final schedules = ScheduleScope.of(context).schedule;
    final totalStudents = schedules.fold<int>(
      0,
      (total, day) => total + day.picketNumbers.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Piket'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(Icons.cleaning_services_outlined, size: 20),
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
                      eyebrow: 'Jadwal Piket',
                      title: 'Kelas Bersih,\nBelajar Nyaman',
                      description:
                          'Bersih itu kerja bareng. Cek nama kamu, '
                          'jangan sampai lupa giliran.',
                      trailing: ClassStamp(),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups_2_outlined,
                            size: 15,
                            color: AppColors.inkSoft,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '$totalStudents siswa, terbagi ke '
                              '${schedules.length} hari',
                              style: const TextStyle(
                                color: AppColors.inkSoft,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 4,
                            children: [
                              for (final accent in dayAccents)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (
                      var index = 0;
                      index < schedules.length;
                      index++
                    ) ...[
                      _PiketDayCard(
                        schedule: schedules[index],
                        accent: dayAccents[index],
                        dayIndex: index,
                      ),
                      if (index != schedules.length - 1)
                        const SizedBox(height: 13),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Kalau berhalangan, kabari teman satu hari ya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.inkSoft.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
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

class _PiketDayCard extends StatelessWidget {
  const _PiketDayCard({
    required this.schedule,
    required this.accent,
    required this.dayIndex,
  });

  final ClassDaySchedule schedule;
  final Color accent;
  final int dayIndex;

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().weekday == dayIndex + 1;
    final students = schedule.picketNumbers.map(studentByNumber).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              border: const Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Container(width: 3, height: 28, color: accent),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.day,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${students.length} petugas',
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: accent, width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'HARI INI',
                      style: TextStyle(
                        color: accent,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 15, 12, 11),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 480 ? 6 : 4;
                const spacing = 6.0;
                final tileWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: 16,
                  children: [
                    for (final student in students)
                      SizedBox(
                        width: tileWidth,
                        child: _PiketMember(student: student, accent: accent),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PiketMember extends StatelessWidget {
  const _PiketMember({required this.student, required this.accent});

  final StudentProfile student;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 62,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.line),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset(
                  student.photoPath,
                  width: 48,
                  height: 58,
                  fit: BoxFit.cover,
                  semanticLabel: 'Foto ${student.name}',
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.paper,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_outline,
                      size: 22,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -3,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  student.attendanceNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          student.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 9.5,
            height: 1.18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
