import 'package:flutter/material.dart';

import '../kas_theme.dart';
import '../models/kas_period.dart';

class KasPeriodSwitcher extends StatelessWidget {
  const KasPeriodSwitcher({
    required this.periods,
    required this.selectedId,
    required this.onChanged,
    super.key,
  });

  final List<KasPeriod> periods;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = periods.firstWhere(
      (period) => period.id == selectedId,
      orElse: () => periods.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'PERIODE KAS',
              style: TextStyle(
                color: KasColors.inkSoft,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: KasColors.line)),
            if (selected.isCustom) ...[
              const SizedBox(width: 8),
              const _KindStamp(),
            ],
            if (!selected.isActive) ...[
              const SizedBox(width: 8),
              _ArchiveStamp(isCustom: selected.isCustom),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: KasColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: KasColors.line),
          ),
          child: Row(
            children: [
              Icon(
                selected.isCustom
                    ? Icons.celebration_outlined
                    : Icons.calendar_today_outlined,
                size: 15,
                color: KasColors.greenInk,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: DropdownButtonHideUnderline(
                  key: const ValueKey('kas-period-dropdown'),
                  child: DropdownButton<String>(
                    value: selected.id,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 19,
                      color: KasColors.inkSoft,
                    ),
                    style: const TextStyle(
                      color: KasColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    dropdownColor: KasColors.card,
                    borderRadius: BorderRadius.circular(10),
                    items: [
                      for (final period in periods)
                        DropdownMenuItem<String>(
                          value: period.id,
                          child: Text(
                            _labelFor(period),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: period.isActive
                                  ? KasColors.ink
                                  : KasColors.inkSoft,
                              fontSize: 12.5,
                              fontWeight: period.isActive
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!selected.isActive) ...[
          const SizedBox(height: 7),
          Text(
            selected.isCustom
                ? 'Kegiatan ini tersimpan sebagai arsip dan tidak bisa diubah.'
                : 'Data bulan ini tersimpan sebagai arsip dan tidak bisa diubah.',
            style: const TextStyle(
              color: KasColors.inkSoft,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String _labelFor(KasPeriod period) {
    if (period.isCustom) {
      return '${period.title} · ${period.monthYear}';
    }
    if (period.isActive) {
      return '${period.monthYear} (Bulan Ini)';
    }
    return '${period.monthYear} · ${period.title}';
  }
}

class _KindStamp extends StatelessWidget {
  const _KindStamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: KasColors.greenWash,
        border: Border.all(color: KasColors.greenInk.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'KEGIATAN',
        style: TextStyle(
          color: KasColors.greenInk,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ArchiveStamp extends StatelessWidget {
  const _ArchiveStamp({required this.isCustom});

  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.02,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: KasColors.amber.withValues(alpha: 0.12),
          border: Border.all(color: KasColors.amber.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          isCustom ? '[ ARSIP KEGIATAN ]' : '[ ARSIP BULAN LALU ]',
          style: const TextStyle(
            color: KasColors.amberInk,
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
