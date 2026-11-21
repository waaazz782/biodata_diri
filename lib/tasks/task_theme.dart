import 'package:flutter/material.dart';

import '../app_style.dart';

/// Palet khusus modul tugas: sampul navy, aksen cyan, dan badge
/// peringatan amber/merah untuk hitung mundur jatuh tempo.
class TaskColors {
  const TaskColors._();

  static const navy = Color(0xFF0F172A);
  static const navySoft = Color(0xFF1A2740);

  static const cyan = Color(0xFF38BDF8);
  static const cyanInk = Color(0xFF0E7490);
  static const cyanWash = Color(0xFFE4F5FD);

  static const amber = Color(0xFFF5B93B);
  static const amberDeep = Color(0xFFD98324);
  static const amberInk = Color(0xFF8A641F);
  static const amberWash = Color(0xFFF7EBD3);

  static const red = Color(0xFFBB5140);
  static const redWash = Color(0xFFF6E2DD);

  static const greenInk = Color(0xFF24664C);
  static const greenWash = Color(0xFFE1F0E7);

  static const paper = AppColors.paper;
  static const card = AppColors.card;
  static const line = AppColors.line;
  static const ink = AppColors.ink;
  static const inkSoft = AppColors.inkSoft;
}

/// Garis putus-putus ala sobekan kuitansi, pemisah antar bagian tugas.
class TaskDottedRule extends StatelessWidget {
  const TaskDottedRule({
    this.color = TaskColors.line,
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
