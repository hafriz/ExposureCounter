import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  AppLockController() {
    WidgetsBinding.instance.addObserver(this);
  }

  static const _enabledKey = 'application_lock_enabled';

  final _auth = LocalAuthentication();
  SharedPreferences? _preferences;
  bool _initialized = false;
  bool _initializing = true;
  bool _enabled = false;
  bool _locked = true;
  bool _busy = false;
  bool _needsUnlock = false;
  String? _error;

  bool get initializing => _initializing;
  bool get enabled => _enabled;
  bool get locked => _locked;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> initialize() async {
    if (_initialized) return;
    _preferences = await SharedPreferences.getInstance();
    _enabled = _preferences!.getBool(_enabledKey) ?? false;
    _initialized = true;
    _initializing = false;
    notifyListeners();
    if (_enabled) await unlock();
    if (!_enabled) {
      _locked = false;
      notifyListeners();
    }
  }

  Future<bool> enable() async {
    if (_enabled || _busy) return _enabled;
    _error = null;
    final supported =
        await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    if (!supported) {
      _error = 'No biometric or device authentication is available.';
      notifyListeners();
      return false;
    }
    final authenticated = await _authenticate();
    if (!authenticated) return false;
    _enabled = true;
    _locked = false;
    await _preferences?.setBool(_enabledKey, true);
    notifyListeners();
    return true;
  }

  Future<void> disable() async {
    _enabled = false;
    _locked = false;
    _needsUnlock = false;
    _error = null;
    await _preferences?.setBool(_enabledKey, false);
    notifyListeners();
  }

  Future<void> unlock() async {
    if (!_enabled || _busy) return;
    final authenticated = await _authenticate();
    if (authenticated) {
      _locked = false;
      _needsUnlock = false;
      _error = null;
      notifyListeners();
    }
  }

  Future<bool> _authenticate() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock Exposure Counter to view your private records',
        persistAcrossBackgrounding: true,
      );
      if (!authenticated) _error = 'Authentication was cancelled.';
      return authenticated;
    } catch (_) {
      _error = 'Authentication is unavailable on this device.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled || !_initialized) return;
    if (state == AppLifecycleState.paused && !_busy) {
      _needsUnlock = true;
      _locked = true;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed && _needsUnlock) {
      _needsUnlock = false;
      unlock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class AppLockScope extends InheritedNotifier<AppLockController> {
  const AppLockScope({required AppLockController controller, required Widget child})
      : super(notifier: controller, child: child);

  static AppLockController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLockScope>();
    assert(scope != null, 'AppLockScope is missing above this context.');
    return scope!.notifier!;
  }
}
