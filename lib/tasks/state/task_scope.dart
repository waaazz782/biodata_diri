import 'package:flutter/widgets.dart';

import 'task_controller.dart';

class TaskScope extends InheritedNotifier<TaskController> {
  const TaskScope({
    required TaskController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static TaskController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TaskScope>();
    assert(scope != null, 'TaskScope tidak ditemukan di atas widget ini.');
    return scope!.notifier!;
  }

  static TaskController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<TaskScope>();
    assert(scope != null, 'TaskScope tidak ditemukan di atas widget ini.');
    return scope!.notifier!;
  }
}
