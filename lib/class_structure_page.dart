import 'package:flutter/material.dart';

import 'app_style.dart';
import 'class_data.dart';
import 'student_profile.dart';

class ClassStructurePage extends StatelessWidget {
  const ClassStructurePage({super.key});

  static const _connector = Color(0xFFC6B9A7);

  @override
  Widget build(BuildContext context) {
    final ketua = studentByNumber(ketuaKelasNumber);
    final wakil = studentByNumber(wakilKelasNumber);
    final sekretaris = sekretarisNumbers.map(studentByNumber).toList();
    final bendahara = bendaharaNumbers.map(studentByNumber).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Struktur Kelas'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(Icons.account_tree_outlined, size: 21),
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
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    const PageIntro(
                      eyebrow: 'Struktur Organisasi',
                      title: 'Kepengurusan\nKelas XII RPL',
                      description:
                          'Setiap peran punya porsinya. Ini orang-orang yang '
                          'biasa jadi tempat bertanya di kelas.',
                      trailing: ClassStamp(),
                    ),
                    const SizedBox(height: 30),
                    const _LeaderCard(
                      photoPath: waliKelasPhoto,
                      name: waliKelasName,
                      role: 'Wali Kelas',
                      accent: AppColors.terracotta,
                    ),
                    const _VerticalConnector(),
                    _LeaderCard(
                      photoPath: ketua.photoPath,
                      name: ketua.name,
                      role: 'Ketua Kelas',
                      accent: AppColors.forest,
                      number: ketua.attendanceNumber,
                    ),
                    const _VerticalConnector(),
                    _LeaderCard(
                      photoPath: wakil.photoPath,
                      name: wakil.name,
                      role: 'Wakil Ketua',
                      accent: AppColors.slate,
                      number: wakil.attendanceNumber,
                    ),
                    const _BranchConnector(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _OfficerGroup(
                            title: 'Sekretaris',
                            accent: AppColors.mustard,
                            members: [
                              _OfficerMember(
                                student: sekretaris[0],
                                role: 'Sekretaris 1',
                              ),
                              _OfficerMember(
                                student: sekretaris[1],
                                role: 'Sekretaris 2',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _OfficerGroup(
                            title: 'Bendahara',
                            accent: AppColors.plum,
                            members: [
                              _OfficerMember(
                                student: bendahara[0],
                                role: 'Bendahara 1',
                              ),
                              _OfficerMember(
                                student: bendahara[1],
                                role: 'Bendahara 2',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 18, height: 1, color: AppColors.line),
                        const SizedBox(width: 8),
                        Text(
                          'Satu kelas, satu tim.',
                          style: TextStyle(
                            color: AppColors.inkSoft.withValues(alpha: 0.8),
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 18, height: 1, color: AppColors.line),
                      ],
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

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({
    required this.photoPath,
    required this.name,
    required this.role,
    required this.accent,
    this.number,
  });

  final String photoPath;
  final String name;
  final String role;
  final Color accent;
  final String? number;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                child: Row(
                  children: [
                    _SquarePhoto(photoPath: photoPath, size: 58),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 14.5,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (number != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Absen $number',
                              style: const TextStyle(
                                color: AppColors.inkSoft,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficerGroup extends StatelessWidget {
  const _OfficerGroup({
    required this.title,
    required this.accent,
    required this.members,
  });

  final String title;
  final Color accent;
  final List<_OfficerMember> members;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 12, height: 2, color: accent),
              const SizedBox(width: 5),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: Container(height: 1, color: AppColors.line)),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < members.length; index++) ...[
            _MemberCard(member: members[index], accent: accent),
            if (index != members.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _OfficerMember {
  const _OfficerMember({required this.student, required this.role});

  final StudentProfile student;
  final String role;
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.accent});

  final _OfficerMember member;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _SquarePhoto(photoPath: member.student.photoPath, size: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.student.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member.role,
                  style: TextStyle(
                    color: accent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No. ${member.student.attendanceNumber}',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
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

class _SquarePhoto extends StatelessWidget {
  const _SquarePhoto({required this.photoPath, required this.size});

  final String photoPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          photoPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.paper,
            alignment: Alignment.center,
            child: Icon(
              Icons.person_outline,
              size: size * 0.44,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalConnector extends StatelessWidget {
  const _VerticalConnector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 1.5,
        height: 26,
        color: ClassStructurePage._connector,
      ),
    );
  }
}

class _BranchConnector extends StatelessWidget {
  const _BranchConnector();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 1.5, height: 16, color: ClassStructurePage._connector),
        SizedBox(
          height: 1.5,
          child: Row(
            children: const [
              Expanded(child: SizedBox()),
              Expanded(
                flex: 2,
                child: ColoredBox(color: ClassStructurePage._connector),
              ),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
        SizedBox(
          height: 18,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 1.5,
                    height: 18,
                    color: ClassStructurePage._connector,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 1.5,
                    height: 18,
                    color: ClassStructurePage._connector,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
