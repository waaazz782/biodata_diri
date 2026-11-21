import '../../class_data.dart';
import '../models/task_reminder.dart';

const _dayNames = <String>[
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _monthNames = <String>[
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

/// Nama hari Indonesia untuk [date]: Senin sampai Minggu.
String dayName(DateTime date) => _dayNames[date.weekday - 1];

/// Nama bulan Indonesia untuk [month]: Januari sampai Desember.
String monthName(int month) => _monthNames[month - 1];

/// Format tanggal panjang Indonesia, mis. "Selasa, 17 November 2026".
String formatFullDate(DateTime date) =>
    '${dayName(date)}, ${date.day} ${monthName(date.month)} ${date.year}';

/// Smart Deadline: mencari pertemuan berikutnya mata pelajaran
/// [subjectName] setelah tanggal [from] (default hari ini) berdasarkan
/// jadwal mingguan kelas. Akhir pekan selalu dilewati. Jika mapel
/// tidak ditemukan di jadwal, jatuh tempo dikembalikan +7 hari.
///
/// Contoh: Matematika dipilih hari Selasa diajarkan lagi hari Rabu,
/// jadi deadline-nya Rabu (+1 hari). Bahasa Indonesia hanya ada
/// hari Selasa, jadi deadline-nya Selasa minggu depan (+7 hari).
DateTime nextLessonOf(
  String subjectName, {
  DateTime? from,
  List<ClassDaySchedule> schedule = classDaySchedules,
}) {
  final start = dateOnly(from ?? DateTime.now());
  for (var offset = 1; offset <= 14; offset++) {
    final candidate = start.add(Duration(days: offset));
    if (candidate.weekday >= DateTime.saturday) {
      continue;
    }
    final dayIndex = candidate.weekday - DateTime.monday;
    if (dayIndex < schedule.length &&
        schedule[dayIndex].subjects.contains(subjectName)) {
      return candidate;
    }
  }
  return start.add(const Duration(days: 7));
}
