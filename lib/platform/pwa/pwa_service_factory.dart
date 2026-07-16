import 'package:mision_admision/platform/pwa/pwa_service.dart';
import 'package:mision_admision/platform/pwa/pwa_service_stub.dart'
    if (dart.library.js_interop) 'package:mision_admision/platform/pwa/pwa_service_web.dart'
    as implementation;

PwaService createPwaService() => implementation.createPwaService();
