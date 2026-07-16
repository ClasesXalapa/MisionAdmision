import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mision_admision/core/constants/app_constants.dart';
import 'package:mision_admision/core/network/remote_text_client.dart';

class HttpRemoteTextClient implements RemoteTextClient {
  HttpRemoteTextClient({
    required http.Client client,
    this.timeout = AppConstants.contentRequestTimeout,
    this.maxBytes = AppConstants.maxContentDocumentBytes,
  }) : _client = client;

  final http.Client _client;
  final Duration timeout;
  final int maxBytes;

  @override
  Future<String> get(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(timeout);

    if (response.statusCode != 200) {
      throw StateError(
        'La descarga respondió HTTP ${response.statusCode}: $uri',
      );
    }
    if (response.bodyBytes.length > maxBytes) {
      throw StateError(
        'El archivo supera el límite permitido de $maxBytes bytes.',
      );
    }
    return utf8.decode(response.bodyBytes);
  }
}
