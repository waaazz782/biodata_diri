import 'package:flutter/material.dart';

import '../../app_style.dart';
import '../../services/local_storage_service.dart';
import '../kas_theme.dart';
import '../models/kas_period.dart';
import '../models/student_payment_status.dart';
import '../state/kas_scope.dart';
import '../utils/kas_calculations.dart';
import '../widgets/create_activity_sheet.dart';
import '../widgets/edit_kas_period_sheet.dart';
import '../widgets/kas_filter_bar.dart';
import '../widgets/kas_period_switcher.dart';
import '../widgets/kas_summary_card.dart';
import '../widgets/payment_sheet.dart';
import '../widgets/student_payment_tile.dart';
import 'kas_history_screen.dart';

class KasScreen extends StatefulWidget {
  const KasScreen({super.key});

  @override
  State<KasScreen> createState() => _KasScreenState();
}

class _KasScreenState extends State<KasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocalStorageService _storage = LocalStorageService();
  String? _selectedPeriodId;
  KasFilter _filter = KasFilter.all;
  String _query = '';
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    _loadBalanceHidden();
  }

  Future<void> _loadBalanceHidden() async {
    final hidden = await _storage.loadKasBalanceHidden();
    if (!mounted) return;
    setState(() => _balanceHidden = hidden);
  }

  Future<void> _toggleBalance() async {
    final next = !_balanceHidden;
    setState(() => _balanceHidden = next);
    await _storage.saveKasBalanceHidden(next);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = KasScope.of(context);
    final periods = controller.periods;
    final selectedId = _selectedPeriodId ?? controller.activePeriod.id;
    final period = periods.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => controller.activePeriod,
    );
    final payments = controller.paymentsFor(period.id);

    final total = payments.length;
    final paid = countPaidStudents(payments);
    final installment = countInstallmentStudents(payments);
    final unpaid = countUnpaidStudents(payments);

    final query = _query.trim().toLowerCase();
    final searched = query.isEmpty
        ? payments
        : payments
              .where((payment) {
                final number = payment.noAbsen.toString().padLeft(2, '0');
                return payment.studentName.toLowerCase().contains(query) ||
                    number.contains(query) ||
                    payment.noAbsen.toString() == query;
              })
              .toList(growable: false);

    final visible = switch (_filter) {
      KasFilter.all => searched,
      KasFilter.paid =>
        searched.where((payment) => payment.isPaidOff).toList(growable: false),
      KasFilter.installment =>
        searched
            .where((payment) => payment.hasInstallment)
            .toList(growable: false),
      KasFilter.unpaid =>
        searched
            .where((payment) => payment.amountPaid <= 0)
            .toList(growable: false),
    };

    return Scaffold(
      backgroundColor: KasColors.paper,
      appBar: AppBar(
        backgroundColor: KasColors.navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: KasColors.navyLine, width: 1),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kas & Urunan XII RPL',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Buku kas kelas · $total siswa',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: KasColors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('kas-history-button'),
            tooltip: 'Riwayat transaksi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const KasHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined, size: 21),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('kas-create-activity-button'),
        onPressed: _createActivity,
        backgroundColor: KasColors.navy,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add_rounded, size: 20, color: KasColors.green),
        label: const Text(
          'Buat Urunan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: PaperBackground(
          child: CustomScrollView(
            key: const ValueKey('kas-scroll'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KasPeriodSwitcher(
                        periods: periods,
                        selectedId: period.id,
                        onChanged: (id) {
                          setState(() {
                            _selectedPeriodId = id;
                            _filter = KasFilter.all;
                            _searchController.clear();
                            _query = '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      KasSummaryCard(
                        key: const ValueKey('kas-summary-card'),
                        period: period,
                        payments: payments,
                        totalStudents: total,
                        balanceHidden: _balanceHidden,
                        onToggleBalance: _toggleBalance,
                        onTap: () => showEditKasPeriodSheet(context, period),
                      ),
                      const SizedBox(height: 15),
                      KasFilterBar(
                        selected: _filter,
                        total: total,
                        paid: paid,
                        installment: installment,
                        unpaid: unpaid,
                        searchController: _searchController,
                        onFilterChanged: (filter) {
                          setState(() => _filter = filter);
                        },
                        onSearchChanged: (value) {
                          setState(() => _query = value);
                        },
                      ),
                      const SizedBox(height: 17),
                      _ListHeader(
                        visibleCount: visible.length,
                        totalCount: total,
                        isArchived: !period.isActive,
                      ),
                    ],
                  ),
                ),
              ),
              if (visible.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 96),
                  sliver: SliverToBoxAdapter(child: _EmptyStudents()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 9, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final payment = visible[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: StudentPaymentTile(
                          payment: payment,
                          targetPerStudent: period.targetPerStudent,
                          onTap: () => _openPayment(period, payment),
                        ),
                      );
                    }, childCount: visible.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPayment(KasPeriod period, StudentPaymentStatus payment) {
    showKasPaymentSheet(context, period: period, payment: payment);
  }

  Future<void> _createActivity() async {
    final period = await showKasCreateActivitySheet(context);
    if (!mounted || period == null) {
      return;
    }

    setState(() {
      _selectedPeriodId = period.id;
      _filter = KasFilter.all;
      _searchController.clear();
      _query = '';
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: KasColors.navy,
          content: Text(
            'Kegiatan "${period.title}" dibuat untuk 47 siswa.',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.visibleCount,
    required this.totalCount,
    required this.isArchived,
  });

  final int visibleCount;
  final int totalCount;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 15,
              color: isArchived ? KasColors.amber : KasColors.greenInk,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Daftar setoran',
                style: const TextStyle(
                  color: KasColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Text(
              '$visibleCount dari $totalCount',
              style: const TextStyle(
                color: KasColors.inkSoft,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 11),
          child: Text(
            isArchived
                ? 'Mode arsip · data hanya bisa dilihat.'
                : 'Ketuk nama untuk mencatat setoran atau cicilan.',
            style: TextStyle(
              color: KasColors.inkSoft.withValues(alpha: 0.9),
              fontSize: 9.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyStudents extends StatelessWidget {
  const _EmptyStudents();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: KasColors.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: KasColors.line),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 30, color: KasColors.inkSoft),
          SizedBox(height: 9),
          Text(
            'Tidak ada siswa yang cocok.\nCoba nama atau nomor absen lain.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: KasColors.inkSoft,
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
