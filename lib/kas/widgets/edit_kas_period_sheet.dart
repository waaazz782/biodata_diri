import 'package:flutter/material.dart';

import '../data/kas_seed_data.dart';
import '../kas_theme.dart';
import '../models/kas_period.dart';
import '../state/kas_scope.dart';
import '../utils/kas_calculations.dart';
import '../utils/thousands_separator_input_formatter.dart';

Future<void> showEditKasPeriodSheet(BuildContext context, KasPeriod period) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => EditKasPeriodSheet(period: period),
  );
}

class EditKasPeriodSheet extends StatefulWidget {
  const EditKasPeriodSheet({required this.period, super.key});

  final KasPeriod period;

  @override
  State<EditKasPeriodSheet> createState() => _EditKasPeriodSheetState();
}

class _EditKasPeriodSheetState extends State<EditKasPeriodSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _monthYearController;
  late final TextEditingController _perStudentController;
  late final TextEditingController _targetController;

  bool _roundPerStudent = true;
  String? _titleError;
  String? _targetError;
  bool _isSyncing = false;
  String _lastEditedField = 'perStudent';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.period.title);
    _monthYearController = TextEditingController(text: widget.period.monthYear);
    _perStudentController = TextEditingController(
      text: _formatDigits(widget.period.targetPerStudent),
    );
    _targetController = TextEditingController(
      text: _formatDigits(widget.period.totalClassTarget),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _monthYearController.dispose();
    _perStudentController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  static String _formatDigits(num value) {
    final rounded = value.round();
    if (rounded <= 0) return '';
    final digits = rounded.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  double get _classTarget => parseRupiahInput(_targetController.text);
  double get _nominalPerStudent => parseRupiahInput(_perStudentController.text);

  double get _rawPerStudent {
    if (_lastEditedField == 'perStudent' && _nominalPerStudent > 0) {
      return _nominalPerStudent;
    }
    return _classTarget <= 0 ? 0 : _classTarget / KasSeedData.totalStudents;
  }

  double get _perStudent {
    if (_lastEditedField == 'perStudent' && _nominalPerStudent > 0) {
      return _nominalPerStudent;
    }
    return calculatePerStudentTarget(
      _classTarget,
      totalStudents: KasSeedData.totalStudents,
      roundUp: _roundPerStudent,
    );
  }

  void _onPerStudentChanged(String _) {
    if (_isSyncing) return;
    _lastEditedField = 'perStudent';
    final perStudent = parseRupiahInput(_perStudentController.text);
    _isSyncing = true;
    if (perStudent > 0) {
      final total = perStudent * KasSeedData.totalStudents;
      _targetController.text = _formatDigits(total);
    } else {
      _targetController.clear();
    }
    _isSyncing = false;
    setState(() {
      _targetError = null;
    });
  }

  void _onTargetChanged(String _) {
    if (_isSyncing) return;
    _lastEditedField = 'target';
    final target = parseRupiahInput(_targetController.text);
    _isSyncing = true;
    if (target > 0) {
      final perStudent = calculatePerStudentTarget(
        target,
        totalStudents: KasSeedData.totalStudents,
        roundUp: _roundPerStudent,
      );
      _perStudentController.text = _formatDigits(perStudent);
    } else {
      _perStudentController.clear();
    }
    _isSyncing = false;
    setState(() {
      _targetError = null;
    });
  }

  void _onRoundToggleChanged(bool value) {
    setState(() => _roundPerStudent = value);
    if (_lastEditedField == 'target') {
      final target = parseRupiahInput(_targetController.text);
      if (target > 0) {
        _isSyncing = true;
        final perStudent = calculatePerStudentTarget(
          target,
          totalStudents: KasSeedData.totalStudents,
          roundUp: value,
        );
        _perStudentController.text = _formatDigits(perStudent);
        _isSyncing = false;
        setState(() {});
      }
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    final monthYear = _monthYearController.text.trim();
    final target = _classTarget;
    final perStudent = _perStudent;

    setState(() {
      _titleError = title.isEmpty ? 'Nama kas wajib diisi.' : null;
      _targetError = (target <= 0 && perStudent <= 0)
          ? 'Target atau iuran harus lebih dari Rp 0.'
          : null;
    });
    if (_titleError != null || _targetError != null) {
      return;
    }

    final finalTarget = target > 0
        ? target
        : (perStudent * KasSeedData.totalStudents);
    final finalPerStudent = perStudent > 0
        ? perStudent
        : (target > 0 ? (target / KasSeedData.totalStudents).roundToDouble() : widget.period.targetPerStudent);

    KasScope.read(context).updatePeriod(
      periodId: widget.period.id,
      title: title.isNotEmpty ? title : widget.period.title,
      monthYear: monthYear.isNotEmpty ? monthYear : widget.period.monthYear,
      targetPerStudent: finalPerStudent,
      totalClassTarget: finalTarget,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final roundedTotal = _perStudent * KasSeedData.totalStudents;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: KasColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: KasColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: KasColors.navy,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: KasColors.green,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PENGATURAN KAS · 47 SISWA',
                        style: TextStyle(
                          color: KasColors.greenInk,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Edit data & target kas',
                        style: TextStyle(
                          color: KasColors.ink,
                          fontSize: 19,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            const Text(
              'Ubah nama periode, nominal iuran per siswa, atau target total. '
              'Perhitungan status setoran siswa akan disesuaikan secara otomatis.',
              style: TextStyle(
                color: KasColors.inkSoft,
                fontSize: 10.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            const KasDottedRule(),
            const SizedBox(height: 15),
            const _FieldLabel('NAMA / JUDUL KAS'),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('kas-edit-title'),
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() => _titleError = null);
                }
              },
              style: const TextStyle(
                color: KasColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: _fieldDecoration(
                hint: 'Contoh: Kas Bulanan',
                error: _titleError,
              ),
            ),
            const SizedBox(height: 13),
            const _FieldLabel('LABEL BULAN / PERIODE'),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('kas-edit-month-year'),
              controller: _monthYearController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                color: KasColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: _fieldDecoration(
                hint: 'Contoh: November 2026',
              ),
            ),
            const SizedBox(height: 13),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('IURAN PER SISWA'),
                      const SizedBox(height: 6),
                      TextField(
                        key: const ValueKey('kas-edit-per-student'),
                        controller: _perStudentController,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [
                          ThousandsSeparatorInputFormatter(),
                        ],
                        onChanged: _onPerStudentChanged,
                        style: const TextStyle(
                          color: KasColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        decoration: _fieldDecoration(
                          hint: '5.000',
                          prefix: 'Rp ',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('TARGET TOTAL KELAS'),
                      const SizedBox(height: 6),
                      TextField(
                        key: const ValueKey('kas-edit-target'),
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [
                          ThousandsSeparatorInputFormatter(),
                        ],
                        onChanged: _onTargetChanged,
                        style: const TextStyle(
                          color: KasColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        decoration: _fieldDecoration(
                          hint: '235.000',
                          prefix: 'Rp ',
                          error: _targetError,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
              decoration: BoxDecoration(
                color: KasColors.card,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: KasColors.line),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulatkan nominal per siswa',
                          style: TextStyle(
                            color: KasColors.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Agar mudah dibayar dan tidak perlu uang kembalian.',
                          style: TextStyle(
                            color: KasColors.inkSoft,
                            fontSize: 9,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    key: const ValueKey('kas-edit-round-switch'),
                    value: _roundPerStudent,
                    onChanged: _onRoundToggleChanged,
                    activeTrackColor: KasColors.greenInk,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _PreviewCard(
              rawPerStudent: _rawPerStudent,
              perStudent: _perStudent,
              roundedTotal: roundedTotal,
              roundPerStudent: _roundPerStudent,
            ),
            const SizedBox(height: 17),
            SizedBox(
              height: 47,
              child: FilledButton(
                key: const ValueKey('kas-edit-save-button'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: KasColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18),
                    SizedBox(width: 7),
                    Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: KasColors.inkSoft),
              child: const Text(
                'Batal',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    String? prefix,
    String? error,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: error == null ? KasColors.line : KasColors.red,
      ),
    );

    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: KasColors.card,
      hintText: hint,
      errorText: error,
      prefixText: prefix,
      prefixStyle: const TextStyle(
        color: KasColors.inkSoft,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: KasColors.inkSoft,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: KasColors.red,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: KasColors.greenInk, width: 1.2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: KasColors.inkSoft,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.rawPerStudent,
    required this.perStudent,
    required this.roundedTotal,
    required this.roundPerStudent,
  });

  final double rawPerStudent;
  final double perStudent;
  final double roundedTotal;
  final bool roundPerStudent;

  @override
  Widget build(BuildContext context) {
    final hasTarget = perStudent > 0;
    final String helper;
    if (!hasTarget) {
      helper = 'Isi target kelas untuk melihat pembagian otomatis.';
    } else if (roundPerStudent) {
      helper = '${formatRupiah(rawPerStudent)} dibulatkan ke atas.';
    } else {
      helper = 'Hasil pembagian target kelas.';
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: KasColors.navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NOMINAL PER SISWA',
              style: TextStyle(
                color: KasColors.white54,
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatRupiah(perStudent),
                style: const TextStyle(
                  color: KasColors.green,
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              helper,
              style: const TextStyle(
                color: KasColors.white54,
                fontSize: 9,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const KasDottedRule(color: KasColors.navyLine, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '${KasSeedData.totalStudents} siswa',
                    style: TextStyle(
                      color: KasColors.white70,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  roundPerStudent && hasTarget
                      ? 'maks. ${formatRupiah(roundedTotal)}'
                      : 'total ${formatRupiah(roundedTotal)}',
                  style: const TextStyle(
                    color: KasColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
