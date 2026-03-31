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
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatDate(dt);
}
