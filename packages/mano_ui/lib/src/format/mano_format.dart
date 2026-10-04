/// Spanish (Colombia) labels for money and time; no `intl` dependency needed yet.
abstract final class ManoFormat {
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  static const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

  /// Whole pesos as "$45.000".
  static String cop(int pesos) {
    final digits = pesos.abs().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
      grouped.write(digits[i]);
    }
    return '${pesos < 0 ? '-' : ''}\$$grouped';
  }

  /// "3:00 p. m."
  static String time(DateTime at) {
    final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${at.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  /// "12 oct"
  static String dayMonth(DateTime at) => '${at.day} ${_months[at.month - 1]}';

  /// "12 oct, 3:00 p. m."
  static String dateTime(DateTime at) => '${dayMonth(at)}, ${time(at)}';

  /// "lun"
  static String weekdayShort(DateTime at) => _weekdays[at.weekday - 1];

  /// Time since [at] as "5m", "3h" or "2d"; never below 1 of the unit.
  static String relative(DateTime at, DateTime now) {
    final elapsed = now.difference(at);
    if (elapsed.inHours < 1) {
      return '${elapsed.inMinutes < 1 ? 1 : elapsed.inMinutes}m';
    }
    if (elapsed.inHours < 24) return '${elapsed.inHours}h';
    return '${elapsed.inDays}d';
  }
}
