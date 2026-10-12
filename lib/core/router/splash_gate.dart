import 'package:flutter/foundation.dart';

/// Keeps the splash screen visible until its animation has finished.
/// The router checks it before leaving the splash.
class SplashGate extends ChangeNotifier {
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  void open() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }
}