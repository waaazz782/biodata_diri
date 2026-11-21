import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helloworld/kas/models/kas_period.dart';
import 'package:helloworld/kas/models/student_payment_status.dart';
import 'package:helloworld/kas/state/kas_controller.dart';
import 'package:helloworld/kas/utils/kas_calculations.dart';
import 'package:helloworld/kas/utils/thousands_separator_input_formatter.dart';

StudentPaymentStatus _payment({
  required int no,
  required double amount,
  bool? paidOff,
}) {
  return StudentPaymentStatus(
    noAbsen: no,
    studentName: 'Siswa $no',
    photoPath: '',
    amountPaid: amount,
    isPaidOff: paidOff ?? amount >= 10000,
  );
}

void main() {
  group('perhitungan kas', () {
    final sample = [
      _payment(no: 1, amount: 10000),
      _payment(no: 2, amount: 5000, paidOff: false),
      _payment(no: 3, amount: 0, paidOff: false),
    ];

    test('menjumlahkan setoran dan target', () {
      expect(calculateTotalCollected(sample), 15000);
      expect(calculateTotalTarget(10000), 470000);
      expect(calculateTotalTarget(50000, totalStudents: 40), 2000000);
    });

    test('menghitung siswa lunas, dicicil, dan persentase', () {
      expect(countPaidStudents(sample), 1);
      expect(countInstallmentStudents(sample), 1);
      expect(countUnpaidStudents(sample), 1);
      expect(
        calculateProgressPercentage(15000, 470000),
        closeTo(0.0319, 0.001),
      );
      expect(calculateProgressPercentage(500, 0), 0);
      expect(calculateProgressPercentage(20000, 10000), 1);
    });

    test('membagi target kelas dan membulatkan nominal per siswa', () {
      expect(calculatePerStudentTarget(500000), 11000);
      expect(calculatePerStudentTarget(500000, roundUp: false), 10638);
      expect(calculatePerStudentTarget(470000), 10000);
      expect(calculatePerStudentTarget(0), 0);
    });

    test('memformat rupiah, bulan, dan tanggal', () {
      expect(formatRupiah(350000), 'Rp 350.000');
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(-5000), '-Rp 5.000');
      expect(formatMonthYear(DateTime(2026, 11, 9)), 'November 2026');
      expect(formatFullDate(DateTime(2026, 11, 9)), '9 November 2026');
      expect(formatShortDate(DateTime(2026, 11, 9)), '09 Nov 2026');
      expect(
        formatLogTimestamp(DateTime(2026, 11, 9, 8, 5)),
        '09 Nov 2026 · 08.05',
      );
    });

    test('input nominal otomatis memakai titik ribuan', () {
      const formatter = ThousandsSeparatorInputFormatter();

      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1000000',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );

      expect(result.text, '1.000.000');
      expect(result.selection.baseOffset, 9);
      expect(parseRupiahInput(result.text), 1000000);
      expect(parseRupiahInput('Rp 10.638'), 10638);
      expect(parseRupiahInput(''), 0);
    });

    test('status pembayaran mengikuti nominal dan target', () {
      final unpaid = _payment(no: 1, amount: 0, paidOff: false);
      final installment = _payment(no: 2, amount: 5000, paidOff: false);
      final paid = _payment(no: 3, amount: 11000, paidOff: true);

      expect(unpaid.stateFor(11000), StudentPaymentState.unpaid);
      expect(installment.stateFor(11000), StudentPaymentState.installment);
      expect(paid.stateFor(11000), StudentPaymentState.paidOff);
      expect(installment.hasInstallment, isTrue);
    });
  });

  group('KasController', () {
    test('data awal November sesuai rekap kelas', () {
      final controller = KasController.seeded();
      addTearDown(controller.dispose);

      expect(controller.periods.length, 4);
      expect(controller.activePeriod.monthYear, 'November 2026');
      expect(controller.activePeriod.totalClassTarget, 470000);
      expect(controller.activePeriod.type, KasType.monthly);

      final payments = controller.paymentsFor(controller.activePeriod.id);
      expect(payments.length, 47);
      expect(calculateTotalCollected(payments), 350000);
      expect(
        calculateTotalTarget(controller.activePeriod.targetPerStudent),
        470000,
      );
      expect(countPaidStudents(payments), 35);
      expect(countInstallmentStudents(payments), 0);
      expect(countUnpaidStudents(payments), 12);
    });

    test('menyimpan setoran baru dan menambah log', () {
      final controller = KasController.seeded();
      addTearDown(controller.dispose);
      final logsBefore = controller.historyLogs.length;

      controller.savePayment(
        periodId: 'kas-2026-11',
        noAbsen: 36,
        amountPaid: 10000,
        paymentDate: DateTime(2026, 11, 9, 9, 30),
      );

      final payments = controller.paymentsFor('kas-2026-11');
      expect(countPaidStudents(payments), 36);
      expect(calculateTotalCollected(payments), 360000);
      expect(controller.historyLogs.length, logsBefore + 1);
      expect(controller.historyLogs.first.monthYear, 'November 2026');
      expect(controller.historyLogs.first.amount, 10000);
      expect(controller.historyLogs.first.note, 'Lunas transfer / Tunai');
      expect(controller.historyLogs.first.periodId, 'kas-2026-11');
      expect(controller.historyLogs.first.noAbsen, 36);
    });

    test('setoran cicilan menambah nominal secara akumulatif', () {
      final controller = KasController.seeded();
      addTearDown(controller.dispose);
      final logsBefore = controller.historyLogs.length;

      controller.addPayment(
        periodId: 'kas-2026-11',
        noAbsen: 36,
        amount: 4000,
        paymentDate: DateTime(2026, 11, 9, 9, 30),
      );

      var payment = controller
          .paymentsFor('kas-2026-11')
          .firstWhere((item) => item.noAbsen == 36);
      expect(payment.amountPaid, 4000);
      expect(payment.isPaidOff, isFalse);
      expect(payment.stateFor(10000), StudentPaymentState.installment);

      controller.addPayment(
        periodId: 'kas-2026-11',
        noAbsen: 36,
        amount: 6000,
        paymentDate: DateTime(2026, 11, 9, 10),
      );

      payment = controller
          .paymentsFor('kas-2026-11')
          .firstWhere((item) => item.noAbsen == 36);
      expect(payment.amountPaid, 10000);
      expect(payment.isPaidOff, isTrue);
      expect(payment.stateFor(10000), StudentPaymentState.paidOff);
      expect(controller.historyLogs.length, logsBefore + 2);
      expect(controller.historyLogs[0].amount, 6000);
      expect(controller.historyLogs[1].amount, 4000);
      expect(controller.historyLogs[0].noAbsen, 36);
      expect(
        calculateTotalCollected(controller.paymentsFor('kas-2026-11')),
        360000,
      );
      expect(countPaidStudents(controller.paymentsFor('kas-2026-11')), 36);
    });

    test('koreksi setoran dicatat sebagai nominal negatif', () {
      final controller = KasController.seeded();
      addTearDown(controller.dispose);

      controller.savePayment(
        periodId: 'kas-2026-11',
        noAbsen: 1,
        amountPaid: 5000,
        paymentDate: DateTime(2026, 11, 9),
      );

      final payment = controller
          .paymentsFor('kas-2026-11')
          .firstWhere((item) => item.noAbsen == 1);
      expect(payment.amountPaid, 5000);
      expect(payment.isPaidOff, isFalse);
      expect(controller.historyLogs.first.amount, -5000);
      expect(controller.historyLogs.first.note, 'Koreksi pembayaran');
    });

    test('membuat kegiatan custom dengan 47 baris pembayaran', () {
      final controller = KasController.seeded();
      addTearDown(controller.dispose);

      final period = controller.createCustomPeriod(
        title: 'Iuran Lomba 17 Agustus',
        totalClassTarget: 500000,
        now: DateTime(2026, 11, 9, 8),
      );

      expect(period, isNotNull);
      expect(period!.type, KasType.custom);
      expect(period.isCustom, isTrue);
      expect(period.isActive, isTrue);
      expect(period.totalClassTarget, 500000);
      expect(period.targetPerStudent, 11000);
      expect(period.monthYear, 'November 2026');

      expect(controller.periods.length, 5);
      expect(controller.periods[1].id, period.id);
      expect(controller.activePeriod.id, 'kas-2026-11');

      final payments = controller.paymentsFor(period.id);
      expect(payments.length, 47);
      expect(calculateTotalCollected(payments), 0);
      expect(countUnpaidStudents(payments), 47);
    });

    test('kegiatan custom tanpa pembulatan memakai pembagian penuh', () {
      final controller = KasController.seeded();
      addTearDown(controller.dispose);

      final period = controller.createCustomPeriod(
        title: 'Iuran Study Tour',
        totalClassTarget: 500000,
        roundPerStudent: false,
        now: DateTime(2026, 11, 9, 8),
      );

      expect(period, isNotNull);
      expect(period!.targetPerStudent, 10638);
    });

    test('setoran kegiatan custom tercatat pada periode yang tepat', () {
      final controller = KasController.seeded();
      addTearDown(controller.dispose);
      final period = controller.createCustomPeriod(
        title: 'Iuran Lomba 17 Agustus',
        totalClassTarget: 500000,
        now: DateTime(2026, 11, 9, 8),
      )!;

      controller.addPayment(
        periodId: period.id,
        noAbsen: 1,
        amount: 6000,
        paymentDate: DateTime(2026, 11, 9, 9),
      );

      expect(controller.logsForPeriod(period).length, 1);
      expect(
        controller.logsForStudent(periodId: period.id, noAbsen: 1).length,
        1,
      );
      expect(
        controller.logsForStudent(periodId: period.id, noAbsen: 2),
        isEmpty,
      );
      expect(
        controller.logsForStudent(periodId: 'kas-2026-11', noAbsen: 1),
        isNotEmpty,
      );
      expect(controller.logsForPeriod(period).first.periodId, period.id);
      expect(controller.logsForPeriod(period).first.periodTitle, period.title);
    });

    test('periode arsip tidak bisa diubah', () {
      final controller = KasController.seeded();
      addTearDown(controller.dispose);
      final before = calculateTotalCollected(
        controller.paymentsFor('kas-2026-10'),
      );
      final logsBefore = controller.historyLogs.length;

      controller.savePayment(
        periodId: 'kas-2026-10',
        noAbsen: 1,
        amountPaid: 0,
      );
      controller.addPayment(periodId: 'kas-2026-10', noAbsen: 44, amount: 5000);

      final after = calculateTotalCollected(
        controller.paymentsFor('kas-2026-10'),
      );
      expect(after, before);
      expect(controller.historyLogs.length, logsBefore);
    });
  });
}
