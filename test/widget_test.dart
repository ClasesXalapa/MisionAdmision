import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/app/app.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/core/network/remote_text_client.dart';

import 'helpers/memory_json_store.dart';

void main() {
  testWidgets('muestra la pantalla inicial', (tester) async {
    // Reproduce una captura real de 540x1200. La app debe usar el ancho
    // disponible directamente y calcular la geometría mediante proporciones.
    tester.view
      ..physicalSize = const Size(540, 1200)
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

    // La composición puede caber completa en teléfonos altos o desplazarse en
    // teléfonos compactos; las acciones deben existir en ambos casos.
    expect(find.byKey(const Key('home_daily_challenge_action')), findsOneWidget);
    expect(find.byKey(const Key('home_exam_action')), findsOneWidget);

    final resourcesFinder = find.byKey(const Key('home_resources_action'));
    final examFinder = find.byKey(const Key('home_exam_action'));

    expect(resourcesFinder, findsOneWidget);
    expect(examFinder, findsOneWidget);

    // En Inicio ambas acciones deben ocupar el ancho útil y permanecer
    // apiladas, sin simular un viewport de otro tamaño.
    final resourcesTopLeft = tester.getTopLeft(resourcesFinder);
    final examTopLeft = tester.getTopLeft(examFinder);
    final resourcesSize = tester.getSize(resourcesFinder);
    final examSize = tester.getSize(examFinder);

    expect(examTopLeft.dy, greaterThan(resourcesTopLeft.dy));
    expect((examTopLeft.dx - resourcesTopLeft.dx).abs(), lessThan(1));
    final scaffoldWidth = tester.getSize(find.byType(Scaffold).first).width;
    expect(scaffoldWidth, closeTo(540, 1));
    final heroTitle = tester.widget<Text>(find.text('Tu misión de hoy'));
    expect(heroTitle.style?.fontSize, closeTo(scaffoldWidth * 0.065, 0.2));
    expect(resourcesSize.width, greaterThan(scaffoldWidth * 0.88));
    expect(examSize.width, greaterThan(scaffoldWidth * 0.88));
    expect(resourcesSize.height, greaterThan(scaffoldWidth * 0.18));
    expect(examSize.height, greaterThan(scaffoldWidth * 0.18));

    // El escalado móvil no debe producir desbordamientos ni otras excepciones
    // de renderizado en la barra inferior o en las cards de Inicio.
    expect(tester.takeException(), isNull);
  });

  testWidgets('recursos usa proporciones del viewport real', (tester) async {
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
    expect(scaffoldWidth, closeTo(720, 1));
    expect(title.style?.fontSize, closeTo(scaffoldWidth * 0.057, 0.2));
    expect(filterSize.width, lessThan(scaffoldWidth * 0.45));
    expect(filterSize.height, greaterThan(scaffoldWidth * 0.07));
    expect(filterSize.height, lessThan(scaffoldWidth * 0.14));

    await tester.scrollUntilVisible(
      find.byKey(const Key('resource_card_card_video_algebra_001')),
      700,
      scrollable: resourcesScrollable,
    );
    final firstCard = find.byKey(
      const Key('resource_card_card_video_algebra_001'),
    );
    expect(firstCard, findsOneWidget);
    expect(tester.getSize(firstCard).height, greaterThan(scaffoldWidth * 0.45));
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
