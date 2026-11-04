import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String timeAgo(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        final m = difference.inMinutes;
        return '$m ${m == 1 ? 'min' : 'mins'} ago';
      } else if (difference.inHours < 24) {
        final h = difference.inHours;
        return '$h ${h == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        final d = difference.inDays;
        return '$d ${d == 1 ? 'day' : 'days'} ago';
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (_) {
      return '';
    }
  }

  static String formatFullDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(dateTime);
    } catch (_) {
      return '';
    }
  }

  static String formatShortDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (_) {
      return '';
    }
  }
}

