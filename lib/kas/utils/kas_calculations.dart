import '../models/student_payment_status.dart';

double calculateTotalCollected(List<StudentPaymentStatus> list) {
  return list.fold<double>(0, (total, student) => total + student.amountPaid);
}

double calculateTotalTarget(double targetPerStudent, {int totalStudents = 47}) {
  return targetPerStudent * totalStudents;
}

/// Nominal per siswa dari target total kelas.
///
/// Saat [roundUp] aktif, nominal dibulatkan ke ribuan berikutnya supaya
/// mudah dibayar (contoh: Rp 10.638 menjadi Rp 11.000).
double calculatePerStudentTarget(
  double totalClassTarget, {
  int totalStudents = 47,
  bool roundUp = true,
}) {
  if (totalStudents <= 0 || totalClassTarget <= 0) {
    return 0;
  }
  final raw = totalClassTarget / totalStudents;
  if (!roundUp) {
    return raw.roundToDouble();
  }
  return (raw / 1000).ceilToDouble() * 1000;
}

int countPaidStudents(List<StudentPaymentStatus> list) {
  return list.where((student) => student.isPaidOff).length;
}

int countInstallmentStudents(List<StudentPaymentStatus> list) {
  return list.where((student) => student.hasInstallment).length;
}

int countUnpaidStudents(List<StudentPaymentStatus> list) {
  return list.where((student) => student.amountPaid <= 0).length;
}

double calculateProgressPercentage(double totalCollected, double totalTarget) {
  if (totalTarget <= 0) {
    return 0;
  }
  return (totalCollected / totalTarget).clamp(0.0, 1.0);
}

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _shortMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatRupiah(num value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }
  return '${rounded < 0 ? '-' : ''}Rp $buffer';
}

String formatMonthYear(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.year}';
}

String formatFullDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

String formatShortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} '
      '${_shortMonthNames[date.month - 1]} ${date.year}';
}

String formatLogTimestamp(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatShortDate(date)} · $hour.$minute';
}
