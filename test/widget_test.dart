import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helloworld/main.dart';

void main() {
  testWidgets('wallpaper settings persist the selected overlay opacity', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp(showSplash: false));

    await tester.tap(find.byKey(const ValueKey('wallpaper-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tampilan & Wallpaper Daftar Siswa'), findsOneWidget);
    expect(find.text('Pilih Foto dari Galeri / Google Foto'), findsOneWidget);
    expect(find.text('Reset ke Warna Cream Default'), findsNothing);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('wallpaper-opacity-slider')),
    );
    expect(slider.value, 0.25);
    slider.onChanged!(0.6);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getDouble('wallpaper_overlay_opacity'), 0.6);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Daftar siswa'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('student-list-wallpaper-area')),
      findsOneWidget,
    );
  });

  testWidgets('opens a student profile from the class list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(showSplash: false));

    expect(find.text('DATA SISWA'), findsOneWidget);
    expect(find.text('XII RPL'), findsOneWidget);
    expect(find.byKey(const ValueKey('class-student-count')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('student-card-photo-01')));
    await tester.pumpAndSettle();

    expect(find.text('Profil Siswa'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('student-detail-photo-frame')),
      findsOneWidget,
    );
    final detailPhoto = tester.widget<Image>(
      find.byKey(const ValueKey('student-detail-photo')),
    );
    expect(detailPhoto.fit, BoxFit.contain);
    expect(find.text('Achmad Saifudin Amri'), findsWidgets);
    expect(find.text('No. 01 • Kelas XII RPL'), findsOneWidget);
    expect(find.text('17 Tahun'), findsOneWidget);
    expect(find.text('Main Game Mobile Legends'), findsOneWidget);
    expect(find.text('Jember, 13 Januari 2009'), findsOneWidget);
    expect(find.text('NAMA'), findsOneWidget);
    expect(find.text('NOMOR ABSEN'), findsOneWidget);
    expect(find.text('UMUR'), findsOneWidget);
    expect(find.text('HOBI'), findsOneWidget);
    expect(find.text('TEMPAT, TANGGAL LAHIR'), findsOneWidget);
    expect(find.text('Belum diisi'), findsNothing);
    expect(find.text('Dewa Amriansyah'), findsNothing);
  });

  testWidgets('opens class structure and schedule pages from dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(showSplash: false));

    await tester.tap(
      find.byKey(const ValueKey('menu-toggle-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Struktur Kelas'));
    await tester.pumpAndSettle();
    expect(find.text('STRUKTUR ORGANISASI'), findsOneWidget);
    expect(find.text('Bayu Ragiel Pamungkas, S.Kom'), findsOneWidget);
    expect(find.text('KETUA KELAS'), findsOneWidget);
    expect(find.text('WAKIL KETUA'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadwal Mapel'));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal Pelajaran'), findsOneWidget);
    expect(find.text('Senin sampai Jumat'), findsOneWidget);
    expect(find.text('SENIN'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadwal Piket'));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal Piket'), findsOneWidget);
    expect(find.text('Kelas Bersih,\nBelajar Nyaman'), findsOneWidget);
    expect(find.text('47 siswa, terbagi ke 5 hari'), findsOneWidget);
  });

  testWidgets('fits the main pages on a narrow phone screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp(showSplash: false));

    await tester.tap(
      find.byKey(const ValueKey('menu-toggle-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Struktur Kelas'));
    await tester.pumpAndSettle();
    expect(find.text('Kepengurusan\nKelas XII RPL'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadwal Mapel'));
    await tester.pumpAndSettle();
    expect(find.text('Pelajaran 1'), findsNothing);
    expect(find.text('PELAJARAN 1'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadwal Piket'));
    await tester.pumpAndSettle();
    expect(find.text('Senin'), findsOneWidget);
  });

  testWidgets('opens the kas ledger and records a payment', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp(showSplash: false));
    await tester.tap(find.text('Kas & Urunan Kelas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kas-open-button')));
    await tester.pumpAndSettle();

    expect(find.text('Kas & Urunan XII RPL'), findsOneWidget);
    expect(find.text('Rp 350.000'), findsWidgets);
    expect(find.text('35 dari 47 siswa lunas'), findsOneWidget);
    expect(find.text('Semua (47)'), findsOneWidget);
    expect(find.text('Lunas (35)'), findsOneWidget);
    expect(find.text('Dicicil (0)'), findsOneWidget);
    expect(find.text('Belum Lunas (12)'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('kas-search-field')),
      'Rahmat Febriyanto',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kas-student-36')), findsOneWidget);
    expect(find.byKey(const ValueKey('kas-student-37')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('kas-student-36')));
    await tester.pumpAndSettle();
    expect(find.text('KUITANSI SETORAN'), findsOneWidget);
    expect(find.text('Tambah Setoran'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('kas-amount-field')),
      '10000',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('kas-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kas-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Rp 360.000'), findsWidgets);
    expect(find.text('36 dari 47 siswa lunas'), findsOneWidget);
  });

  testWidgets('creates a custom activity and records installments', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp(showSplash: false));
    await tester.tap(find.text('Kas & Urunan Kelas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kas-open-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('kas-create-activity-button')));
    await tester.pumpAndSettle();

    expect(find.text('Buat urunan\nkegiatan kelas'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('kas-activity-title')),
      'Iuran Lomba 17 Agustus',
    );
    await tester.enterText(
      find.byKey(const ValueKey('kas-activity-target')),
      '500000',
    );
    await tester.pumpAndSettle();

    expect(find.text('Rp 11.000'), findsOneWidget);
    expect(find.text('Rp 10.638 dibulatkan ke atas.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kas-round-switch')));
    await tester.pumpAndSettle();
    expect(find.text('Rp 10.638'), findsOneWidget);
    expect(find.text('Hasil pembagian target kelas.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kas-round-switch')));
    await tester.pumpAndSettle();
    expect(find.text('Rp 11.000'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kas-create-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Iuran Lomba 17 Agustus'), findsWidgets);
    expect(find.text('Target Rp 500.000 · Rp 11.000/siswa'), findsOneWidget);
    expect(find.text('0 dari 47 siswa lunas'), findsOneWidget);
    expect(find.text('Semua (47)'), findsOneWidget);
    expect(find.text('Lunas (0)'), findsOneWidget);
    expect(find.text('Dicicil (0)'), findsOneWidget);
    expect(find.text('Belum Lunas (47)'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('kas-student-01')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kas-student-01')));
    await tester.pumpAndSettle();

    expect(
      find.text('Belum ada riwayat setoran untuk siswa ini.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('kas-amount-field')),
      '6000',
    );
    await tester.pumpAndSettle();
    expect(find.text('Rp 6.000'), findsWidgets);
    await tester.ensureVisible(find.byKey(const ValueKey('kas-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kas-save-button')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('kas-scroll')),
      const Offset(0, 1400),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dicicil (1)'), findsOneWidget);
    expect(find.text('Belum Lunas (46)'), findsOneWidget);
    expect(find.text('Rp 6.000 / 11.000'), findsOneWidget);
    expect(find.text('sisa Rp 5.000'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('kas-student-01')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kas-student-01')));
    await tester.pumpAndSettle();

    expect(find.text('1 transaksi'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('kas-amount-field')),
      '5000',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('kas-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kas-save-button')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('kas-scroll')),
      const Offset(0, 1400),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lunas (1)'), findsOneWidget);
    expect(find.text('Dicicil (0)'), findsOneWidget);
    expect(find.text('Belum Lunas (46)'), findsOneWidget);
    expect(find.text('1 dari 47 siswa lunas'), findsOneWidget);
    expect(find.text('Rp 11.000 / 11.000'), findsOneWidget);
  });

  testWidgets('archived kas periods are read-only', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp(showSplash: false));
    await tester.tap(find.text('Kas & Urunan Kelas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kas-open-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('November 2026 (Bulan Ini)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oktober 2026 · Kas Bulanan').last);
    await tester.pumpAndSettle();

    expect(find.text('[ ARSIP BULAN LALU ]'), findsOneWidget);
    expect(find.text('Rp 430.000'), findsOneWidget);
    expect(find.text('42 dari 47 siswa lunas'), findsOneWidget);
    expect(find.text('Mode arsip · data hanya bisa dilihat.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kas-student-01')));
    await tester.pumpAndSettle();
    expect(find.text('ARSIP SETORAN'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
    expect(find.text('Simpan Setoran'), findsNothing);
  });

  testWidgets('opens the kas history and filters by month', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp(showSplash: false));
    await tester.tap(find.text('Kas & Urunan Kelas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kas-open-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('kas-history-button')));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Kas'), findsOneWidget);
    expect(find.text('BUKU BESAR KAS'), findsOneWidget);
    expect(find.text('Catatan setoran\nkelas XII RPL'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kas-month-September 2026')));
    await tester.pumpAndSettle();

    expect(find.text('September 2026'), findsWidgets);
    expect(find.text('Semua'), findsOneWidget);
  });

  testWidgets('splash falls back to the dashboard when video is unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Menyiapkan buku kelas…'), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('DATA SISWA'), findsOneWidget);
    expect(find.text('Menyiapkan buku kelas…'), findsNothing);
  });

  testWidgets('opens the today summary dialog from the header alert', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(showSplash: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('today-alert-button')));
    await tester.pumpAndSettle();

    expect(find.text('RINGKASAN HARI INI'), findsOneWidget);
    expect(find.text('PIKET HARI INI'), findsOneWidget);
    expect(find.text('JADWAL MAPEL HARI INI'), findsOneWidget);
    expect(find.text('PR & TUGAS TERDEKAT'), findsOneWidget);
    expect(find.text('HARI INI'), findsOneWidget);
    expect(find.text('H-2'), findsOneWidget);
    expect(find.text('Rangkuman Modul Flutter'), findsOneWidget);
    expect(find.text('Vocabulary Unit 5'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('task-checkbox-task-seed-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-checkbox-task-seed-1')));
    await tester.pumpAndSettle();

    expect(find.text('SELESAI'), findsOneWidget);
    expect(find.text('HARI INI'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('today-dialog-close')));
    await tester.pumpAndSettle();

    expect(find.text('RINGKASAN HARI INI'), findsNothing);
  });

  testWidgets('adds a task from a subject cell on the schedule page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp(showSplash: false));
    await tester.tap(
      find.byKey(const ValueKey('menu-toggle-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadwal Mapel'));
    await tester.pumpAndSettle();

    expect(find.text('Tugas & PR'), findsOneWidget);
    expect(find.text('Latihan Barisan & Deret'), findsOneWidget);
    expect(find.text('H-6'), findsOneWidget);
    expect(find.text('3 belum selesai'), findsOneWidget);

    await tester.ensureVisible(find.text('Matematika').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matematika').first);
    await tester.pumpAndSettle();

    expect(find.text('Tambah Tugas/PR: Matematika'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-countdown-text')), findsOneWidget);
    expect(find.textContaining('Dikumpulkan'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Mencari Peluang',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Mencari Peluang'), findsOneWidget);
    expect(find.text('4 belum selesai'), findsOneWidget);
    expect(find.textContaining('dicatat'), findsOneWidget);
  });
}
