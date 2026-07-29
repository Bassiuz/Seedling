import 'dart:io';

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
  static const _mirrorKey = 'vault.mirror';
  static const _readsCalendarKey = 'calendar.readsDevice';
  static const _standupNameKey = 'standup.name';

  final SharedPreferences _prefs;

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());

  /// The name the copied standup is headed with, as your colleagues know
  /// you. Empty leaves the heading off rather than guessing it out of an
  /// email address.
  String get standupName => _prefs.getString(_standupNameKey) ?? '';

  Future<void> setStandupName(String name) async {
    await _prefs.setString(_standupNameKey, name.trim());
    notifyListeners();
  }

  bool get einkMode => _prefs.getBool(_einkKey) ?? false;

  Future<void> setEinkMode(bool on) async {
    await _prefs.setBool(_einkKey, on);
    notifyListeners();
  }

  /// Whether the Markdown vault follows the app automatically. On by default
  /// where a vault is possible: an export you have to remember is an export
  /// that goes stale.
  bool get vaultMirroring => _prefs.getBool(_mirrorKey) ?? true;

  Future<void> setVaultMirroring(bool on) async {
    await _prefs.setBool(_mirrorKey, on);
    notifyListeners();
  }

  /// Whether this device reads its own calendar, or shows what another device
  /// published.
  ///
  /// Defaults to on for the iPhone and off everywhere else. Being Android is
  /// not the same as being able to see your calendar: the BigMe runs Android
  /// but has no iCloud account, so reading its own calendar shows nothing and
  /// publishing from it would overwrite what the phone shared.
  bool get readsDeviceCalendar =>
      _prefs.getBool(_readsCalendarKey) ?? defaultReadsDeviceCalendar;

  /// Overridable so tests do not depend on the platform they run on.
  static bool Function() defaultReadsDeviceCalendarFor = () => Platform.isIOS;

  static bool get defaultReadsDeviceCalendar =>
      defaultReadsDeviceCalendarFor();

  Future<void> setReadsDeviceCalendar(bool on) async {
    await _prefs.setBool(_readsCalendarKey, on);
    notifyListeners();
  }
}
