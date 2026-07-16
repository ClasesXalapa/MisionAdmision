DateTime localDateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String localDateKey(DateTime value) {
  final date = localDateOnly(value);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime parseLocalDateKey(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw FormatException('Fecha local inválida: $value.');
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);

  if (date.year != year || date.month != month || date.day != day) {
    throw FormatException('Fecha local inexistente: $value.');
  }
  return date;
}

int localDayDifference(String fromDateKey, String toDateKey) {
  final from = parseLocalDateKey(fromDateKey);
  final to = parseLocalDateKey(toDateKey);
  return to.difference(from).inDays;
}

String addLocalDays(String dateKey, int days) {
  return localDateKey(parseLocalDateKey(dateKey).add(Duration(days: days)));
}
