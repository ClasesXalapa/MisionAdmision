import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/app.dart';
import 'package:mision_admision/app/dependencies.dart';

import 'helpers/memory_json_store.dart';

void main() {
  testWidgets('muestra la pantalla inicial', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jsonKeyValueStoreProvider.overrideWithValue(MemoryJsonStore()),
        ],
        child: const MissionAdmissionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Misión Admisión'), findsOneWidget);
    expect(find.text('Iniciar examen'), findsOneWidget);
    expect(find.text('Hacer reto de hoy'), findsOneWidget);
  });
}
