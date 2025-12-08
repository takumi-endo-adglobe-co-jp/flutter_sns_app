import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  /// Format DateTime to a human-readable relative time string
  /// Example: "5分前", "3時間前", "2日前", "2024/01/15"
  String toRelativeTimeString() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return '今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return DateFormat('yyyy/MM/dd').format(this);
    }
  }

  /// Format DateTime to "yyyy/MM/dd HH:mm" format
  String toFormattedString() {
    return DateFormat('yyyy/MM/dd HH:mm').format(this);
  }

  /// Format DateTime to "MM月dd日 HH:mm" format
  String toJapaneseFormat() {
    return DateFormat('MM月dd日 HH:mm').format(this);
  }
}
