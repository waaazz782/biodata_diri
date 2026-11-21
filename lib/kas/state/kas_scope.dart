import 'package:flutter/widgets.dart';

import 'kas_controller.dart';

class KasScope extends InheritedNotifier<KasController> {
  const KasScope({
    required KasController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static KasController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<KasScope>();
    assert(scope != null, 'KasScope tidak ditemukan di atas widget ini.');
    return scope!.notifier!;
  }

  static KasController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<KasScope>();
    assert(scope != null, 'KasScope tidak ditemukan di atas widget ini.');
    return scope!.notifier!;
  }
}
