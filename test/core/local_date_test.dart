import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/core/time/local_date.dart';

void main() {
  test('genera una clave local YYYY-MM-DD', () {
    expect(localDateKey(DateTime(2026, 7, 5, 23, 50)), '2026-07-05');
  });

  test('calcula diferencia de días sin depender de la hora', () {
    expect(localDayDifference('2026-07-14', '2026-07-15'), 1);
    expect(localDayDifference('2026-07-14', '2026-07-17'), 3);
  });

  test('rechaza fechas inexistentes', () {
    expect(() => parseLocalDateKey('2026-02-30'), throwsFormatException);
  });
}
