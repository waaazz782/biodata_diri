import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_style.dart';
import 'class_structure_page.dart';
import 'cleaning_schedule_page.dart';
import 'kas/kas_theme.dart';
import 'kas/screens/kas_screen.dart';
import 'kas/state/kas_scope.dart';
import 'kas/utils/kas_calculations.dart';
import 'student_detail_page.dart';
import 'student_profile.dart';
import 'subject_schedule_page.dart';
import 'tasks/state/task_controller.dart';
import 'tasks/state/task_scope.dart';
import 'tasks/task_theme.dart';
import 'tasks/widgets/today_summary_dialog.dart';
import 'settings_page.dart';
import 'services/local_storage_service.dart';
import 'wallpaper_helper.dart';

/// Aksen chip menu di header gelap: versi terang dari palet tema
/// (terracotta, forest, mustard) supaya tetap terbaca di atas tinta.
const _accentTerracotta = Color(0xFFE39B6B);
const _accentForest = Color(0xFF93C3AC);
const _accentMustard = Color(0xFFDFC27C);

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  /// Fitur kas disembunyikan dulu; panah bawah membukanya.
  bool _kasExpanded = false;

  /// Menu 3 card (struktur, mapel, piket) disembunyikan secara default.
  bool _isMenuExpanded = false;
  final WallpaperHelper _wallpaperHelper = WallpaperHelper();
  final LocalStorageService _storage = LocalStorageService();
  String? _wallpaperPath;
  double _overlayOpacity = WallpaperHelper.defaultOverlayOpacity;
  bool _balanceHidden = false;
  List<StudentProfile> _students = studentProfiles;

  @override
  void initState() {
    super.initState();
    _loadWallpaperSettings();
  }

  Future<void> _loadWallpaperSettings() async {
    final path = await _wallpaperHelper.loadWallpaperPath();
    final opacity = await _wallpaperHelper.loadOverlayOpacity();
    final hidden = await _storage.loadKasBalanceHidden();
    final students = await _storage.loadStudents();
    if (!mounted) return;
    setState(() {
      _wallpaperPath = path;
      _overlayOpacity = opacity;
      _balanceHidden = hidden;
      _students = students;
    });
  }

  bool get _hasWallpaper =>
      _wallpaperPath != null && File(_wallpaperPath!).existsSync();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer Paling Bawah: Wallpaper full-bleed memenuhi 100% layar
          Positioned.fill(
            child: Container(
              key: const ValueKey('student-list-wallpaper-area'),
              decoration: BoxDecoration(
                color: _hasWallpaper ? null : AppColors.paper,
                image: _hasWallpaper
                    ? DecorationImage(
                        image: FileImage(File(_wallpaperPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _hasWallpaper
                  ? ColoredBox(
                      color: Colors.black.withValues(alpha: _overlayOpacity),
                    )
                  : const PaperBackground(
                      child: SizedBox.expand(),
                    ),
            ),
          ),
          // Layer Atas: Konten utama
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(
                kasExpanded: _kasExpanded,
                isMenuExpanded: _isMenuExpanded,
                onToggleKas: _toggleKas,
                onToggleMenu: _toggleMenu,
                onOpenKas: _openKas,
                onOpenStructure: () =>
                    _open(context, const ClassStructurePage()),
                onOpenSubjects: () =>
                    _open(context, const SubjectSchedulePage()),
                onOpenPicket: () =>
                    _open(context, const CleaningSchedulePage()),
                onOpenSettings: _openSettings,
                students: _students,
                balanceHidden: _balanceHidden,
                onToggleBalance: _toggleBalance,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 11),
                child: _ListHeading(wallpaperActive: _hasWallpaper),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
                  itemCount: _students.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final number = student.number.toString().padLeft(
                      2,
                      '0',
                    );
                    return _StudentRow(
                      key: ValueKey('student-card-photo-$number'),
                      student: student,
                      wallpaperActive: _hasWallpaper,
                      onTap: () => _open(
                        context,
                        StudentDetailPage(student: student),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openKas() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const KasScreen()),
    );
    if (mounted) {
      final hidden = await _storage.loadKasBalanceHidden();
      if (mounted) setState(() => _balanceHidden = hidden);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          wallpaperPath: _wallpaperPath,
          overlayOpacity: _overlayOpacity,
        ),
      ),
    );
    if (mounted) await _loadWallpaperSettings();
  }

  Future<void> _toggleBalance() async {
    final value = !_balanceHidden;
    setState(() => _balanceHidden = value);
    await _storage.saveKasBalanceHidden(value);
  }

  void _toggleKas() {
    setState(() => _kasExpanded = !_kasExpanded);
  }

  void _toggleMenu() {
    setState(() => _isMenuExpanded = !_isMenuExpanded);
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

/// Panel gelap di atas halaman: kartu kelas ringkas, menu cepat,
/// dan fitur kas yang tersembunyi. Bagian bawahnya melengkung sebagai
/// batas ke area daftar siswa yang berwarna kertas.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.kasExpanded,
    required this.isMenuExpanded,
    required this.onToggleKas,
    required this.onToggleMenu,
    required this.onOpenKas,
    required this.onOpenStructure,
    required this.onOpenSubjects,
    required this.onOpenPicket,
    required this.onOpenSettings,
    required this.students,
    required this.balanceHidden,
    required this.onToggleBalance,
  });

  final bool kasExpanded;
  final bool isMenuExpanded;
  final VoidCallback onToggleKas;
  final VoidCallback onToggleMenu;
  final VoidCallback onOpenKas;
  final VoidCallback onOpenStructure;
  final VoidCallback onOpenSubjects;
  final VoidCallback onOpenPicket;
  final VoidCallback onOpenSettings;
  final List<StudentProfile> students;
  final bool balanceHidden;
  final VoidCallback onToggleBalance;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          color: TaskColors.navy,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(
              color: TaskColors.navy.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned(
                right: -16,
                top: -30,
                child: IgnorePointer(
                  child: Text(
                    'XII',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.05),
                      fontSize: 132,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -7,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'DATA SISWA',
                            style: TextStyle(
                              color: AppColors.mustard,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.4,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 19,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            IconButton(
                              key: const ValueKey('wallpaper-settings-button'),
                              onPressed: onOpenSettings,
                              tooltip: 'Pengaturan wallpaper',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 20,
                                height: 20,
                              ),
                              icon: Icon(
                                Icons.settings_outlined,
                                size: 20,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ClassIdentityCard(
                      isMenuExpanded: isMenuExpanded,
                      onToggleMenu: onToggleMenu,
                      students: students,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: isMenuExpanded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _MenuChip(
                                      number: '01',
                                      label: 'Struktur Kelas',
                                      icon: Icons.account_tree_rounded,
                                      accent: _accentTerracotta,
                                      onTap: onOpenStructure,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MenuChip(
                                      number: '02',
                                      label: 'Jadwal Mapel',
                                      icon: Icons.calendar_month_rounded,
                                      accent: _accentForest,
                                      onTap: onOpenSubjects,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MenuChip(
                                      number: '03',
                                      label: 'Jadwal Piket',
                                      icon: Icons.cleaning_services_rounded,
                                      accent: _accentMustard,
                                      onTap: onOpenPicket,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(height: 0),
                    ),
                    _KasToggle(expanded: kasExpanded, onTap: onToggleKas),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: kasExpanded
                          ? _KasPanel(
                              onOpen: onOpenKas,
                              balanceHidden: balanceHidden,
                              onToggleBalance: onToggleBalance,
                            )
                          : const SizedBox(width: double.infinity),
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

/// Kartu identitas kelas versi ringkas: nama kelas, jurusan,
/// jumlah siswa, dan tumpukan foto siswa, dengan tombol toggle menu di bawah tengah.
class _ClassIdentityCard extends StatelessWidget {
  const _ClassIdentityCard({
    required this.isMenuExpanded,
    required this.onToggleMenu,
    required this.students,
  });

  final bool isMenuExpanded;
  final VoidCallback onToggleMenu;
  final List<StudentProfile> students;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'XII RPL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Rekayasa Perangkat Lunak',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.terracotta.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.terracotta.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  size: 9,
                                  color: _accentTerracotta,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '47 siswa',
                                  key: ValueKey('class-student-count'),
                                  style: TextStyle(
                                    color: _accentTerracotta,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const _MinimalReminderButton(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AvatarPile(students: students),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -1,
          child: _MenuToggleButton(
            isExpanded: isMenuExpanded,
            onTap: onToggleMenu,
          ),
        ),
      ],
    );
  }
}

/// Tombol reminder minimalis & proporsional berdampingan dengan badge siswa.
class _MinimalReminderButton extends StatefulWidget {
  const _MinimalReminderButton();

  @override
  State<_MinimalReminderButton> createState() => _MinimalReminderButtonState();
}

class _MinimalReminderButtonState extends State<_MinimalReminderButton> {
  TaskController? _taskController;
  int _urgentCount = 0;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_taskController != null) return;
    final controller = TaskScope.of(context);
    _taskController = controller;
    _urgentCount = controller.urgentCount;
    controller.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    _taskController?.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    if (!mounted) return;
    setState(() {
      _urgentCount = _taskController?.urgentCount ?? 0;
    });
  }

  void _openSummary() {
    HapticFeedback.mediumImpact();
    showTodaySummaryDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _openSummary,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.04 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            key: const ValueKey('today-alert-button'),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered || _isPressed
                    ? _accentTerracotta
                    : Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 15,
                      color: _accentTerracotta,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Agenda',
                      style: TextStyle(
                        color: _accentTerracotta,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                if (_urgentCount > 0)
                  Positioned(
                    top: 2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _accentTerracotta,
                        shape: BoxShape.circle,
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

/// Tombol panah pengendali di ujung tengah bawah card kelas (expandable header).
class _MenuToggleButton extends StatefulWidget {
  const _MenuToggleButton({required this.isExpanded, required this.onTap});

  final bool isExpanded;
  final VoidCallback onTap;

  @override
  State<_MenuToggleButton> createState() => _MenuToggleButtonState();
}

class _MenuToggleButtonState extends State<_MenuToggleButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Container(
            key: const ValueKey('menu-toggle-button'),
            width: 44,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: _isHovered || _isPressed
                    ? _accentTerracotta
                    : Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: AnimatedRotation(
              turns: widget.isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tumpukan foto siswa pertama sebagai penghitung yang hidup.
class _AvatarPile extends StatefulWidget {
  const _AvatarPile({required this.students});

  final List<StudentProfile> students;
  static const _size = 26.0;
  static const _step = 17.0;

  @override
  State<_AvatarPile> createState() => _AvatarPileState();
}

class _AvatarPileState extends State<_AvatarPile> {
  int _currentIndex = 0;
  double _dragDelta = 0.0;

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) {
      return const SizedBox.shrink();
    }

    final length = widget.students.length;
    final s1 = widget.students[_currentIndex % length];
    final s2 = widget.students[(_currentIndex + 1) % length];
    final s3 = widget.students[(_currentIndex + 2) % length];
    final shown = [s1, s2, s3];
    final rest = length - shown.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {
        _dragDelta = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        _dragDelta += details.primaryDelta ?? details.delta.dx;
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < 0 || (velocity == 0 && _dragDelta < -10)) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % length;
          });
        } else if (velocity > 0 || (velocity == 0 && _dragDelta > 10)) {
          setState(() {
            _currentIndex = (_currentIndex - 1 + length) % length;
          });
        }
        _dragDelta = 0.0;
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: SizedBox(
          key: ValueKey<int>(_currentIndex),
          height: _AvatarPile._size,
          width: shown.length * _AvatarPile._step +
              (_AvatarPile._size - _AvatarPile._step) +
              38,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              for (var index = 0; index < shown.length; index++)
                Positioned(
                  left: index * _AvatarPile._step,
                  child: _PileAvatar(photoPath: shown[index].photoPath),
                ),
              Positioned(
                left: shown.length * _AvatarPile._step + 4,
                child: Text(
                  '+$rest',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

class _PileAvatar extends StatelessWidget {
  const _PileAvatar({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _AvatarPile._size,
      height: _AvatarPile._size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inkSoft,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.4,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          photoPath,
          width: 23,
          height: 23,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person_rounded, size: 13, color: Colors.white38),
        ),
      ),
    );
  }
}

/// Tombol menu cepat: mengecil sesaat saat disentuh lalu memantul kembali.
class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.number,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String number;
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      pressedScale: 0.93,
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: accent.withValues(alpha: 0.18),
          highlightColor: accent.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Column(
              children: [
                Text(
                  number,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.75),
                    fontSize: 6.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 5),
                Icon(icon, size: 17, color: accent),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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

/// Baris pembuka fitur kas. Isinya tersembunyi sampai panah bawah
/// diketuk, lalu panahnya berputar menghadap ke atas.
class _KasToggle extends StatelessWidget {
  const _KasToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      pressedScale: 0.97,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          splashColor: KasColors.green.withValues(alpha: 0.14),
          highlightColor: KasColors.green.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: expanded ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: KasColors.green.withValues(
                  alpha: expanded ? 0.45 : 0.28,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: KasColors.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    size: 16,
                    color: KasColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kas & Urunan Kelas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          expanded
                              ? 'Terbuka · ketuk untuk menutup'
                              : 'Tersembunyi · ketuk untuk membuka',
                          key: ValueKey(expanded),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KasColors.green.withValues(alpha: 0.14),
                    border: Border.all(
                      color: KasColors.green.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: KasColors.green,
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

/// Isi fitur kas yang baru terlihat setelah dibuka: saldo yang
/// berhitung naik, progres yang tumbuh, dan tombol menuju buku kas.
class _KasPanel extends StatelessWidget {
  const _KasPanel({
    required this.onOpen,
    required this.balanceHidden,
    required this.onToggleBalance,
  });

  final VoidCallback onOpen;
  final bool balanceHidden;
  final VoidCallback onToggleBalance;

  @override
  Widget build(BuildContext context) {
    final controller = KasScope.of(context);
    final period = controller.activePeriod;
    final payments = controller.paymentsFor(period.id);
    final totalCollected = calculateTotalCollected(payments);
    final totalTarget = period.totalClassTarget;
    final paidCount = countPaidStudents(payments);
    final unpaidCount = countUnpaidStudents(payments);
    final progress = calculateProgressPercentage(totalCollected, totalTarget);

    return Container(
      margin: const EdgeInsets.only(top: 9),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 7),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3.5, color: KasColors.greenInk),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 13, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: KasColors.greenInk,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'BUKU KAS · ${period.monthYear.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: KasColors.greenInk,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terkumpul',
                            style: TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                child: balanceHidden
                                    ? const Text(
                                        'Rp ••••••',
                                        key: ValueKey('kas-panel-hidden'),
                                        style: TextStyle(
                                          color: KasColors.greenInk,
                                          fontSize: 17,
                                          height: 1,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.4,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      )
                                    : TweenAnimationBuilder<double>(
                                        key: const ValueKey(
                                          'kas-panel-visible',
                                        ),
                                        tween: Tween(
                                          begin: 0,
                                          end: totalCollected,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 700,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) =>
                                            Text(
                                              formatRupiah(value),
                                              style: const TextStyle(
                                                color: KasColors.greenInk,
                                                fontSize: 17,
                                                height: 1,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.4,
                                                fontFeatures: [
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                            ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                key: const ValueKey('kas-toggle-balance-button'),
                                behavior: HitTestBehavior.opaque,
                                onTap: onToggleBalance,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                  child: Icon(
                                    balanceHidden
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    key: ValueKey('kas-eye-$balanceHidden'),
                                    size: 19,
                                    color: KasColors.greenInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: KasColors.greenInk,
                            fontSize: 13,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Text(
                            balanceHidden
                                ? 'dari Rp ••••••'
                                : 'dari ${formatRupiah(totalTarget)}',
                            key: ValueKey('kas-target-$balanceHidden'),
                            style: const TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 5.5,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(color: AppColors.paper),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) =>
                              FractionallySizedBox(
                                widthFactor: value.clamp(0.0, 1.0),
                                child: child,
                              ),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [KasColors.greenInk, KasColors.green],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _KasStat(
                      label: 'Lunas',
                      count: paidCount,
                      color: KasColors.greenInk,
                      wash: KasColors.greenWash,
                    ),
                    const SizedBox(width: 6),
                    _KasStat(
                      label: 'Belum',
                      count: unpaidCount,
                      color: KasColors.red,
                      wash: KasColors.redWash,
                    ),
                    const Spacer(),
                    Text(
                      '${formatRupiah(period.targetPerStudent)}/siswa',
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TapScale(
                  pressedScale: 0.97,
                  child: Material(
                    color: KasColors.navy,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const ValueKey('kas-open-button'),
                      onTap: onOpen,
                      splashColor: KasColors.green.withValues(alpha: 0.2),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 14,
                              color: KasColors.green,
                            ),
                            SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'Buka Buku Kas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: KasColors.green,
                            ),
                          ],
                        ),
                      ),
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

class _KasStat extends StatelessWidget {
  const _KasStat({
    required this.label,
    required this.count,
    required this.color,
    required this.wash,
  });

  final String label;
  final int count;
  final Color color;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label $count',
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Membungkus anak dengan efek "ditekan": mengecil cepat saat disentuh
/// dan memantul kembali saat dilepas, terasa hidup tanpa memakan tempat.
class _TapScale extends StatefulWidget {
  const _TapScale({required this.child, this.pressedScale = 0.96});

  final Widget child;
  final double pressedScale;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }
}

class _ListHeading extends StatelessWidget {
  const _ListHeading({this.wallpaperActive = false});

  final bool wallpaperActive;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      children: [
        Container(width: 3, height: 15, color: AppColors.terracotta),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Daftar siswa',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Text(
          '${studentProfiles.length} siswa',
          style: const TextStyle(
            color: AppColors.inkSoft,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (!wallpaperActive) return heading;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: heading,
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.onTap,
    this.wallpaperActive = false,
    super.key,
  });

  final StudentProfile student;
  final VoidCallback onTap;
  final bool wallpaperActive;

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      pressedScale: 0.97,
      child: Material(
        color: wallpaperActive
            ? Colors.white.withValues(alpha: 0.92)
            : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.terracotta.withValues(alpha: 0.08),
          highlightColor: AppColors.terracotta.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Hero(
                    tag: student.photoPath,
                    child: Image.asset(
                      student.photoPath,
                      width: 62,
                      height: 70,
                      fit: BoxFit.cover,
                      semanticLabel: 'Foto ${student.displayName}',
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 62,
                        height: 70,
                        color: AppColors.paper,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.inkSoft,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        student.hobby,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.terracotta.withValues(
                                alpha: 0.09,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'No. ${student.attendanceNumber}',
                              style: const TextStyle(
                                color: AppColors.terracotta,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              '${student.age} · Kelas XII RPL',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.inkSoft,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.line,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
