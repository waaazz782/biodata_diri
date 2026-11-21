import 'package:flutter/material.dart';

import '../kas_theme.dart';
import '../models/student_payment_status.dart';
import '../utils/kas_calculations.dart';

class StudentPaymentTile extends StatelessWidget {
  const StudentPaymentTile({
    required this.payment,
    required this.targetPerStudent,
    required this.onTap,
    super.key,
  });

  final StudentPaymentStatus payment;
  final double targetPerStudent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = payment.noAbsen.toString().padLeft(2, '0');
    final state = payment.stateFor(targetPerStudent);
    final date = payment.paymentDate;
    final remaining = (targetPerStudent - payment.amountPaid).clamp(
      0.0,
      double.infinity,
    );
    final accent = switch (state) {
      StudentPaymentState.paidOff => KasColors.greenInk,
      StudentPaymentState.installment => KasColors.amberInk,
      StudentPaymentState.unpaid => KasColors.red,
    };

    return Material(
      key: ValueKey('kas-student-$number'),
      color: KasColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(
          color: state == StudentPaymentState.installment
              ? KasColors.amber.withValues(alpha: 0.5)
              : KasColors.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 11, 9),
          child: Row(
            children: [
              _Avatar(payment: payment, state: state),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number - ${payment.studentName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KasColors.ink,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          date == null
                              ? Icons.remove_circle_outline
                              : (state == StudentPaymentState.installment
                                    ? Icons.hourglass_bottom_rounded
                                    : Icons.event_available_outlined),
                          size: 11,
                          color: date == null ? KasColors.inkSoft : accent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            date == null
                                ? 'Belum ada setoran'
                                : '${state == StudentPaymentState.installment ? 'Cicilan' : 'Dibayar'} '
                                      '${formatShortDate(date)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: KasColors.inkSoft,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  KasStatusStamp(state: state, compact: true),
                  const SizedBox(height: 6),
                  Text(
                    state == StudentPaymentState.unpaid
                        ? formatRupiah(0)
                        : '${formatRupiah(payment.amountPaid)} / '
                              '${formatRupiah(targetPerStudent).replaceFirst('Rp ', '')}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (state == StudentPaymentState.installment) ...[
                    const SizedBox(height: 2),
                    Text(
                      'sisa ${formatRupiah(remaining)}',
                      style: const TextStyle(
                        color: KasColors.inkSoft,
                        fontSize: 8.2,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: KasColors.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.payment, required this.state});

  final StudentPaymentStatus payment;
  final StudentPaymentState state;

  @override
  Widget build(BuildContext context) {
    final borderColor = switch (state) {
      StudentPaymentState.paidOff => KasColors.greenInk.withValues(alpha: 0.35),
      StudentPaymentState.installment => KasColors.amber.withValues(
        alpha: 0.65,
      ),
      StudentPaymentState.unpaid => KasColors.line,
    };

    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        color: KasColors.paper,
      ),
      child: ClipOval(
        child: Image.asset(
          payment.photoPath,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          semanticLabel: 'Foto ${payment.studentName}',
          errorBuilder: (context, error, stackTrace) => Container(
            color: KasColors.paper,
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_outline,
              size: 20,
              color: KasColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
