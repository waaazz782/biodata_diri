import 'dart:io';

import 'package:flutter/material.dart';

import 'app_style.dart';
import 'chess/chess_bot.dart';
import 'chess/chess_game_page.dart';
import 'kas/state/kas_scope.dart';
import 'services/local_storage_service.dart';
import 'services/schedule_controller.dart';
import 'student_profile.dart';
import 'tasks/state/task_scope.dart';
import 'wallpaper_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.wallpaperPath,
    required this.overlayOpacity,
    super.key,
  });

  final String? wallpaperPath;
  final double overlayOpacity;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final WallpaperHelper _wallpaperHelper = WallpaperHelper();
  final LocalStorageService _storage = LocalStorageService();
  late String? _wallpaperPath = widget.wallpaperPath;
  late double _overlayOpacity = widget.overlayOpacity;

  @override
  void initState() {
    super.initState();
  }

  bool get _hasWallpaper =>
      _wallpaperPath != null && File(_wallpaperPath!).existsSync();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageIntro(
                eyebrow: 'PREFERENSI TAMPILAN',
                title: 'Tampilan & Wallpaper Daftar Siswa',
                description:
                    'Atur foto latar dan tingkat lapisan agar daftar siswa tetap nyaman dibaca.',
              ),
              const SizedBox(height: 18),
              _buildClassManagement(),
              const SizedBox(height: 18),
              _buildPreviewCard(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickWallpaper,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pilih Foto dari Galeri / Google Foto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildOpacityControl(),
              if (_hasWallpaper) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _resetWallpaper,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset ke Warna Cream Default'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.terracotta,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassManagement() => _settingsCard(
    title: 'Manajemen Data Kelas',
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.people_outline),
        title: const Text('Edit Data Siswa'),
        subtitle: const Text('Cari dan ubah biodata 47 siswa'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const StudentEditorPage()),
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.calendar_month_outlined),
        title: const Text('Edit Jadwal Pelajaran'),
        subtitle: const Text('Senin–Jumat · 3 jam pelajaran per hari'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const ScheduleEditorPage()),
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.cleaning_services_outlined),
        title: const Text('Edit Jadwal Piket'),
        subtitle: const Text('Atur petugas kebersihan setiap hari'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const CleaningScheduleEditorPage(),
          ),
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.extension_outlined),
        title: const Text('Catur Santai XII RPL'),
        subtitle: const Text('Main catur lawan bot saat jam kosong'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _showChessDifficultyDialog,
      ),
      const Divider(),
      TextButton.icon(
        key: const ValueKey('settings-reset-kas-tasks'),
        onPressed: _confirmReset,
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('Reset Data Kas & Tugas ke Nol'),
        style: TextButton.styleFrom(foregroundColor: AppColors.terracotta),
      ),
    ],
  );

  Widget _settingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset kas dan tugas?'),
        content: const Text(
          'Seluruh transaksi kas dan daftar tugas/PR akan dikosongkan. '
          'Editan biodata siswa dan jadwal tetap disimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    KasScope.read(context).resetTransactions();
    TaskScope.read(context).clearTasks();
    await _storage.resetKasAndTasks();
  }

  Future<void> _showChessDifficultyDialog() async {
    ChessDifficulty selected = ChessDifficulty.medium;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE5DEC9)),
            ),
            title: const Text(
              'Ingin Bermain Catur?',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih tingkat kecerdasan bot sebelum memulai permainan.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: ChessDifficulty.values.map((difficulty) {
                    final isSelected = selected == difficulty;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              selected = difficulty;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFFAF6F0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFE5DEC9),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              difficulty.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ChessGamePage(difficulty: selected),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Konfirmasi'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pratinjau wallpaper',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 128,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_hasWallpaper)
                    Image.file(File(_wallpaperPath!), fit: BoxFit.cover)
                  else
                    const ColoredBox(color: AppColors.paper),
                  if (_hasWallpaper)
                    ColoredBox(
                      color: Colors.black.withValues(alpha: _overlayOpacity),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Daftar siswa  ·  47 siswa',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: _hasWallpaper ? 0.92 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: const Text(
                            'Contoh kartu siswa',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasWallpaper ? 'Wallpaper aktif' : 'Warna cream bawaan aplikasi',
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildOpacityControl() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kegelapan Lapisan Wallpaper',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(_overlayOpacity * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.terracotta,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('wallpaper-opacity-slider'),
            value: _overlayOpacity,
            min: WallpaperHelper.minOverlayOpacity,
            max: WallpaperHelper.maxOverlayOpacity,
            divisions: 14,
            label: '${(_overlayOpacity * 100).round()}%',
            onChanged: _setOverlayOpacity,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 10),
              ),
              Text(
                '70%',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickWallpaper() async {
    final path = await _wallpaperHelper.pickAndSaveWallpaper();
    if (!mounted || path == null) return;
    setState(() => _wallpaperPath = path);
  }

  void _setOverlayOpacity(double value) {
    setState(() => _overlayOpacity = value);
    _wallpaperHelper.saveOverlayOpacity(value);
  }

  Future<void> _resetWallpaper() async {
    await _wallpaperHelper.resetWallpaper();
    if (!mounted) return;
    setState(() => _wallpaperPath = null);
  }
}

class StudentEditorPage extends StatefulWidget {
  const StudentEditorPage({super.key});

  @override
  State<StudentEditorPage> createState() => _StudentEditorPageState();
}

class _StudentEditorPageState extends State<StudentEditorPage> {
  final LocalStorageService _storage = LocalStorageService();
  final TextEditingController _search = TextEditingController();
  List<StudentProfile> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final students = await _storage.loadStudents();
    if (mounted) setState(() => _students = students);
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _students.where(
      (student) =>
          student.displayName.toLowerCase().contains(query) ||
          student.attendanceNumber.contains(query),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Data Siswa')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const ValueKey('student-edit-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama atau nomor absen',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final student = visible.elementAt(index);
                return ListTile(
                  leading: CircleAvatar(child: Text(student.attendanceNumber)),
                  title: Text(student.displayName),
                  subtitle: Text(student.hobby),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editStudent(student),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editStudent(StudentProfile student) async {
    final name = TextEditingController(text: student.name);
    final hobby = TextEditingController(text: student.hobby);
    final age = TextEditingController(
      text: student.age.replaceAll(' Tahun', ''),
    );
    final birthParts = student.birthPlaceAndDate.split(',');
    final place = TextEditingController(
      text: birthParts.isEmpty ? '' : birthParts.first.trim(),
    );
    final birthDate = TextEditingController(
      text: birthParts.length > 1 ? birthParts.skip(1).join(',').trim() : '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${student.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              TextField(
                controller: hobby,
                decoration: const InputDecoration(labelText: 'Hobi'),
              ),
              TextField(
                controller: place,
                decoration: const InputDecoration(labelText: 'Tempat Lahir'),
              ),
              TextField(
                controller: birthDate,
                decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
              ),
              TextField(
                controller: age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Umur'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      final updated = student.copyWith(
        name: name.text.trim(),
        hobby: hobby.text.trim(),
        age: age.text.trim().isEmpty ? '' : '${age.text.trim()} Tahun',
        birthPlaceAndDate: [
          place.text.trim(),
          birthDate.text.trim(),
        ].where((value) => value.isNotEmpty).join(', '),
      );
      final index = _students.indexWhere(
        (item) => item.number == student.number,
      );
      if (index >= 0) _students[index] = updated;
      await _storage.saveStudents(_students);
      if (!mounted) return;
      KasScope.read(context).updateStudent(
        noAbsen: updated.number,
        name: updated.displayName,
        photoPath: updated.photoPath,
      );
      setState(() {});
    }
    name.dispose();
    hobby.dispose();
    age.dispose();
    place.dispose();
    birthDate.dispose();
  }
}

class ScheduleEditorPage extends StatelessWidget {
  const ScheduleEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ScheduleScope.of(context);
    final days = controller.schedule;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Jadwal Pelajaran')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: days.length,
        itemBuilder: (context, dayIndex) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days[dayIndex].day,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                for (
                  var subjectIndex = 0;
                  subjectIndex < days[dayIndex].subjects.length;
                  subjectIndex++
                )
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(days[dayIndex].subjects[subjectIndex]),
                    leading: CircleAvatar(child: Text('${subjectIndex + 1}')),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editSubject(
                      context,
                      controller,
                      dayIndex,
                      subjectIndex,
                      days[dayIndex].subjects[subjectIndex],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editSubject(
    BuildContext context,
    ScheduleController schedule,
    int dayIndex,
    int subjectIndex,
    String value,
  ) async {
    final text = TextEditingController(text: value);
    final updated = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah mata pelajaran'),
        content: TextField(controller: text, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, text.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    text.dispose();
   if (updated != null) {
  schedule.updateSubject(dayIndex, subjectIndex, updated);
}
  }
}

class CleaningScheduleEditorPage extends StatefulWidget {
  const CleaningScheduleEditorPage({super.key});

  @override
  State<CleaningScheduleEditorPage> createState() =>
      _CleaningScheduleEditorPageState();
}

class _CleaningScheduleEditorPageState
    extends State<CleaningScheduleEditorPage> {
  final LocalStorageService _storage = LocalStorageService();
  List<StudentProfile> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await _storage.loadStudents();
    if (mounted) setState(() => _allStudents = students);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ScheduleScope.of(context);
    final days = controller.schedule;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Jadwal Piket')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: days.length,
        itemBuilder: (context, dayIndex) {
          final schedule = days[dayIndex];
          final students = schedule.picketNumbers
              .map(
                (n) => _allStudents.firstWhere(
                  (s) => s.number == n,
                  orElse: () => StudentProfile(
                    number: n,
                    name: 'Siswa $n',
                    age: '',
                    attendanceNumber: '',
                    hobby: '',
                    birthPlaceAndDate: '',
                    photoPath: '',
                  ),
                ),
              )
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        schedule.day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _editDayPicket(
                          context,
                          controller,
                          dayIndex,
                          schedule.picketNumbers,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Ubah Petugas'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (students.isEmpty)
                    const Text(
                      'Belum ada petugas',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: students
                          .map(
                            (s) => Chip(
                              label: Text(s.displayName),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editDayPicket(
    BuildContext context,
    ScheduleController controller,
    int dayIndex,
    List<int> current,
  ) async {
    final selected = List<int>.from(current);
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pilih Petugas ${controller.schedule[dayIndex].day}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allStudents.length,
              itemBuilder: (context, index) {
                final student = _allStudents[index];
                final isSelected = selected.contains(student.number);
                return CheckboxListTile(
                  title: Text(student.displayName),
                  secondary: CircleAvatar(
                    child: Text(student.attendanceNumber),
                  ),
                  value: isSelected,
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        selected.add(student.number);
                      } else {
                        selected.remove(student.number);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      controller.updatePicket(dayIndex, result);
    }
  }
}
