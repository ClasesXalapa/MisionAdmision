import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/app/app.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/core/network/remote_text_client.dart';

import 'helpers/memory_json_store.dart';

void main() {
  testWidgets('muestra la pantalla inicial', (tester) async {
    // Reproduce el tipo de viewport ancho que algunos navegadores Android
    // reportan para una PWA, en lugar de depender del tamaño de prueba 800x600.
    tester.view
      ..physicalSize = const Size(720, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jsonKeyValueStoreProvider.overrideWithValue(MemoryJsonStore()),
          remoteTextClientProvider.overrideWithValue(
            const _OfflineRemoteTextClient(),
          ),
        ],
        child: const MissionAdmissionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Misión Admisión'), findsOneWidget);
    expect(find.text('Tu misión de hoy'), findsOneWidget);
    expect(find.byKey(const Key('app_bottom_navigation')), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Reto'), findsOneWidget);
    expect(find.text('Recursos'), findsWidgets);
    expect(find.text('Examen'), findsOneWidget);
    expect(find.text('Datos y respaldo'), findsNothing);
    expect(find.text('Ayuda y diagnóstico'), findsNothing);
    expect(find.text('Aplicación instalada'), findsNothing);
    expect(find.text('Copiar ID de prueba'), findsNothing);

    // Las claves son estables aunque el texto cambie entre comenzar,
    // continuar o repetir según el progreso local del alumno.
    expect(find.byKey(const Key('home_daily_challenge_action')), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('home_exam_action')),
      350,
      scrollable: scrollable,
    );

    final resourcesFinder = find.byKey(const Key('home_resources_action'));
    final examFinder = find.byKey(const Key('home_exam_action'));

    expect(resourcesFinder, findsOneWidget);
    expect(examFinder, findsOneWidget);

    // En Inicio ambas acciones deben ocupar una fila completa y estar
    // apiladas, incluso cuando el navegador móvil reporta 720 px de ancho.
    final resourcesTopLeft = tester.getTopLeft(resourcesFinder);
    final examTopLeft = tester.getTopLeft(examFinder);
    final resourcesSize = tester.getSize(resourcesFinder);
    final examSize = tester.getSize(examFinder);

    expect(examTopLeft.dy, greaterThan(resourcesTopLeft.dy));
    expect((examTopLeft.dx - resourcesTopLeft.dx).abs(), lessThan(1));
    expect(resourcesSize.width, greaterThan(690));
    expect(examSize.width, greaterThan(690));
  });
}

class _OfflineRemoteTextClient implements RemoteTextClient {
  const _OfflineRemoteTextClient();

  @override
  Future<String> get(Uri uri) {
    return Future<String>.error(
      StateError('La red está desactivada durante esta prueba de widgets.'),
    );
  }
}
