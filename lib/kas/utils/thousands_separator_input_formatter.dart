import 'package:flutter/services.dart';

/// Memformat input nominal uang dengan pemisah ribuan titik.
///
/// Contoh: mengetik `1000000` akan tampil menjadi `1.000.000`.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter({this.maxDigits = 15});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final digits = rawDigits.length > maxDigits
        ? rawDigits.substring(0, maxDigits)
        : rawDigits;
    final text = _groupDigits(digits);

    final selection = newValue.selection;
    int cursorDigits;
    if (selection.isValid) {
      final end = selection.extentOffset.clamp(0, newValue.text.length);
      cursorDigits = 0;
      for (var index = 0; index < end; index++) {
        if (_isDigit(newValue.text.codeUnitAt(index))) {
          cursorDigits++;
        }
      }
    } else {
      cursorDigits = digits.length;
    }
    if (cursorDigits > digits.length) {
      cursorDigits = digits.length;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _offsetAfterDigits(text, cursorDigits),
      ),
    );
  }

  String _groupDigits(String digits) {
    if (digits.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  int _offsetAfterDigits(String text, int digitCount) {
    if (digitCount <= 0) {
      return 0;
    }
    var seen = 0;
    for (var index = 0; index < text.length; index++) {
      if (_isDigit(text.codeUnitAt(index))) {
        seen++;
        if (seen == digitCount) {
          return index + 1;
        }
      }
    }
    return text.length;
  }

  bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}

/// Mengubah teks nominal berformat (`1.000.000`) menjadi angka `1000000`.
double parseRupiahInput(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return 0;
  }
  return double.tryParse(digits) ?? 0;
}
