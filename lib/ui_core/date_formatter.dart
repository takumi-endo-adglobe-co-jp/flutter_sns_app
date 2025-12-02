import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Format DateTime to "yyyy/MM/dd HH:mm" format
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  /// Format DateTime to "yyyy/MM/dd" format
  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }

  /// Format DateTime to "HH:mm" format
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format DateTime to relative time string
  /// Example: "5分前", "3時間前", "2日前", "2024/01/15"
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return formatDate(dateTime);
    }
  }
}
