import 'package:flutter/material.dart';

import '../kas_theme.dart';
import '../models/kas_history_log.dart';
import '../models/kas_period.dart';
import '../models/student_payment_status.dart';
import '../state/kas_scope.dart';
import '../utils/kas_calculations.dart';
import '../utils/thousands_separator_input_formatter.dart';

enum _PaymentMode { deposit, correction }

Future<void> showKasPaymentSheet(
  BuildContext context, {
  required KasPeriod period,
  required StudentPaymentStatus payment,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        KasPaymentSheet(period: period, payment: payment),
  );
}

class KasPaymentSheet extends StatefulWidget {
  const KasPaymentSheet({
    required this.period,
    required this.payment,
    super.key,
  });

  final KasPeriod period;
  final StudentPaymentStatus payment;

  @override
  State<KasPaymentSheet> createState() => _KasPaymentSheetState();
}

class _KasPaymentSheetState extends State<KasPaymentSheet> {
  late final TextEditingController _depositController;
  late final TextEditingController _correctionController;
  late bool _isPaidOff;
  late DateTime? _paymentDate;
  _PaymentMode _mode = _PaymentMode.deposit;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _isPaidOff =
        payment.isPaidOff ||
        payment.amountPaid + 0.001 >= widget.period.targetPerStudent;
    _depositController = TextEditingController();
    _correctionController = TextEditingController(
      text: payment.amountPaid <= 0
          ? ''
          : formatRupiah(payment.amountPaid).replaceFirst('Rp ', ''),
    );
    _paymentDate = payment.paymentDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _depositController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  double get _depositAmount => parseRupiahInput(_depositController.text);

  double get _correctionAmount => parseRupiahInput(_correctionController.text);

  void _setDeposit(double value) {
    if (value <= 0) {
      _depositController.clear();
    } else {
      _depositController.text = formatRupiah(value).replaceFirst('Rp ', '');
    }
    setState(() {});
  }

  void _togglePaid(bool value) {
    setState(() {
      _isPaidOff = value;
      if (value) {
        _correctionController.text = formatRupiah(
          widget.period.targetPerStudent,
        ).replaceFirst('Rp ', '');
        _paymentDate ??= DateTime.now();
      } else {
        if (_correctionAmount >= widget.period.targetPerStudent) {
          _correctionController.clear();
        }
        _paymentDate = null;
      }
    });
  }

  void _onCorrectionChanged(String value) {
    final amount = parseRupiahInput(value);
    setState(() {
      _isPaidOff = amount + 0.001 >= widget.period.targetPerStudent;
      if (amount <= 0) {
        _paymentDate = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Tanggal pembayaran',
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  void _saveDeposit() {
    final controller = KasScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final amount = _depositAmount;
    controller.addPayment(
      periodId: widget.period.id,
      noAbsen: widget.payment.noAbsen,
      amount: amount,
      paymentDate: _paymentDate,
    );
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: KasColors.navy,
          content: Text(
            'Setoran ${widget.payment.studentName} '
            '${formatRupiah(amount)} dicatat.',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
  }

  void _saveCorrection() {
    final controller = KasScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final amount = _correctionAmount;
    controller.savePayment(
      periodId: widget.period.id,
      noAbsen: widget.payment.noAbsen,
      amountPaid: amount,
      paymentDate: _paymentDate,
      note: _isPaidOff ? 'Lunas transfer / Tunai' : 'Cicilan tunai',
    );
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: KasColors.navy,
          content: Text(
            'Total setoran ${widget.payment.studentName} diperbarui.',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final controller = KasScope.of(context);
    final livePayment = controller
        .paymentsFor(widget.period.id)
        .firstWhere(
          (item) => item.noAbsen == widget.payment.noAbsen,
          orElse: () => widget.payment,
        );
    final logs = controller.logsForStudent(
      periodId: widget.period.id,
      noAbsen: livePayment.noAbsen,
    );
    final state = livePayment.stateFor(widget.period.targetPerStudent);
    final isArchived = !widget.period.isActive;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: KasColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: KasColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 17),
            _SheetHeader(
              payment: livePayment,
              period: widget.period,
              isArchived: isArchived,
            ),
            const SizedBox(height: 15),
            const KasDottedRule(),
            const SizedBox(height: 13),
            _BalancePanel(
              payment: livePayment,
              target: widget.period.targetPerStudent,
              state: state,
            ),
            const SizedBox(height: 13),
            _HistorySection(logs: logs),
            const SizedBox(height: 14),
            if (isArchived)
              _ArchivedBody(
                payment: livePayment,
                state: state,
                onClose: () => Navigator.of(context).pop(),
              )
            else ...[
              _ModeToggle(
                mode: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              const SizedBox(height: 13),
              if (_mode == _PaymentMode.deposit)
                _DepositBody(
                  payment: livePayment,
                  target: widget.period.targetPerStudent,
                  controller: _depositController,
                  amount: _depositAmount,
                  paymentDate: _paymentDate,
                  onAmountChanged: (_) => setState(() {}),
                  onQuickAmount: _setDeposit,
                  onPickDate: _pickDate,
                  onSave: _saveDeposit,
                )
              else
                _CorrectionBody(
                  isPaidOff: _isPaidOff,
                  controller: _correctionController,
                  amount: _correctionAmount,
                  target: widget.period.targetPerStudent,
                  paymentDate: _paymentDate,
                  onTogglePaid: _togglePaid,
                  onAmountChanged: _onCorrectionChanged,
                  onPickDate: _pickDate,
                  onSave: _saveCorrection,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.payment,
    required this.period,
    required this.isArchived,
  });

  final StudentPaymentStatus payment;
  final KasPeriod period;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: KasColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: KasColors.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              payment.photoPath,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: KasColors.paper,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_outline,
                  color: KasColors.inkSoft,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArchived ? 'ARSIP SETORAN' : 'KUITANSI SETORAN',
                style: TextStyle(
                  color: isArchived ? KasColors.amberInk : KasColors.greenInk,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                payment.studentName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KasColors.ink,
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No. ${payment.noAbsen.toString().padLeft(2, '0')} · '
                '${period.title} ${period.monthYear}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KasColors.inkSoft,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({
    required this.payment,
    required this.target,
    required this.state,
  });

  final StudentPaymentStatus payment;
  final double target;
  final StudentPaymentState state;

  @override
  Widget build(BuildContext context) {
    final remaining = (target - payment.amountPaid).clamp(0.0, double.infinity);
    final progress = target <= 0
        ? 0.0
        : (payment.amountPaid / target).clamp(0.0, 1.0);
    final accent = switch (state) {
      StudentPaymentState.paidOff => KasColors.greenInk,
      StudentPaymentState.installment => KasColors.amberInk,
      StudentPaymentState.unpaid => KasColors.red,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: KasColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KasColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUDAH DIBAYAR',
                      style: TextStyle(
                        color: KasColors.inkSoft,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatRupiah(payment.amountPaid),
                        style: TextStyle(
                          color: accent,
                          fontSize: 21,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 11),
                color: KasColors.line,
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TARGET',
                      style: TextStyle(
                        color: KasColors.inkSoft,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatRupiah(target),
                        style: const TextStyle(
                          color: KasColors.ink,
                          fontSize: 13,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: KasColors.paper,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              KasStatusStamp(state: state, compact: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  switch (state) {
                    StudentPaymentState.paidOff => 'Setoran sudah lunas.',
                    StudentPaymentState.installment =>
                      'Kurang ${formatRupiah(remaining)} lagi.',
                    StudentPaymentState.unpaid => 'Belum ada setoran masuk.',
                  },
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.logs});

  final List<KasHistoryLog> logs;

  @override
  Widget build(BuildContext context) {
    final visible = logs.take(4).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'RIWAYAT SETORAN',
              style: TextStyle(
                color: KasColors.inkSoft,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(child: Container(height: 1, color: KasColors.line)),
            const SizedBox(width: 7),
            Text(
              '${logs.length} transaksi',
              style: const TextStyle(
                color: KasColors.inkSoft,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        if (visible.isEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            decoration: BoxDecoration(
              color: KasColors.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: KasColors.line),
            ),
            child: const Text(
              'Belum ada riwayat setoran untuk siswa ini.',
              style: TextStyle(
                color: KasColors.inkSoft,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(11, 4, 11, 4),
            decoration: BoxDecoration(
              color: KasColors.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: KasColors.line),
            ),
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  _HistoryRow(log: visible[index]),
                  if (index < visible.length - 1)
                    const KasDottedRule(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.log});

  final KasHistoryLog log;

  @override
  Widget build(BuildContext context) {
    final isCorrection = log.amount < 0;
    final accent = isCorrection ? KasColors.red : KasColors.greenInk;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            isCorrection ? Icons.undo_rounded : Icons.south_west_rounded,
            size: 13,
            color: accent,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KasColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatShortDate(log.timestamp),
                  style: const TextStyle(
                    color: KasColors.inkSoft,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            isCorrection
                ? formatRupiah(log.amount)
                : '+ ${formatRupiah(log.amount)}',
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _PaymentMode mode;
  final ValueChanged<_PaymentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: KasColors.card,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: KasColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              key: const ValueKey('kas-mode-deposit'),
              label: 'Tambah Setoran',
              selected: mode == _PaymentMode.deposit,
              onTap: () => onChanged(_PaymentMode.deposit),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _ModeTab(
              key: const ValueKey('kas-mode-correction'),
              label: 'Koreksi Total',
              selected: mode == _PaymentMode.correction,
              onTap: () => onChanged(_PaymentMode.correction),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? KasColors.navy : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.white : KasColors.inkSoft,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DepositBody extends StatelessWidget {
  const _DepositBody({
    required this.payment,
    required this.target,
    required this.controller,
    required this.amount,
    required this.paymentDate,
    required this.onAmountChanged,
    required this.onQuickAmount,
    required this.onPickDate,
    required this.onSave,
  });

  final StudentPaymentStatus payment;
  final double target;
  final TextEditingController controller;
  final double amount;
  final DateTime? paymentDate;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<double> onQuickAmount;
  final VoidCallback onPickDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final newTotal = payment.amountPaid + amount;
    final remaining = (target - newTotal).clamp(0.0, double.infinity);
    final missingBefore = (target - payment.amountPaid).clamp(
      0.0,
      double.infinity,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'NOMINAL SETORAN BARU',
          style: TextStyle(
            color: KasColors.inkSoft,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('kas-amount-field'),
          controller: controller,
          onChanged: onAmountChanged,
          keyboardType: TextInputType.number,
          inputFormatters: const [ThousandsSeparatorInputFormatter()],
          style: const TextStyle(
            color: KasColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: KasColors.card,
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(
              color: KasColors.inkSoft,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            hintText: '0',
            hintStyle: const TextStyle(
              color: KasColors.inkSoft,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: KasColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: KasColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: KasColors.greenInk,
                width: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _QuickAmount(label: 'Rp 5.000', onTap: () => onQuickAmount(5000)),
            _QuickAmount(label: 'Rp 10.000', onTap: () => onQuickAmount(10000)),
            if (missingBefore > 0)
              _QuickAmount(
                label: 'Lunasi sisa',
                accent: true,
                onTap: () => onQuickAmount(missingBefore),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
          decoration: BoxDecoration(
            color: amount > 0 ? KasColors.greenWash : KasColors.card,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: amount > 0
                  ? KasColors.greenInk.withValues(alpha: 0.35)
                  : KasColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total setelah setoran',
                      style: TextStyle(
                        color: KasColors.inkSoft,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formatRupiah(newTotal),
                    style: TextStyle(
                      color: amount > 0
                          ? KasColors.greenInk
                          : KasColors.inkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                amount <= 0
                    ? 'Masukkan nominal setoran untuk melihat total baru.'
                    : remaining <= 0
                    ? 'Setoran ini melunasi target siswa.'
                    : 'Masih kurang ${formatRupiah(remaining)} setelah setoran ini.',
                style: TextStyle(
                  color: amount <= 0
                      ? KasColors.inkSoft
                      : (remaining <= 0
                            ? KasColors.greenInk
                            : KasColors.amberInk),
                  fontSize: 9,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _DatePickerRow(
          paymentDate: paymentDate,
          label: 'TANGGAL SETORAN',
          onPickDate: onPickDate,
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 46,
          child: FilledButton(
            key: const ValueKey('kas-save-button'),
            onPressed: amount > 0 ? onSave : null,
            style: FilledButton.styleFrom(
              backgroundColor: KasColors.navy,
              foregroundColor: Colors.white,
              disabledBackgroundColor: KasColors.line,
              disabledForegroundColor: KasColors.inkSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 18),
                SizedBox(width: 7),
                Text(
                  'Tambah Setoran',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAmount extends StatelessWidget {
  const _QuickAmount({
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? KasColors.greenWash : KasColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: accent
              ? KasColors.greenInk.withValues(alpha: 0.4)
              : KasColors.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: accent ? KasColors.greenInk : KasColors.inkSoft,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _CorrectionBody extends StatelessWidget {
  const _CorrectionBody({
    required this.isPaidOff,
    required this.controller,
    required this.amount,
    required this.target,
    required this.paymentDate,
    required this.onTogglePaid,
    required this.onAmountChanged,
    required this.onPickDate,
    required this.onSave,
  });

  final bool isPaidOff;
  final TextEditingController controller;
  final double amount;
  final double target;
  final DateTime? paymentDate;
  final ValueChanged<bool> onTogglePaid;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onPickDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final remaining = target - amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          decoration: BoxDecoration(
            color: KasColors.card,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: KasColors.line),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Tandai sudah lunas',
                  style: TextStyle(
                    color: KasColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch.adaptive(
                key: const ValueKey('kas-paid-switch'),
                value: isPaidOff,
                onChanged: onTogglePaid,
                activeTrackColor: KasColors.greenInk,
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        const Text(
          'TOTAL SETORAN (KOREKSI)',
          style: TextStyle(
            color: KasColors.inkSoft,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('kas-correction-field'),
          controller: controller,
          onChanged: onAmountChanged,
          keyboardType: TextInputType.number,
          inputFormatters: const [ThousandsSeparatorInputFormatter()],
          style: const TextStyle(
            color: KasColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: KasColors.card,
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(
              color: KasColors.inkSoft,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            hintText: '0',
            hintStyle: const TextStyle(
              color: KasColors.inkSoft,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: KasColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: KasColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: KasColors.greenInk,
                width: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          amount <= 0
              ? 'Belum ada nominal yang dicatat.'
              : (remaining > 0
                    ? 'Kurang ${formatRupiah(remaining)} dari target.'
                    : 'Sudah mencapai target kegiatan ini.'),
          style: TextStyle(
            color: amount <= 0
                ? KasColors.inkSoft
                : (remaining > 0 ? KasColors.red : KasColors.greenInk),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mode koreksi mengganti total setoran, bukan menambah.',
          style: TextStyle(
            color: KasColors.amberInk,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 11),
        _DatePickerRow(
          paymentDate: paymentDate,
          label: 'TANGGAL BAYAR',
          onPickDate: onPickDate,
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 46,
          child: FilledButton(
            key: const ValueKey('kas-save-button'),
            onPressed: onSave,
            style: FilledButton.styleFrom(
              backgroundColor: KasColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 18),
                SizedBox(width: 7),
                Text(
                  'Simpan Koreksi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.paymentDate,
    required this.label,
    required this.onPickDate,
  });

  final DateTime? paymentDate;
  final String label;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KasColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: const BorderSide(color: KasColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPickDate,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 11, 11),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 17,
                color: KasColors.greenInk,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: KasColors.inkSoft,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      paymentDate == null
                          ? 'Belum dicatat'
                          : formatFullDate(paymentDate!),
                      style: TextStyle(
                        color: paymentDate == null
                            ? KasColors.inkSoft
                            : KasColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Ubah',
                style: TextStyle(
                  color: KasColors.greenInk,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: KasColors.greenInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivedBody extends StatelessWidget {
  const _ArchivedBody({
    required this.payment,
    required this.state,
    required this.onClose,
  });

  final StudentPaymentStatus payment;
  final StudentPaymentState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: BoxDecoration(
            color: KasColors.card,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: KasColors.line),
          ),
          child: Column(
            children: [
              _ArchiveRow(
                label: 'Nominal disetor',
                value: formatRupiah(payment.amountPaid),
              ),
              const SizedBox(height: 9),
              const KasDottedRule(height: 1),
              const SizedBox(height: 9),
              _ArchiveRow(
                label: 'Tanggal bayar',
                value: payment.paymentDate == null
                    ? 'Tidak tercatat'
                    : formatFullDate(payment.paymentDate!),
              ),
              const SizedBox(height: 9),
              const KasDottedRule(height: 1),
              const SizedBox(height: 9),
              _ArchiveRow(
                label: 'Status',
                value: switch (state) {
                  StudentPaymentState.paidOff => 'Lunas',
                  StudentPaymentState.installment => 'Dicicil',
                  StudentPaymentState.unpaid => 'Belum lunas',
                },
                valueColor: switch (state) {
                  StudentPaymentState.paidOff => KasColors.greenInk,
                  StudentPaymentState.installment => KasColors.amberInk,
                  StudentPaymentState.unpaid => KasColors.red,
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: KasColors.inkSoft,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Periode ini sudah diarsipkan. Data hanya bisa dilihat, '
                'tidak bisa diubah lagi.',
                style: TextStyle(
                  color: KasColors.inkSoft.withValues(alpha: 0.9),
                  fontSize: 10,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: KasColors.ink,
              side: const BorderSide(color: KasColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({
    required this.label,
    required this.value,
    this.valueColor = KasColors.ink,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: KasColors.inkSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
