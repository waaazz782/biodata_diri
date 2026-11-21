enum StudentPaymentState { paidOff, installment, unpaid }

class StudentPaymentStatus {
  const StudentPaymentStatus({
    required this.noAbsen,
    required this.studentName,
    required this.photoPath,
    required this.amountPaid,
    required this.isPaidOff,
    this.paymentDate,
  });

  final int noAbsen;
  final String studentName;
  final String photoPath;
  final double amountPaid;
  final bool isPaidOff;
  final DateTime? paymentDate;

  Map<String, dynamic> toJson() => {
    'noAbsen': noAbsen,
    'studentName': studentName,
    'photoPath': photoPath,
    'amountPaid': amountPaid,
    'isPaidOff': isPaidOff,
    'paymentDate': paymentDate?.toIso8601String(),
  };

  factory StudentPaymentStatus.fromJson(Map<String, dynamic> json) =>
      StudentPaymentStatus(
        noAbsen: json['noAbsen'] as int,
        studentName: json['studentName'] as String,
        photoPath: json['photoPath'] as String? ?? '',
        amountPaid: (json['amountPaid'] as num).toDouble(),
        isPaidOff: json['isPaidOff'] as bool? ?? false,
        paymentDate: json['paymentDate'] == null
            ? null
            : DateTime.parse(json['paymentDate'] as String),
      );

  bool get hasInstallment => amountPaid > 0 && !isPaidOff;

  StudentPaymentState stateFor(double targetPerStudent) {
    if (amountPaid <= 0) {
      return StudentPaymentState.unpaid;
    }
    if (isPaidOff ||
        (targetPerStudent > 0 && amountPaid + 0.001 >= targetPerStudent)) {
      return StudentPaymentState.paidOff;
    }
    return StudentPaymentState.installment;
  }

  StudentPaymentStatus copyWith({
    double? amountPaid,
    bool? isPaidOff,
    DateTime? paymentDate,
    bool clearPaymentDate = false,
  }) {
    return StudentPaymentStatus(
      noAbsen: noAbsen,
      studentName: studentName,
      photoPath: photoPath,
      amountPaid: amountPaid ?? this.amountPaid,
      isPaidOff: isPaidOff ?? this.isPaidOff,
      paymentDate: clearPaymentDate ? null : (paymentDate ?? this.paymentDate),
    );
  }
}
