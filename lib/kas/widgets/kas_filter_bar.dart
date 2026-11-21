import 'package:flutter/material.dart';

import '../kas_theme.dart';

enum KasFilter { all, paid, installment, unpaid }

class KasFilterBar extends StatelessWidget {
  const KasFilterBar({
    required this.selected,
    required this.total,
    required this.paid,
    required this.installment,
    required this.unpaid,
    required this.searchController,
    required this.onFilterChanged,
    required this.onSearchChanged,
    super.key,
  });

  final KasFilter selected;
  final int total;
  final int paid;
  final int installment;
  final int unpaid;
  final TextEditingController searchController;
  final ValueChanged<KasFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: KasColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: KasColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: _FilterTab(
                  label: 'Semua ($total)',
                  selected: selected == KasFilter.all,
                  onTap: () => onFilterChanged(KasFilter.all),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _FilterTab(
                  label: 'Lunas ($paid)',
                  selected: selected == KasFilter.paid,
                  onTap: () => onFilterChanged(KasFilter.paid),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _FilterTab(
                  label: 'Dicicil ($installment)',
                  selected: selected == KasFilter.installment,
                  onTap: () => onFilterChanged(KasFilter.installment),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _FilterTab(
                  label: 'Belum Lunas ($unpaid)',
                  selected: selected == KasFilter.unpaid,
                  onTap: () => onFilterChanged(KasFilter.unpaid),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          key: const ValueKey('kas-search-field'),
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            color: KasColors.ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: KasColors.card,
            hintText: 'Cari nama atau nomor absen…',
            hintStyle: const TextStyle(
              color: KasColors.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 19,
              color: KasColors.inkSoft,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: KasColors.inkSoft,
                    ),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: KasColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: KasColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: KasColors.greenInk,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
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
      color: selected ? KasColors.navy : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.white : KasColors.inkSoft,
                fontSize: 9.4,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
