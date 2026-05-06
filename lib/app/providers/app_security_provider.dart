import 'package:flutter/foundation.dart';
import '../services/security_service.dart';

class AppSecurityProvider with ChangeNotifier {
  bool _isAppLocked = true;
  bool _isCheckingLock = true;
  bool _isAppInBackground = false;

  bool get isAppLocked => _isAppLocked;
  bool get isCheckingLock => _isCheckingLock;
  bool get isAppInBackground => _isAppInBackground;

  AppSecurityProvider() {
    _initializeAppLock();
  }

  Future<void> _initializeAppLock() async {
    try {
      final lockRequired = await SecurityService.instance.isAppLockRequired();
      // Always lock the app on initialization if app lock is enabled
      _isAppLocked = lockRequired;
      _isCheckingLock = false;
      notifyListeners();
    } catch (e) {
      _isAppLocked = false;
      _isCheckingLock = false;
      notifyListeners();
    }
  }

  Future<void> unlockApp() async {
    _isAppLocked = false;
    _isAppInBackground = false;
    await SecurityService.instance.updateLastAuthTime();
    notifyListeners();
  }

  Future<void> lockApp() async {
    _isAppLocked = true;
    notifyListeners();
  }

  Future<void> checkAppLockStatus() async {
    final lockRequired = await SecurityService.instance.isAppLockRequired();
    // Always lock if app lock is enabled, regardless of current state
    if (lockRequired) {
      _isAppLocked = true;
      notifyListeners();
    }
  }

  // Call this when app comes to foreground
  Future<void> onAppResumed() async {
    print('App resumed - checking lock status');
    _isAppInBackground = false;
    await checkAppLockStatus();
  }

  // Call this when app goes to background (minimized)
  Future<void> onAppPaused() async {
    print('App paused/minimized - locking app');
    final lockRequired = await SecurityService.instance.isAppLockRequired();
    if (lockRequired) {
      _isAppLocked = true;
      _isAppInBackground = true;
      notifyListeners();
    }
  }

  // Call this when app becomes inactive (during phone calls, etc.)
  Future<void> onAppInactive() async {
    print('App inactive - hiding content');
    final lockRequired = await SecurityService.instance.isAppLockRequired();
    if (lockRequired) {
      _isAppInBackground = true;
      notifyListeners();
    }
  }

  // Call this when user logs out
  Future<void> onLogout() async {
    await SecurityService.instance.clearSecurityData();
    _isAppLocked = true;
    notifyListeners();
  }
}
