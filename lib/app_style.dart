import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const ink = Color(0xFF1F2A33);
  static const inkSoft = Color(0xFF5E6A72);
  static const paper = Color(0xFFF3EDE2);
  static const card = Color(0xFFFFFCF6);
  static const line = Color(0xFFDED3C2);
  static const terracotta = Color(0xFFB2562E);
  static const forest = Color(0xFF356153);
  static const mustard = Color(0xFFC09A4C);
  static const plum = Color(0xFF7C4C5A);
  static const slate = Color(0xFF466A84);
}

const dayAccents = [
  AppColors.terracotta,
  AppColors.forest,
  AppColors.mustard,
  AppColors.plum,
  AppColors.slate,
];

class PaperBackground extends StatelessWidget {
  const PaperBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
        child,
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.line.withValues(alpha: 0.5);
    const gap = 22.0;
    for (double y = 11; y < size.height; y += gap) {
      for (double x = 11; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ClassStamp extends StatelessWidget {
  const ClassStamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.terracotta, width: 1.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'XII RPL',
          style: TextStyle(
            color: AppColors.terracotta,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
      ),
    );
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.trailing,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 27,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Padding(padding: const EdgeInsets.only(top: 2), child: trailing),
            ],
          ],
        ),
        const SizedBox(height: 9),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.inkSoft,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Container(width: 26, height: 3, color: AppColors.terracotta),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: AppColors.line)),
          ],
        ),
      ],
    );
  }
}
