import 'package:flutter/material.dart';

import '../app_style.dart';
import 'models/student_payment_status.dart';

/// Palet khusus modul kas: sampul buku kas navy, kertas ledger krem,
/// dan tinta hijau/merah untuk status setoran.
class KasColors {
  const KasColors._();

  static const navy = Color(0xFF0F172A);
  static const navySoft = Color(0xFF1A2740);
  static const navyLine = Color(0xFF2B3C5D);

  static const paper = AppColors.paper;
  static const card = AppColors.card;
  static const line = AppColors.line;
  static const ink = AppColors.ink;
  static const inkSoft = AppColors.inkSoft;

  static const green = Color(0xFF6FE0A0);
  static const greenInk = Color(0xFF24664C);
  static const greenWash = Color(0xFFE1F0E7);

  static const red = Color(0xFFBB5140);
  static const redWash = Color(0xFFF6E2DD);

  static const amber = Color(0xFFD3AB5C);
  static const amberInk = Color(0xFF8A641F);
  static const amberWash = Color(0xFFF7EBD3);
  static const white54 = Color(0x8AFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const white10 = Color(0x1AFFFFFF);
}

/// Garis putus-putus ala buku kas / sobekan kuitansi.
class KasDottedRule extends StatelessWidget {
  const KasDottedRule({
    this.color = KasColors.line,
    this.height = 1,
    this.dash = 4,
    this.gap = 4,
    super.key,
  });

  final Color color;
  final double height;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _DashLinePainter(
          color: color,
          dash: dash,
          gap: gap,
          thickness: height,
        ),
      ),
    );
  }
}

class _DashLinePainter extends CustomPainter {
  const _DashLinePainter({
    required this.color,
    required this.dash,
    required this.gap,
    required this.thickness,
  });

  final Color color;
  final double dash;
  final double gap;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += dash + gap) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap ||
        oldDelegate.thickness != thickness;
  }
}

class KasStatusStamp extends StatelessWidget {
  const KasStatusStamp({required this.state, this.compact = false, super.key});

  final StudentPaymentState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (accent, wash, displayLabel) = switch (state) {
      StudentPaymentState.paidOff => (
        KasColors.greenInk,
        KasColors.greenWash,
        'LUNAS',
      ),
      StudentPaymentState.installment => (
        KasColors.amberInk,
        KasColors.amberWash,
        'DICICIL',
      ),
      StudentPaymentState.unpaid => (
        KasColors.red,
        KasColors.redWash,
        'BELUM LUNAS',
      ),
    };

    return Transform.rotate(
      angle: -0.035,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: wash,
          border: Border.all(color: accent.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              displayLabel,
              style: TextStyle(
                color: accent,
                fontSize: compact ? 7.5 : 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
