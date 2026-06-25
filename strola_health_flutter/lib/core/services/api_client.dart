import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Backend base URL. `localhost` resolves to the phone itself when testing
/// on a real device (e.g. over adb wifi), not your dev machine — override
/// with your machine's LAN IP:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api/v1`
/// The Android emulator's loopback alias is `10.0.2.2`, not `localhost`.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

/// Thin wrapper around Dio that attaches the current Firebase ID token to
/// every request. One instance for the whole app — created once in
/// `backendApiProvider` (see `backend_api.dart`).
class ApiClient {
  ApiClient(this._auth)
      : dio = Dio(
          BaseOptions(
            baseUrl: apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _auth.currentUser?.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final FirebaseAuth _auth;
  final Dio dio;
}
