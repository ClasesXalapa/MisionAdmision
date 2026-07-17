class AppConstants {
  const AppConstants._();

  static const String appVersion = '0.9.9';
  static const int appBuildNumber = 21;
  static const int supportedContentSchemaVersion = 1;
  static const Duration contentRequestTimeout = Duration(seconds: 15);
  static const int maxContentDocumentBytes = 5 * 1024 * 1024;
}
