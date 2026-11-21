import 'package:flutter/material.dart';

import 'app_style.dart';
import 'class_data.dart';
import 'kas/state/kas_controller.dart';
import 'kas/state/kas_scope.dart';
import 'services/local_storage_service.dart';
import 'services/schedule_controller.dart';
import 'splash_screen.dart';
import 'student_list_page.dart';
import 'tasks/state/task_controller.dart';
import 'tasks/state/task_scope.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.showSplash = true});

  /// Set to false to open the dashboard immediately, for example in tests.
  final bool showSplash;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocalStorageService _storage = LocalStorageService();
  late KasController _kasController;
  late TaskController _taskController;
  late ScheduleController _scheduleController;

  @override
  void initState() {
    super.initState();
    _kasController = KasController.seeded();
    _taskController = TaskController.seeded();
    _scheduleController = ScheduleController(schedule: classDaySchedules);
    _restoreSavedData();
  }

  Future<void> _restoreSavedData() async {
    final tasks = await _storage.loadTasks();
    final storedPeriods = await _storage.loadKasPeriods();
    final payments = await _storage.loadKasPayments();
    final history = await _storage.loadKasHistory();
    final schedule = await _storage.loadSchedule();
    final defaultNominal = await _storage.loadDefaultKasNominal();
    if (!mounted) return;
    final oldKas = _kasController;
    final oldTasks = _taskController;
    final oldSchedule = _scheduleController;
    setState(() {
      _taskController = TaskController.restored(
        tasks: tasks,
        storage: _storage,
      );
      _kasController = storedPeriods.isEmpty
          ? KasController.seeded(
              storage: _storage,
              defaultNominal: defaultNominal,
            )
          : KasController(
              periods: storedPeriods,
              paymentsByPeriod: payments,
              historyLogs: history,
              storage: _storage,
            );
      _scheduleController = ScheduleController(
        schedule: schedule,
        storage: _storage,
      );
    });
    oldKas.dispose();
    oldTasks.dispose();
    oldSchedule.dispose();
  }

  @override
  void dispose() {
    _kasController.dispose();
    _taskController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScheduleScope(
      controller: _scheduleController,
      child: TaskScope(
        controller: _taskController,
        child: KasScope(
          controller: _kasController,
          child: MaterialApp(
            title: 'Data Siswa XII RPL',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.terracotta,
                primary: AppColors.ink,
                surface: AppColors.paper,
              ),
              scaffoldBackgroundColor: AppColors.paper,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.paper,
                foregroundColor: AppColors.ink,
                centerTitle: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                shape: Border(bottom: BorderSide(color: AppColors.line)),
                titleTextStyle: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: AppColors.line,
                thickness: 1,
                space: 1,
              ),
            ),
            home: widget.showSplash
                ? const SplashGate()
                : const StudentListPage(),
          ),
        ),
      ),
    );
  }
}
