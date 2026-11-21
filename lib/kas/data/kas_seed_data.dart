import '../../student_profile.dart';
import '../models/student_payment_status.dart';

class KasSeedData {
  const KasSeedData._();

  static const totalStudents = 47;

  /// Baris pembayaran kosong untuk 47 siswa, dipakai saat kegiatan baru dibuat.
  static List<StudentPaymentStatus> emptyPayments() {
    return [
      for (final student in studentProfiles)
        StudentPaymentStatus(
          noAbsen: student.number,
          studentName: student.name,
          photoPath: student.photoPath,
          amountPaid: 0,
          isPaidOff: false,
        ),
    ];
  }

}
