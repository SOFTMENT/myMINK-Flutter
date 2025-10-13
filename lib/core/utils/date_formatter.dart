import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date, String format) {
    try {
      final dateFormat = DateFormat(format);
      return dateFormat.format(date);
    } catch (e) {
      return 'Invalid Format'; // Handle invalid formats gracefully
    }
  }
}
