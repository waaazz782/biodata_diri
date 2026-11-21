import 'package:flutter/material.dart';

import '../task_theme.dart';

/// Badge kecil sisa waktu menuju jatuh tempo: SELESAI, TERLAMBAT,
/// HARI INI, atau H-1 sampai H-n.
class TaskCountdownBadge extends StatelessWidget {
  const TaskCountdownBadge({
    required this.daysLeft,
    this.isCompleted = false,
    super.key,
  });

  final int daysLeft;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final Color wash;
    if (isCompleted) {
      label = 'SELESAI';
      color = TaskColors.greenInk;
      wash = TaskColors.greenWash;
    } else if (daysLeft < 0) {
      label = 'TERLAMBAT';
      color = TaskColors.red;
      wash = TaskColors.redWash;
    } else if (daysLeft == 0) {
      label = 'HARI INI';
      color = TaskColors.red;
      wash = TaskColors.redWash;
    } else if (daysLeft <= 3) {
      label = 'H-$daysLeft';
      color = TaskColors.amberDeep;
      wash = TaskColors.amberWash;
    } else {
      label = 'H-$daysLeft';
      color = TaskColors.cyanInk;
      wash = TaskColors.cyanWash;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
