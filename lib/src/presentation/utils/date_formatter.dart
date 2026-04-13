import 'package:intl/intl.dart';

String formatTimestamp(int? ms) {
  if (ms == null) return 'Never';
  final date = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      if (difference.inMinutes == 0) {
        return 'Just now';
      }
      return '${difference.inMinutes}m ago';
    }
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else {
    return DateFormat.yMMMd().format(date);
  }
}

String formatFullDate(int? ms) {
  if (ms == null) return 'N/A';
  final date = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateFormat.yMMMMd().add_jm().format(date);
}
