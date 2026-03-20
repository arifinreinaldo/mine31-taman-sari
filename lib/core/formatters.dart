import 'package:intl/intl.dart';

/// Format integer amount as IDR: "Rp 1.500.000"
String formatIdr(int amount) {
  final formatter = NumberFormat('#,###', 'id_ID');
  return 'Rp ${formatter.format(amount)}';
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
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(dt);
}
