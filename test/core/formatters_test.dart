import 'package:flutter_test/flutter_test.dart';
import 'package:taman_sari_pos/core/formatters.dart';

void main() {
  group('formatIdr', () {
    test('formats zero', () {
      expect(formatIdr(0), 'Rp 0');
    });

    test('formats small amount', () {
      expect(formatIdr(500), 'Rp 500');
    });

    test('formats thousands with dot separator', () {
      expect(formatIdr(1500), 'Rp 1.500');
    });

    test('formats millions', () {
      expect(formatIdr(1500000), 'Rp 1.500.000');
    });

    test('formats large amount', () {
      expect(formatIdr(25000000), 'Rp 25.000.000');
    });

    test('formats negative amount', () {
      // Negative prices shouldn't happen, but ensure no crash
      final result = formatIdr(-500);
      expect(result, contains('500'));
    });
  });

  group('formatDateTime', () {
    test('formats correctly', () {
      final dt = DateTime(2026, 3, 20, 14, 30);
      expect(formatDateTime(dt), '20 Mar 2026, 14:30');
    });

    test('pads single-digit day', () {
      final dt = DateTime(2026, 1, 5, 9, 5);
      expect(formatDateTime(dt), '05 Jan 2026, 09:05');
    });
  });

  group('formatDate', () {
    test('formats date only', () {
      final dt = DateTime(2026, 12, 25, 10, 0);
      expect(formatDate(dt), '25 Dec 2026');
    });
  });

  group('formatTimeAgo', () {
    test('returns "just now" for recent time', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(formatTimeAgo(dt), 'just now');
    });

    test('returns minutes ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 5));
      expect(formatTimeAgo(dt), '5m ago');
    });

    test('returns hours ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatTimeAgo(dt), '3h ago');
    });

    test('returns days ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 2));
      expect(formatTimeAgo(dt), '2d ago');
    });

    test('returns formatted date for old times', () {
      final dt = DateTime.now().subtract(const Duration(days: 10));
      // Should fall back to formatDate
      expect(formatTimeAgo(dt), formatDate(dt));
    });
  });
}
