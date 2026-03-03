import 'package:intl/intl.dart';

class DateFormatter {
  static String format(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
