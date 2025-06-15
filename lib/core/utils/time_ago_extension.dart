extension TimeAgoExtension on DateTime {
  String timeAgoSinceDate() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays >= 365) {
      final years = difference.inDays ~/ 365;
      return years == 1 ? "$years year ago" : "$years years ago";
    }
    if (difference.inDays >= 30) {
      final months = difference.inDays ~/ 30;
      return months == 1 ? "$months month ago" : "$months months ago";
    }
    if (difference.inDays >= 1) {
      final days = difference.inDays;
      return days == 1 ? "$days day ago" : "$days days ago";
    }
    if (difference.inHours >= 1) {
      final hours = difference.inHours;
      return hours == 1 ? "$hours hour ago" : "$hours hours ago";
    }
    if (difference.inMinutes >= 1) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? "$minutes minute ago" : "$minutes minutes ago";
    }
    return "a moment ago";
  }
}
