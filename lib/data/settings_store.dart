import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings that belong to *this device*, not to the account.
///
/// Display mode is the whole reason this is local: e-ink mode should be on for
/// the BigMe and off for the phone at the same time, so syncing it through
/// Firestore would be wrong.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs);

  static const _einkKey = 'display.eink';

  final SharedPreferences _prefs;

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());

  bool get einkMode => _prefs.getBool(_einkKey) ?? false;

  Future<void> setEinkMode(bool on) async {
    await _prefs.setBool(_einkKey, on);
    notifyListeners();
  }
}
