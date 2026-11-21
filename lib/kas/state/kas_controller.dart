import 'package:flutter/foundation.dart';

import '../data/kas_seed_data.dart';
import '../models/kas_history_log.dart';
import '../models/kas_period.dart';
import '../models/student_payment_status.dart';
import '../../services/local_storage_service.dart';
import '../utils/kas_calculations.dart';

class KasController extends ChangeNotifier {
  KasController({
    required List<KasPeriod> periods,
    required Map<String, List<StudentPaymentStatus>> paymentsByPeriod,
    required List<KasHistoryLog> historyLogs,
    LocalStorageService? storage,
  }) : _periods = List<KasPeriod>.of(periods),
       _paymentsByPeriod = {
         for (final entry in paymentsByPeriod.entries)
           entry.key: List<StudentPaymentStatus>.of(entry.value),
       },
       _historyLogs = List<KasHistoryLog>.of(historyLogs),
       _storage = storage ?? LocalStorageService();

  factory KasController.seeded({
    int defaultNominal = 5000,
    LocalStorageService? storage,
  }) {
    final now = DateTime.now();
    final period = KasPeriod(
      id: 'kas-${now.year}-${now.month.toString().padLeft(2, '0')}',
      monthYear: formatMonthYear(now),
      title: 'Kas Bulanan',
      targetPerStudent: defaultNominal.toDouble(),
      isActive: true,
    );
    return KasController(
      periods: [period],
      paymentsByPeriod: {period.id: KasSeedData.emptyPayments()},
      historyLogs: const [],
      storage: storage,
    );
  }

  final List<KasPeriod> _periods;
  final Map<String, List<StudentPaymentStatus>> _paymentsByPeriod;
  final List<KasHistoryLog> _historyLogs;
  final LocalStorageService _storage;

  List<KasPeriod> get periods => List<KasPeriod>.unmodifiable(_periods);

  KasPeriod get activePeriod {
    return _periods.firstWhere(
      (period) => period.isActive,
      orElse: () => _periods.first,
    );
  }

  KasPeriod periodById(String id) {
    return _periods.firstWhere((period) => period.id == id);
  }

  List<StudentPaymentStatus> paymentsFor(String periodId) {
    return List<StudentPaymentStatus>.unmodifiable(
      _paymentsByPeriod[periodId] ?? const [],
    );
  }

  List<KasHistoryLog> get historyLogs {
    return List<KasHistoryLog>.unmodifiable(_historyLogs);
  }

  List<KasHistoryLog> logsForPeriod(KasPeriod period) {
    return _historyLogs
        .where((log) => _logBelongsToPeriod(log, period))
        .toList(growable: false);
  }

  List<KasHistoryLog> logsForStudent({
    required String periodId,
    required int noAbsen,
  }) {
    final period = periodById(periodId);
    final studentIndex = _paymentsByPeriod[periodId]?.indexWhere(
      (student) => student.noAbsen == noAbsen,
    );
    final studentName = studentIndex == null || studentIndex == -1
        ? null
        : _paymentsByPeriod[periodId]![studentIndex].studentName;

    return _historyLogs
        .where((log) {
          if (!_logBelongsToPeriod(log, period)) {
            return false;
          }
          if (log.noAbsen != 0) {
            return log.noAbsen == noAbsen;
          }
          return studentName != null && log.studentName == studentName;
        })
        .toList(growable: false);
  }

  bool _logBelongsToPeriod(KasHistoryLog log, KasPeriod period) {
    if (log.periodId.isNotEmpty) {
      return log.periodId == period.id;
    }
    // Data lama belum punya periodId: cocokkan lewat bulan.
    return log.monthYear == period.monthYear;
  }

  /// Menambah setoran baru di atas nominal yang sudah tercatat.
  ///
  /// Dipakai untuk cicilan: total baru = nominal lama + setoran baru.
  void addPayment({
    required String periodId,
    required int noAbsen,
    required double amount,
    DateTime? paymentDate,
    String note = 'Cicilan tunai',
  }) {
    final period = periodById(periodId);
    final payments = _paymentsByPeriod[periodId];
    if (!period.isActive || payments == null || amount <= 0) {
      return;
    }

    final index = payments.indexWhere((student) => student.noAbsen == noAbsen);
    if (index == -1) {
      return;
    }

    final previous = payments[index];
    final total = previous.amountPaid + amount;
    final isPaidOff = total + 0.001 >= period.targetPerStudent;
    final date = paymentDate ?? DateTime.now();

    payments[index] = previous.copyWith(
      amountPaid: total,
      isPaidOff: isPaidOff,
      paymentDate: date,
    );

    _recordLog(
      period: period,
      noAbsen: noAbsen,
      studentName: previous.studentName,
      amount: amount,
      timestamp: date,
      note: isPaidOff ? 'Pelunasan cicilan' : note,
    );

    _persist();
    notifyListeners();
  }

  /// Mengganti total setoran siswa (mode koreksi). [savePayment] tetap
  /// dipertahankan agar perilaku kas bulanan lama tidak berubah.
  void savePayment({
    required String periodId,
    required int noAbsen,
    required double amountPaid,
    DateTime? paymentDate,
    String note = 'Lunas transfer / Tunai',
  }) {
    final period = periodById(periodId);
    final payments = _paymentsByPeriod[periodId];
    if (!period.isActive || payments == null) {
      return;
    }

    final index = payments.indexWhere((student) => student.noAbsen == noAbsen);
    if (index == -1) {
      return;
    }

    final previous = payments[index];
    final safeAmount = amountPaid < 0 ? 0.0 : amountPaid;
    final isPaidOff = safeAmount + 0.001 >= period.targetPerStudent;
    final date = safeAmount > 0
        ? (paymentDate ?? previous.paymentDate ?? DateTime.now())
        : null;

    payments[index] = previous.copyWith(
      amountPaid: safeAmount,
      isPaidOff: isPaidOff,
      paymentDate: date,
      clearPaymentDate: date == null,
    );

    final delta = safeAmount - previous.amountPaid;
    if (delta.abs() >= 0.001) {
      _recordLog(
        period: period,
        noAbsen: noAbsen,
        studentName: previous.studentName,
        amount: delta,
        timestamp: DateTime.now(),
        note: delta < 0 ? 'Koreksi pembayaran' : note,
      );
    }

    _persist();
    notifyListeners();
  }

  /// Membuat kegiatan/urunan baru beserta baris pembayaran untuk 47 siswa.
  ///
  /// Periode baru disisipkan tepat setelah kas bulanan aktif agar dropdown
  /// tetap menampilkan kas bulanan sebagai pilihan utama.
  KasPeriod? createCustomPeriod({
    required String title,
    required double totalClassTarget,
    bool roundPerStudent = true,
    double? targetPerStudent,
    String? monthYear,
    DateTime? now,
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty || totalClassTarget <= 0) {
      return null;
    }

    final clock = now ?? DateTime.now();
    final finalTargetPerStudent = targetPerStudent ??
        calculatePerStudentTarget(
          totalClassTarget,
          roundUp: roundPerStudent,
        );

    final period = KasPeriod(
      id: 'kas-custom-${clock.microsecondsSinceEpoch}',
      monthYear: monthYear ?? formatMonthYear(clock),
      title: cleanTitle,
      targetPerStudent: finalTargetPerStudent,
      totalClassTarget: totalClassTarget,
      isActive: true,
      type: KasType.custom,
    );

    final activeIndex = _periods.indexWhere(
      (item) => item.id == activePeriod.id,
    );
    _periods.insert(activeIndex + 1, period);
    _paymentsByPeriod[period.id] = KasSeedData.emptyPayments();

    _persist();
    notifyListeners();
    return period;
  }

  void updatePeriod({
    required String periodId,
    String? title,
    String? monthYear,
    double? targetPerStudent,
    double? totalClassTarget,
  }) {
    final index = _periods.indexWhere((period) => period.id == periodId);
    if (index == -1) return;

    final oldPeriod = _periods[index];
    final newTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : oldPeriod.title;
    final newMonthYear = (monthYear != null && monthYear.trim().isNotEmpty)
        ? monthYear.trim()
        : oldPeriod.monthYear;

    final newTargetPerStudent = targetPerStudent ?? oldPeriod.targetPerStudent;
    final newTotalClassTarget = totalClassTarget ?? (newTargetPerStudent * 47);

    final updated = oldPeriod.copyWith(
      title: newTitle,
      monthYear: newMonthYear,
      targetPerStudent: newTargetPerStudent,
      totalClassTarget: newTotalClassTarget,
    );
    _periods[index] = updated;

    final payments = _paymentsByPeriod[periodId];
    if (payments != null) {
      for (var i = 0; i < payments.length; i++) {
        final p = payments[i];
        final isPaidOff = p.amountPaid + 0.001 >= updated.targetPerStudent;
        payments[i] = p.copyWith(isPaidOff: isPaidOff);
      }
    }

    if (updated.type == KasType.monthly) {
      _storage.saveDefaultKasNominal(updated.targetPerStudent.round());
    }

    _persist();
    notifyListeners();
  }

  void updateStudent({
    required int noAbsen,
    required String name,
    required String photoPath,
  }) {
    for (final payments in _paymentsByPeriod.values) {
      final index = payments.indexWhere(
        (payment) => payment.noAbsen == noAbsen,
      );
      if (index >= 0) {
        payments[index] = StudentPaymentStatus(
          noAbsen: noAbsen,
          studentName: name,
          photoPath: photoPath,
          amountPaid: payments[index].amountPaid,
          isPaidOff: payments[index].isPaidOff,
          paymentDate: payments[index].paymentDate,
        );
      }
    }
    _persist();
    notifyListeners();
  }

  void resetTransactions() {
    for (final period in _periods) {
      _paymentsByPeriod[period.id] = KasSeedData.emptyPayments();
    }
    _historyLogs.clear();
    _persist();
    notifyListeners();
  }

  void _persist() => _storage.saveKasData(
    periods: _periods,
    paymentsByPeriod: _paymentsByPeriod,
    history: _historyLogs,
  );

  void _recordLog({
    required KasPeriod period,
    required int noAbsen,
    required String studentName,
    required double amount,
    required DateTime timestamp,
    required String note,
  }) {
    _historyLogs.insert(
      0,
      KasHistoryLog(
        transactionId: 'trx-${timestamp.microsecondsSinceEpoch}-$noAbsen',
        monthYear: period.monthYear,
        studentName: studentName,
        amount: amount,
        timestamp: timestamp,
        note: note,
        noAbsen: noAbsen,
        periodId: period.id,
        periodTitle: period.title,
      ),
    );
  }
}
