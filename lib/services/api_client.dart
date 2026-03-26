import 'package:backend_client/backend_client.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Client client;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  void init() {
    // 1. For Physical Devices + USB: Run 'adb reverse tcp:8080 tcp:8080' and use 'http://localhost:8080/'
    // 2. For Android Emulators: Use 'http://10.0.2.2:8080/'
    // 3. For Physical Devices + Wi-Fi: Use your Computer's Local IP (e.g. 'http://192.168.1.15:8080/')
    
    const String baseUrl = 'http://localhost:8080/'; 
    
    client = Client(
      baseUrl,
      authenticationKeyManager: FlutterAuthenticationKeyManager(),
    )..connectivityMonitor = FlutterConnectivityMonitor();
  }
}

final apiClient = ApiClient();
