import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Format integer amount as IDR: "Rp 1.500.000"
String formatIdr(int amount) {
  final formatter = NumberFormat('#,###', 'id_ID');
  return 'Rp ${formatter.format(amount)}';
}

/// Parse a formatted price string (e.g. "1.500.000") back to int.
/// Returns null if the string is empty or not a valid number.
int? parseIdr(String text) {
  final digits = text.replaceAll('.', '').trim();
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// TextInputFormatter that adds thousand separators with '.' as user types.
/// E.g. "1500000" becomes "1.500.000".
class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format with dots
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Format DateTime as "20 Mar 2026, 14:30"
String formatDateTime(DateTime dt) {
  return DateFormat('dd MMM yyyy, HH:mm').format(dt);
}

/// Format DateTime as "20 Mar 2026"
String formatDate(DateTime dt) {
  return DateFormat('dd MMM yyyy').format(dt);
}

/// Format DateTime as relative time ago string.
String formatTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatDate(dt);
}
