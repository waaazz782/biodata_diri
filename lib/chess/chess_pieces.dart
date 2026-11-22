import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

class ChessPieceWidget extends StatelessWidget {
  const ChessPieceWidget({
    required this.type,
    required this.isWhite,
    this.size,
    super.key,
  });

  final chess.PieceType type;
  final bool isWhite;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _ChessPiecePainter(
            type: type,
            isWhite: isWhite,
          ),
        ),
      ),
    );
  }
}

class _ChessPiecePainter extends CustomPainter {
  const _ChessPiecePainter({
    required this.type,
    required this.isWhite,
  });

  final chess.PieceType type;
  final bool isWhite;

  static const Color whiteFill = Color(0xFFFFFFFF);
  static const Color whiteStroke = Color(0xFF0F172A);
  static const Color blackFill = Color(0xFF0F172A);
  static const Color blackStroke = Color(0xFFF8FAFC);
  static const Color blackAccent = Color(0xFF94A3B8);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = isWhite ? whiteFill : blackFill
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = isWhite ? whiteStroke : blackStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.045).clamp(1.4, 3.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentPaint = Paint()
      ..color = isWhite ? whiteStroke : blackAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.035).clamp(1.0, 2.2)
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case chess.PieceType.PAWN:
        _drawPawn(canvas, w, h, fillPaint, strokePaint, accentPaint);
        break;
      case chess.PieceType.KNIGHT:
        _drawKnight(canvas, w, h, fillPaint, strokePaint, accentPaint);
        break;
      case chess.PieceType.BISHOP:
        _drawBishop(canvas, w, h, fillPaint, strokePaint, accentPaint);
        break;
      case chess.PieceType.ROOK:
        _drawRook(canvas, w, h, fillPaint, strokePaint, accentPaint);
        break;
      case chess.PieceType.QUEEN:
        _drawQueen(canvas, w, h, fillPaint, strokePaint, accentPaint);
        break;
      case chess.PieceType.KING:
        _drawKing(canvas, w, h, fillPaint, strokePaint, accentPaint);
        break;
    }
  }

  void _drawPawn(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint accent,
  ) {
    // Base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.77, w * 0.56, h * 0.11),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(baseRect, fill);
    canvas.drawRRect(baseRect, stroke);

    // Body
    final body = Path()
      ..moveTo(w * 0.39, h * 0.48)
      ..cubicTo(w * 0.42, h * 0.65, w * 0.30, h * 0.72, w * 0.28, h * 0.77)
      ..lineTo(w * 0.72, h * 0.77)
      ..cubicTo(w * 0.70, h * 0.72, w * 0.58, h * 0.65, w * 0.61, h * 0.48)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Collar
    final collar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.47),
        width: w * 0.34,
        height: h * 0.05,
      ),
      Radius.circular(h * 0.025),
    );
    canvas.drawRRect(collar, fill);
    canvas.drawRRect(collar, stroke);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.29), w * 0.16, fill);
    canvas.drawCircle(Offset(w * 0.5, h * 0.29), w * 0.16, stroke);
  }

  void _drawKnight(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint accent,
  ) {
    // Base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.77, w * 0.60, h * 0.11),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(baseRect, fill);
    canvas.drawRRect(baseRect, stroke);

    // Knight Profile Path
    final horse = Path()
      ..moveTo(w * 0.25, h * 0.77)
      ..lineTo(w * 0.28, h * 0.56)
      ..cubicTo(w * 0.26, h * 0.46, w * 0.17, h * 0.43, w * 0.17, h * 0.34)
      ..lineTo(w * 0.27, h * 0.28)
      ..cubicTo(w * 0.33, h * 0.27, w * 0.38, h * 0.22, w * 0.40, h * 0.14)
      ..lineTo(w * 0.46, h * 0.12)
      ..lineTo(w * 0.49, h * 0.20)
      ..cubicTo(w * 0.64, h * 0.24, w * 0.77, h * 0.40, w * 0.75, h * 0.77)
      ..close();

    canvas.drawPath(horse, fill);
    canvas.drawPath(horse, stroke);

    // Eye dot
    canvas.drawCircle(
      Offset(w * 0.34, h * 0.31),
      w * 0.03,
      isWhite ? stroke : accent,
    );

    // Mane accent curve
    final mane = Path()
      ..moveTo(w * 0.56, h * 0.30)
      ..quadraticBezierTo(w * 0.68, h * 0.42, w * 0.64, h * 0.62);
    canvas.drawPath(mane, accent);
  }

  void _drawBishop(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint accent,
  ) {
    // Base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.77, w * 0.60, h * 0.11),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(baseRect, fill);
    canvas.drawRRect(baseRect, stroke);

    // Body
    final body = Path()
      ..moveTo(w * 0.37, h * 0.58)
      ..cubicTo(w * 0.41, h * 0.67, w * 0.30, h * 0.72, w * 0.26, h * 0.77)
      ..lineTo(w * 0.74, h * 0.77)
      ..cubicTo(w * 0.70, h * 0.72, w * 0.59, h * 0.67, w * 0.63, h * 0.58)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Collar
    final collar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.56),
        width: w * 0.36,
        height: h * 0.05,
      ),
      Radius.circular(h * 0.025),
    );
    canvas.drawRRect(collar, fill);
    canvas.drawRRect(collar, stroke);

    // Mitre
    final mitre = Path()
      ..moveTo(w * 0.5, h * 0.18)
      ..cubicTo(w * 0.68, h * 0.24, w * 0.68, h * 0.46, w * 0.57, h * 0.54)
      ..lineTo(w * 0.43, h * 0.54)
      ..cubicTo(w * 0.32, h * 0.46, w * 0.32, h * 0.24, w * 0.5, h * 0.18)
      ..close();
    canvas.drawPath(mitre, fill);
    canvas.drawPath(mitre, stroke);

    // Slit accent
    canvas.drawLine(
      Offset(w * 0.44, h * 0.26),
      Offset(w * 0.56, h * 0.36),
      accent,
    );

    // Finial ball
    canvas.drawCircle(Offset(w * 0.5, h * 0.14), w * 0.04, fill);
    canvas.drawCircle(Offset(w * 0.5, h * 0.14), w * 0.04, stroke);
  }

  void _drawRook(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint accent,
  ) {
    // Base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.19, h * 0.76, w * 0.62, h * 0.12),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(baseRect, fill);
    canvas.drawRRect(baseRect, stroke);

    // Tower Body
    final tower = Path()
      ..moveTo(w * 0.28, h * 0.34)
      ..lineTo(w * 0.25, h * 0.76)
      ..lineTo(w * 0.75, h * 0.76)
      ..lineTo(w * 0.72, h * 0.34)
      ..close();
    canvas.drawPath(tower, fill);
    canvas.drawPath(tower, stroke);

    // Crenellated Top
    final top = Path()
      ..moveTo(w * 0.23, h * 0.22)
      ..lineTo(w * 0.23, h * 0.34)
      ..lineTo(w * 0.77, h * 0.34)
      ..lineTo(w * 0.77, h * 0.22)
      ..lineTo(w * 0.65, h * 0.22)
      ..lineTo(w * 0.65, h * 0.27)
      ..lineTo(w * 0.57, h * 0.27)
      ..lineTo(w * 0.57, h * 0.22)
      ..lineTo(w * 0.43, h * 0.22)
      ..lineTo(w * 0.43, h * 0.27)
      ..lineTo(w * 0.35, h * 0.27)
      ..lineTo(w * 0.35, h * 0.22)
      ..close();
    canvas.drawPath(top, fill);
    canvas.drawPath(top, stroke);

    // Window slit in tower
    final window = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.53),
        width: w * 0.08,
        height: h * 0.13,
      ),
      Radius.circular(h * 0.03),
    );
    canvas.drawRRect(window, isWhite ? stroke : accent);
  }

  void _drawQueen(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint accent,
  ) {
    // Base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.77, w * 0.64, h * 0.11),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(baseRect, fill);
    canvas.drawRRect(baseRect, stroke);

    // Flared lower dress
    final dress = Path()
      ..moveTo(w * 0.36, h * 0.58)
      ..cubicTo(w * 0.40, h * 0.68, w * 0.28, h * 0.72, w * 0.23, h * 0.77)
      ..lineTo(w * 0.77, h * 0.77)
      ..cubicTo(w * 0.72, h * 0.72, w * 0.60, h * 0.68, w * 0.64, h * 0.58)
      ..close();
    canvas.drawPath(dress, fill);
    canvas.drawPath(dress, stroke);

    // Waist belt
    final belt = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.56),
        width: w * 0.38,
        height: h * 0.05,
      ),
      Radius.circular(h * 0.025),
    );
    canvas.drawRRect(belt, fill);
    canvas.drawRRect(belt, stroke);

    // Crown Body
    final crown = Path()
      ..moveTo(w * 0.22, h * 0.26)
      ..lineTo(w * 0.28, h * 0.36)
      ..lineTo(w * 0.36, h * 0.22)
      ..lineTo(w * 0.43, h * 0.36)
      ..lineTo(w * 0.50, h * 0.18)
      ..lineTo(w * 0.57, h * 0.36)
      ..lineTo(w * 0.64, h * 0.22)
      ..lineTo(w * 0.72, h * 0.36)
      ..lineTo(w * 0.78, h * 0.26)
      ..cubicTo(w * 0.74, h * 0.46, w * 0.66, h * 0.52, w * 0.62, h * 0.54)
      ..lineTo(w * 0.38, h * 0.54)
      ..cubicTo(w * 0.34, h * 0.52, w * 0.26, h * 0.46, w * 0.22, h * 0.26)
      ..close();
    canvas.drawPath(crown, fill);
    canvas.drawPath(crown, stroke);

    // 5 Pearls on tips
    const tips = [
      Offset(0.22, 0.25),
      Offset(0.36, 0.21),
      Offset(0.50, 0.17),
      Offset(0.64, 0.21),
      Offset(0.78, 0.25),
    ];
    for (final tip in tips) {
      canvas.drawCircle(Offset(w * tip.dx, h * tip.dy), w * 0.032, fill);
      canvas.drawCircle(Offset(w * tip.dx, h * tip.dy), w * 0.032, stroke);
    }
  }

  void _drawKing(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint accent,
  ) {
    // Base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.17, h * 0.77, w * 0.66, h * 0.11),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(baseRect, fill);
    canvas.drawRRect(baseRect, stroke);

    // Stately Body
    final body = Path()
      ..moveTo(w * 0.34, h * 0.58)
      ..cubicTo(w * 0.38, h * 0.68, w * 0.26, h * 0.72, w * 0.22, h * 0.77)
      ..lineTo(w * 0.78, h * 0.77)
      ..cubicTo(w * 0.74, h * 0.72, w * 0.62, h * 0.68, w * 0.66, h * 0.58)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Belt
    final belt = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.56),
        width: w * 0.40,
        height: h * 0.05,
      ),
      Radius.circular(h * 0.025),
    );
    canvas.drawRRect(belt, fill);
    canvas.drawRRect(belt, stroke);

    // Crown Dome
    final crown = Path()
      ..moveTo(w * 0.24, h * 0.32)
      ..cubicTo(w * 0.26, h * 0.22, w * 0.46, h * 0.22, w * 0.50, h * 0.24)
      ..cubicTo(w * 0.54, h * 0.22, w * 0.74, h * 0.22, w * 0.76, h * 0.32)
      ..cubicTo(w * 0.76, h * 0.46, w * 0.68, h * 0.52, w * 0.63, h * 0.54)
      ..lineTo(w * 0.37, h * 0.54)
      ..cubicTo(w * 0.32, h * 0.52, w * 0.24, h * 0.46, w * 0.24, h * 0.32)
      ..close();
    canvas.drawPath(crown, fill);
    canvas.drawPath(crown, stroke);

    // Cross at top
    // Vertical
    final vCross = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.16),
      width: w * 0.06,
      height: h * 0.13,
    );
    // Horizontal
    final hCross = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.15),
      width: w * 0.18,
      height: h * 0.05,
    );
    canvas.drawRect(vCross, fill);
    canvas.drawRect(vCross, stroke);
    canvas.drawRect(hCross, fill);
    canvas.drawRect(hCross, stroke);
  }

  @override
  bool shouldRepaint(covariant _ChessPiecePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.isWhite != isWhite;
  }
}
