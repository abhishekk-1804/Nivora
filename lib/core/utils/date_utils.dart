class AppDateUtils {
  /// Strips the time component from a DateTime, returning a new DateTime at midnight in UTC.
  /// Using UTC ensures that Daylight Saving Time (DST) shifts (+/- 1 hour) do not
  /// break calendar day-count math.
  static DateTime stripTime(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Safely calculates the number of calendar days between two dates, ignoring time and DST shifts.
  static int daysBetween(DateTime start, DateTime end) {
    final utcStart = stripTime(start);
    final utcEnd = stripTime(end);
    return utcEnd.difference(utcStart).inDays;
  }

  /// Checks if two dates are on the same day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
