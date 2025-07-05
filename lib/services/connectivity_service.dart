import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static void initialize(Function(bool) onConnectivityChanged) {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      onConnectivityChanged(isConnected);
    });
  }

  static Future<bool> isConnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}