import 'package:flutter/material.dart';

import 'app_style.dart';
import 'student_profile.dart';

class StudentDetailPage extends StatelessWidget {
  const StudentDetailPage({required this.student, super.key});

  final StudentProfile student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Siswa')),
      body: SafeArea(
        top: false,
        child: PaperBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      key: const ValueKey('student-detail-photo-frame'),
                      padding: const EdgeInsets.fromLTRB(9, 9, 9, 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.line),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Hero(
                              tag: student.photoPath,
                              child: ColoredBox(
                                color: AppColors.paper,
                                child: Image.asset(
                                  student.photoPath,
                                  key: const ValueKey('student-detail-photo'),
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Foto ${student.displayName}',
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 280,
                                        alignment: Alignment.center,
                                        color: AppColors.paper,
                                        child: const Icon(
                                          Icons.person_outline,
                                          size: 64,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Row(
                              children: [
                                const Text(
                                  'KELAS XII RPL',
                                  style: TextStyle(
                                    color: AppColors.inkSoft,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'No. ${student.attendanceNumber}',
                                  style: const TextStyle(
                                    color: AppColors.terracotta,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      student.displayName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No. ${student.attendanceNumber} • Kelas XII RPL',
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 2,
                          color: AppColors.terracotta,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BIODATA',
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(height: 1, color: AppColors.line),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          _ProfileField(
                            label: 'Nama',
                            value: student.name,
                            icon: Icons.person_outline,
                          ),
                          const Divider(height: 1),
                          _ProfileField(
                            label: 'Umur',
                            value: student.age,
                            icon: Icons.cake_outlined,
                          ),
                          const Divider(height: 1),
                          _ProfileField(
                            label: 'Nomor absen',
                            value: student.attendanceNumber,
                            icon: Icons.format_list_numbered,
                          ),
                          const Divider(height: 1),
                          _ProfileField(
                            label: 'Hobi',
                            value: student.hobby,
                            icon: Icons.interests_outlined,
                          ),
                          const Divider(height: 1),
                          _ProfileField(
                            label: 'Tempat, tanggal lahir',
                            value: student.birthPlaceAndDate,
                            icon: Icons.calendar_month_outlined,
                          ),
                        ],
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: AppColors.terracotta, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
