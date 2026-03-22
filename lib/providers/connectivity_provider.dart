import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks device connectivity for offline UI (banner, etc.).
/// Note: "connected" does not guarantee reachable servers — API retries + stale cache handle that.
class ConnectivityNotifier extends ChangeNotifier {
  ConnectivityNotifier() {
    _subscription = Connectivity().onConnectivityChanged.listen(_onChanged);
    unawaited(_refresh());
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;

  bool get isOffline => _offline;

  Future<void> _refresh() async {
    try {
      final list = await Connectivity().checkConnectivity();
      _apply(list);
    } catch (_) {}
  }

  void _onChanged(List<ConnectivityResult> list) => _apply(list);

  void _apply(List<ConnectivityResult> list) {
    final offline = list.contains(ConnectivityResult.none);
    if (offline != _offline) {
      _offline = offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
