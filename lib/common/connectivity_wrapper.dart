import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  // Use a nullable type to represent initial "unknown" state if needed,
  // currently assuming we want to listen immediately.
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    // Check initial state
    _checkInitialConnection();
    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      _updateConnectionStatus(result);
    });
  }

  Future<void> _checkInitialConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint("Error checking connectivity: $e");
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    // result is a list. If it contains none and nothing else, or simply if it does not contain mobile/wifi/ethernet/vpn
    // Easier check: if it contains ConnectivityResult.none AND length is 1...
    // Actually documentation says: "The list will contain the connection types available."
    // If disconnected, it returns [ConnectivityResult.none].

    // So if any valid connection type is present, we are connected.
    bool hasConnection = result.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other,
    );

    if (mounted) {
      setState(() {
        _isConnected = hasConnection;
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // Ensure directionality for overlay
      child: Stack(
        children: [
          widget.child,
          if (!_isConnected)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: Colors.red,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: const Text(
                    "No Internet Connection",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
