import 'package:intl/intl.dart';

class FormatUtils {
  /// Formats numbers to human readable strings (e.g., 1.5K, 2.3M)
  static String formatNumber(int? n) {
    if (n == null) return '0';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  /// Returns a relative time string (e.g., 2h, 3d, 1mo, 1y)
  static String relativeTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  /// Standard date format: DDR MMM YYYY
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }
  
  /// Formats timestamp in ms to date
  static String formatTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    return formatDate(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }
}
