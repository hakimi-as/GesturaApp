import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connection status enum
enum ConnectionStatus {
  online,
  offline,
  unknown,
}

/// Provider to manage network connectivity state
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  
  ConnectionStatus _status = ConnectionStatus.unknown;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  bool _isInitialized = false;

  /// Current connection status
  ConnectionStatus get status => _status;
  
  /// Whether device is online
  bool get isOnline => _status == ConnectionStatus.online;
  
  /// Whether device is offline
  bool get isOffline => _status == ConnectionStatus.offline;
  
  /// Current connection type (wifi, mobile, etc.)
  ConnectivityResult get connectionType => _connectionType;
  
  /// Whether connected via WiFi
  bool get isWifi => _connectionType == ConnectivityResult.wifi;
  
  /// Whether connected via mobile data
  bool get isMobile => _connectionType == ConnectivityResult.mobile;
  
  /// Whether initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the connectivity provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get initial connectivity status
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      
      // Listen for connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          debugPrint('Connectivity error: $error');
          _status = ConnectionStatus.unknown;
          notifyListeners();
        },
      );
      
      _isInitialized = true;
      debugPrint('📶 ConnectivityProvider initialized: $_status');
    } catch (e) {
      debugPrint('Error initializing connectivity: $e');
      _status = ConnectionStatus.unknown;
      _isInitialized = true;
    }
  }

  /// Update connection status from connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionType = result;
    
    final wasOnline = _status == ConnectionStatus.online;
    
    if (result == ConnectivityResult.none) {
      _status = ConnectionStatus.offline;
    } else {
      _status = ConnectionStatus.online;
    }
    
    final isNowOnline = _status == ConnectionStatus.online;
    
    // Log status changes
    if (wasOnline != isNowOnline) {
      debugPrint('📶 Connection changed: ${isNowOnline ? "ONLINE" : "OFFLINE"}');
      debugPrint('   Type: ${result.name}');
    }
    
    notifyListeners();
  }

  /// Manually check current connectivity
  Future<ConnectionStatus> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _status;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return ConnectionStatus.unknown;
    }
  }

  /// Get human readable connection type string
  String get connectionTypeString {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No connection';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}


/// Singleton instance for easy access
class ConnectivityService {
  static final ConnectivityProvider _instance = ConnectivityProvider();
  
  static ConnectivityProvider get instance => _instance;
  
  static Future<void> initialize() => _instance.initialize();
  
  static bool get isOnline => _instance.isOnline;
  static bool get isOffline => _instance.isOffline;
  static ConnectionStatus get status => _instance.status;
}