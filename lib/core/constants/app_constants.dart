class AppConstants {
  const AppConstants._();

  static const String appVersion = '0.9.8';
  static const int appBuildNumber = 20;
  static const int supportedContentSchemaVersion = 1;
  static const Duration contentRequestTimeout = Duration(seconds: 15);
  static const int maxContentDocumentBytes = 5 * 1024 * 1024;
}
