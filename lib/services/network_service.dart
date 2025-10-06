import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

/// Service for monitoring network connectivity and providing online status
class NetworkService {
  final Connectivity _connectivity = Connectivity();

  /// Stream that emits connectivity changes
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;

  /// Check if the device is online by testing actual internet connectivity
  /// Returns true if connected to the internet, false otherwise
  Future<bool> isOnline() async {
    try {
      // First check basic connectivity
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        return false;
      }

      // Test actual internet access by trying to reach a reliable host
      final response = await InternetAddress.lookup('google.com');
      return response.isNotEmpty && response[0].rawAddress.isNotEmpty;
    } catch (e) {
      // If lookup fails, we're offline
      return false;
    }
  }

  /// Get current connectivity status without internet check
  Future<ConnectivityResult> getCurrentConnectivity() async {
    return await _connectivity.checkConnectivity();
  }
}