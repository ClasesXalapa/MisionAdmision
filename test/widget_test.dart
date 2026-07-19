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

    expect(find.text('Racha actual'), findsOneWidget);
    expect(find.text('Mejor racha'), findsOneWidget);
    expect(find.text('Escudos'), findsOneWidget);
    expect(find.text('Retos'), findsOneWidget);
    expect(find.text('Explorar recursos'), findsNothing);
    expect(find.text('Iniciar examen'), findsNothing);

    final scrollable = find.byType(Scrollable).first;
    final scrollPosition = tester.state<ScrollableState>(scrollable).position;
    expect(scrollPosition.maxScrollExtent, greaterThan(0));

    // La pantalla está diseñada para desplazarse: el reto y las acciones
    // inferiores pueden estar fuera del primer viewport sin dejar de existir.
    await tester.scrollUntilVisible(
      find.byKey(const Key('home_daily_challenge_action')),
      500,
      scrollable: scrollable,
    );
    expect(find.byKey(const Key('home_daily_challenge_action')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('home_exam_action')),
      500,
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
    final scaffoldWidth = tester.getSize(find.byType(Scaffold).first).width;
    expect(resourcesSize.width, greaterThan(scaffoldWidth - 36));
    expect(examSize.width, greaterThan(scaffoldWidth - 36));
    expect(resourcesSize.height, greaterThanOrEqualTo(500));
    expect(examSize.height, greaterThanOrEqualTo(500));

    // El escalado móvil no debe producir desbordamientos ni otras excepciones
    // de renderizado en la barra inferior o en las cards de Inicio.
    expect(tester.takeException(), isNull);
  });

  testWidgets('recursos usa la composición móvil grande', (tester) async {
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

    await tester.tap(find.text('Recursos').last);
    await tester.pumpAndSettle();

    expect(find.text('Biblioteca de estudio'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Biblioteca de estudio'));
    expect(title.style?.fontSize, greaterThanOrEqualTo(80));

    final resourcesList = find.byKey(const Key('resources_list'));
    expect(resourcesList, findsOneWidget);
    final resourcesScrollable = find.descendant(
      of: resourcesList,
      matching: find.byType(Scrollable),
    ).first;

    await tester.scrollUntilVisible(
      find.byKey(const Key('resource_type_filter_all')),
      500,
      scrollable: resourcesScrollable,
    );
    final allFilter = find.byKey(const Key('resource_type_filter_all'));
    final filterSize = tester.getSize(allFilter);
    final scaffoldWidth = tester.getSize(find.byType(Scaffold).first).width;
    expect(filterSize.width, greaterThan(scaffoldWidth - 140));
    expect(filterSize.height, greaterThanOrEqualTo(150));

    await tester.scrollUntilVisible(
      find.byKey(const Key('resource_card_card_video_algebra_001')),
      700,
      scrollable: resourcesScrollable,
    );
    final firstCard = find.byKey(
      const Key('resource_card_card_video_algebra_001'),
    );
    expect(firstCard, findsOneWidget);
    expect(tester.getSize(firstCard).height, greaterThanOrEqualTo(920));
    expect(tester.takeException(), isNull);
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
