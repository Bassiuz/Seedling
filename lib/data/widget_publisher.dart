import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../logic/widget_actions.dart';
import '../logic/widget_payload.dart';

/// Hands today's summary to the home-screen widget, and takes back whatever
/// was ticked off on it.
///
/// The widget itself is native — a Kotlin provider on Android and an Xcode
/// target on iOS (see `docs/widget-setup.md`); this is only the Dart half.
/// Failures are swallowed on purpose: a missing widget must never stop the
/// app.
class WidgetPublisher {
  const WidgetPublisher({this.appGroupId = 'group.dev.bassiuz.seedling'});

  /// Shared between the app and the iOS widget extension; both must declare
  /// it. Ignored on Android.
  final String appGroupId;

  static const dataKey = 'seedling_today';
  static const pendingKey = 'seedling_pending';
  static const iosWidgetName = 'SeedlingWidget';
  static const androidWidgetName = 'SeedlingWidgetProvider';

  Future<void> publish(WidgetPayload payload) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData<String>(dataKey, payload.toJson());
      await HomeWidget.updateWidget(
        iOSName: iosWidgetName,
        androidName: androidWidgetName,
      );
    } catch (error) {
      debugPrint('Seedling: could not update the widget: $error');
    }
  }

  /// What was ticked off on the widget since the app last looked.
  Future<PendingToggles> takePending() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      final queued = PendingToggles.parse(
          await HomeWidget.getWidgetData<String>(pendingKey));
      if (!queued.isEmpty) {
        await HomeWidget.saveWidgetData<String>(pendingKey, '[]');
      }
      return queued;
    } catch (_) {
      return PendingToggles.empty;
    }
  }
}

/// Runs in a background isolate when a checkbox on the widget is tapped.
///
/// It does not write to Firestore. Opening the offline database from a second
/// isolate is what produced "LOCK: Resource temporarily unavailable" earlier
/// in this project, and a home screen is a bad place to discover that. The tap
/// is queued and the widget redrawn as though it had landed; the app makes it
/// true when it next runs.
@pragma('vm:entry-point')
Future<void> widgetTapped(Uri? uri) async {
  final taskId = toggledTaskId(uri);
  if (taskId == null) return;

  await HomeWidget.setAppGroupId(const WidgetPublisher().appGroupId);

  final queued = PendingToggles.parse(
      await HomeWidget.getWidgetData<String>(WidgetPublisher.pendingKey));
  await HomeWidget.saveWidgetData<String>(
      WidgetPublisher.pendingKey, queued.plus(taskId).toJson());

  // Redraw without it, so the tap feels like it did something. The app will
  // rebuild this properly the moment it opens.
  final shown = await HomeWidget.getWidgetData<String>(WidgetPublisher.dataKey);
  if (shown != null) {
    await HomeWidget.saveWidgetData<String>(
        WidgetPublisher.dataKey, withoutTask(shown, taskId));
  }

  await HomeWidget.updateWidget(
    iOSName: WidgetPublisher.iosWidgetName,
    androidName: WidgetPublisher.androidWidgetName,
  );
}

/// Drops one task from a published payload without rebuilding it, so the
/// background isolate needs nothing but the JSON it already has.
@visibleForTesting
String withoutTask(String json, String taskId) {
  try {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final tasks = (map['tasks'] as List<dynamic>? ?? const [])
        .where((t) => (t as Map<String, dynamic>)['id'] != taskId)
        .toList();
    return jsonEncode({...map, 'tasks': tasks});
  } catch (_) {
    return json;
  }
}
