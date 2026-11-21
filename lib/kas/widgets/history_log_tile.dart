import 'package:flutter/material.dart';

import '../kas_theme.dart';
import '../models/kas_history_log.dart';
import '../utils/kas_calculations.dart';

class HistoryLogTile extends StatelessWidget {
  const HistoryLogTile({required this.log, super.key});

  final KasHistoryLog log;

  @override
  Widget build(BuildContext context) {
    final isCorrection = log.amount < 0;
    final accent = isCorrection ? KasColors.red : KasColors.greenInk;
    final wash = isCorrection ? KasColors.redWash : KasColors.greenWash;

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
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
              color: wash,
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(
              isCorrection ? Icons.undo_rounded : Icons.receipt_long_outlined,
              size: 16,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KasColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: log.periodTitle.isEmpty
                            ? '${log.monthYear} · '
                            : '${log.periodTitle} · ${log.monthYear} · ',
                        style: const TextStyle(
                          color: KasColors.greenInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: log.note),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KasColors.inkSoft,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCorrection
                    ? formatRupiah(log.amount)
                    : '+ ${formatRupiah(log.amount)}',
                style: TextStyle(
                  color: accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatLogTimestamp(log.timestamp),
                style: const TextStyle(
                  color: KasColors.inkSoft,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
