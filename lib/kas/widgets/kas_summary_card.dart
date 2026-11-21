import 'package:flutter/material.dart';

import '../kas_theme.dart';
import '../models/kas_period.dart';
import '../models/student_payment_status.dart';
import '../utils/kas_calculations.dart';

class KasSummaryCard extends StatelessWidget {
  const KasSummaryCard({
    required this.period,
    required this.payments,
    this.totalStudents = 47,
    this.balanceHidden = false,
    this.onToggleBalance,
    this.onTap,
    super.key,
  });

  final KasPeriod period;
  final List<StudentPaymentStatus> payments;
  final int totalStudents;
  final bool balanceHidden;
  final VoidCallback? onToggleBalance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final totalCollected = calculateTotalCollected(payments);
    final totalTarget = period.totalClassTarget;
    final paidCount = countPaidStudents(payments);
    final installmentCount = countInstallmentStudents(payments);
    final unpaidCount = countUnpaidStudents(payments);
    final progress = calculateProgressPercentage(totalCollected, totalTarget);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: KasColors.navy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: KasColors.navy.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.06),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _LedgerPainter()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: period.isActive
                                      ? KasColors.green
                                      : KasColors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${period.title.toUpperCase()} · '
                                  '${period.monthYear.toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: KasColors.white54,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Total terkumpul',
                            style: TextStyle(
                              color: KasColors.white54,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
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
                                  child: Text(
                                    balanceHidden
                                        ? 'Rp ••••••'
                                        : formatRupiah(totalCollected),
                                    key: ValueKey(
                                      'kas-detail-balance-$balanceHidden',
                                    ),
                                    style: const TextStyle(
                                      color: KasColors.green,
                                      fontSize: 30,
                                      height: 1,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.9,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                if (onToggleBalance != null) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    key: const ValueKey(
                                      'kas-detail-toggle-balance-button',
                                    ),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onToggleBalance,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                      child: Icon(
                                        balanceHidden
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        key: ValueKey(
                                          'kas-detail-eye-$balanceHidden',
                                        ),
                                        size: 20,
                                        color: KasColors.white54,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            child: Text(
                              balanceHidden
                                  ? 'Target Rp •••••• · Rp ••••••/siswa'
                                  : 'Target ${formatRupiah(totalTarget)} · '
                                      '${formatRupiah(period.targetPerStudent)}/siswa',
                              key: ValueKey('kas-detail-target-$balanceHidden'),
                              style: const TextStyle(
                                color: KasColors.white54,
                                fontSize: 10,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _StudentSeal(totalStudents: totalStudents),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: KasColors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          KasColors.green,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${(progress * 100).round()}% terkumpul',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: KasColors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$paidCount dari $totalStudents siswa lunas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: KasColors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _SummaryBadge(
                      count: paidCount,
                      label: 'LUNAS',
                      color: KasColors.green,
                    ),
                    _SummaryBadge(
                      count: installmentCount,
                      label: 'DICICIL',
                      color: KasColors.amber,
                    ),
                    _SummaryBadge(
                      count: unpaidCount,
                      label: 'BELUM LUNAS',
                      color: const Color(0xFFFF8B77),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Text(
                        period.isCustom
                            ? (period.isActive
                                  ? 'KEGIATAN AKTIF'
                                  : 'ARSIP KEGIATAN')
                            : (period.isActive
                                  ? 'BULAN BERJALAN'
                                  : 'REKAP ARSIP'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.32),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
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

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentSeal extends StatelessWidget {
  const _StudentSeal({required this.totalStudents});

  final int totalStudents;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.035,
      child: Container(
        width: 61,
        height: 61,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$totalStudents',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'SISWA',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 6.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerPainter extends CustomPainter {
  const _LedgerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (double y = 28; y < size.height; y += 29) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    final margin = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(13, 0), Offset(13, size.height), margin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
