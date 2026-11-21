import 'package:flutter/material.dart';

import '../../app_style.dart';
import '../kas_theme.dart';
import '../models/kas_history_log.dart';
import '../state/kas_scope.dart';
import '../utils/kas_calculations.dart';
import '../widgets/history_log_tile.dart';

class KasHistoryScreen extends StatefulWidget {
  const KasHistoryScreen({super.key});

  @override
  State<KasHistoryScreen> createState() => _KasHistoryScreenState();
}

class _KasHistoryScreenState extends State<KasHistoryScreen> {
  String? _monthFilter;

  @override
  Widget build(BuildContext context) {
    final controller = KasScope.of(context);
    final allLogs = controller.historyLogs;
    final filtered = _monthFilter == null
        ? allLogs
        : allLogs
              .where((log) => log.monthYear == _monthFilter)
              .toList(growable: false);
    final total = filtered.fold<double>(0, (sum, log) => sum + log.amount);

    final months = <String>[];
    for (final period in controller.periods) {
      if (!months.contains(period.monthYear)) {
        months.add(period.monthYear);
      }
    }

    return Scaffold(
      backgroundColor: KasColors.paper,
      appBar: AppBar(
        backgroundColor: KasColors.navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(),
        title: const Text(
          'Riwayat Kas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(Icons.menu_book_outlined, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: PaperBackground(
          child: ListView(
            key: const ValueKey('kas-history-list'),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              _HistoryHeader(total: total, count: filtered.length),
              const SizedBox(height: 16),
              const Text(
                'SARING BULAN',
                style: TextStyle(
                  color: KasColors.inkSoft,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MonthChip(
                    label: 'Semua',
                    selected: _monthFilter == null,
                    onTap: () => setState(() => _monthFilter = null),
                  ),
                  for (final month in months)
                    _MonthChip(
                      label: month,
                      selected: _monthFilter == month,
                      onTap: () => setState(() => _monthFilter = month),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                const _EmptyHistory()
              else
                ..._buildGroups(filtered),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroups(List<KasHistoryLog> logs) {
    final widgets = <Widget>[];
    String? lastDay;

    for (var index = 0; index < logs.length; index++) {
      final log = logs[index];
      final day = formatShortDate(log.timestamp);
      if (day != lastDay) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 5, bottom: 8),
            child: Row(
              children: [
                Text(
                  day.toUpperCase(),
                  style: const TextStyle(
                    color: KasColors.inkSoft,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: KasColors.line)),
              ],
            ),
          ),
        );
        lastDay = day;
      }
      widgets.add(HistoryLogTile(log: log));
      widgets.add(const SizedBox(height: 7));
    }

    return widgets;
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'BUKU BESAR KAS',
          style: TextStyle(
            color: KasColors.greenInk,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Catatan setoran\nkelas XII RPL',
          style: TextStyle(
            color: KasColors.ink,
            fontSize: 25,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Semua uang yang masuk dan koreksi pembayaran, '
          'diurutkan dari yang paling baru.',
          style: TextStyle(
            color: KasColors.inkSoft,
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(width: 24, height: 3, color: KasColors.greenInk),
            const SizedBox(width: 7),
            Expanded(child: Container(height: 1, color: KasColors.line)),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: BoxDecoration(
            color: KasColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: KasColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: KasColors.greenWash,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 17,
                  color: KasColors.greenInk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL TERCATAT',
                      style: TextStyle(
                        color: KasColors.inkSoft,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatRupiah(total),
                      style: const TextStyle(
                        color: KasColors.greenInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: KasColors.line),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TRANSAKSI',
                    style: TextStyle(
                      color: KasColors.inkSoft,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: KasColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('kas-month-$label'),
      color: selected ? KasColors.navy : KasColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: selected ? KasColors.navy : KasColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : KasColors.inkSoft,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: KasColors.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: KasColors.line),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 30, color: KasColors.inkSoft),
          SizedBox(height: 9),
          Text(
            'Belum ada transaksi pada bulan ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: KasColors.inkSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
