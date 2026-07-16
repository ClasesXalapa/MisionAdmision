abstract interface class RemoteTextClient {
  Future<String> get(Uri uri);
}
