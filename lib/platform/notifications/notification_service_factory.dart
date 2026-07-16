import 'package:mision_admision/platform/notifications/notification_service.dart';
import 'package:mision_admision/platform/notifications/notification_service_stub.dart'
    if (dart.library.js_interop) 'package:mision_admision/platform/notifications/notification_service_web.dart';

NotificationService createNotificationService() => createPlatformNotificationService();
