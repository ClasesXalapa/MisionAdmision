import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/app/app.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/core/network/remote_text_client.dart';

import 'helpers/memory_json_store.dart';

void main() {
  testWidgets('muestra la pantalla inicial', (tester) async {
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
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Reto'), findsOneWidget);
    expect(find.text('Recursos'), findsWidgets);
    expect(find.text('Examen'), findsOneWidget);
    expect(find.text('Datos y respaldo'), findsNothing);
    expect(find.text('Ayuda y diagnóstico'), findsNothing);
    expect(find.text('Aplicación instalada'), findsNothing);
    expect(find.text('Copiar ID de prueba'), findsNothing);

    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('Comenzar reto de hoy'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Comenzar reto de hoy'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Iniciar examen'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Iniciar examen'), findsOneWidget);
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
