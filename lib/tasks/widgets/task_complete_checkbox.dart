import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../task_theme.dart';

/// Kotak centang untuk menandai tugas selesai, lengkap dengan haptic
/// feedback dan animasi centang yang muncul halus.
class TaskCompleteCheckbox extends StatelessWidget {
  const TaskCompleteCheckbox({
    required this.taskId,
    required this.value,
    required this.onChanged,
    this.size = 22,
    super.key,
  });

  final String taskId;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.36);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('task-checkbox-$taskId'),
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        splashColor: TaskColors.cyan.withValues(alpha: 0.22),
        highlightColor: TaskColors.cyan.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: value ? TaskColors.greenInk : Colors.transparent,
            borderRadius: radius,
            border: Border.all(
              color: value ? TaskColors.greenInk : TaskColors.line,
              width: 1.5,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: value
                  ? Icon(
                      Icons.check_rounded,
                      key: const ValueKey('task-check-on'),
                      size: size - 8,
                      color: TaskColors.greenWash,
                    )
                  : const SizedBox.shrink(key: ValueKey('task-check-off')),
            ),
          ),
        ),
      ),
    );
  }
}
