import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  bool isOnline = true;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _controller.stream;

  StreamSubscription? _subscription;

  Future<void> init() async {
    final result = await Connectivity().checkConnectivity();
    isOnline = !result.contains(ConnectivityResult.none);

    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      final online = !result.contains(ConnectivityResult.none);
      if (online != isOnline) {
        isOnline = online;
        _controller.add(online);
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
