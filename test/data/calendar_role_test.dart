import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which devices read a calendar and which show what another device shared.
///
/// Being Android is not the same as being able to see the calendar: the BigMe
/// runs Android with no iCloud account, so it must not read its own calendar
/// and must never publish over what the phone shared.
void main() {
  late SettingsStore settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsStore(await SharedPreferences.getInstance());
  });

  tearDown(() {
    SettingsStore.defaultReadsDeviceCalendarFor = () => false;
  });

  test('the phone reads its own calendar by default', () async {
    SettingsStore.defaultReadsDeviceCalendarFor = () => true;
    SharedPreferences.setMockInitialValues({});
    settings = SettingsStore(await SharedPreferences.getInstance());

    expect(settings.readsDeviceCalendar, isTrue);
  });

  test('anything else shows what was shared, so the BigMe does not publish',
      () async {
    SettingsStore.defaultReadsDeviceCalendarFor = () => false;
    SharedPreferences.setMockInitialValues({});
    settings = SettingsStore(await SharedPreferences.getInstance());

    expect(settings.readsDeviceCalendar, isFalse);
  });

  test('the choice is remembered once made', () async {
    SettingsStore.defaultReadsDeviceCalendarFor = () => false;

    await settings.setReadsDeviceCalendar(true);
    expect(settings.readsDeviceCalendar, isTrue);

    await settings.setReadsDeviceCalendar(false);
    expect(settings.readsDeviceCalendar, isFalse);
  });

  test('changing it tells listeners, so the day page swaps source', () async {
    var notified = 0;
    settings.addListener(() => notified++);

    await settings.setReadsDeviceCalendar(true);

    expect(notified, 1);
  });

  test('it is separate from the other per-device settings', () async {
    await settings.setReadsDeviceCalendar(true);
    await settings.setEinkMode(true);

    expect(settings.readsDeviceCalendar, isTrue);
    expect(settings.einkMode, isTrue);
    expect(settings.vaultMirroring, isTrue, reason: 'untouched default');
  });
}
