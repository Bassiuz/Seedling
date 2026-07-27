import 'package:home_widget/home_widget.dart';

import '../logic/widget_payload.dart';

/// Hands today's summary to the home-screen widget.
///
/// The widget itself lives in a separate Xcode target (see
/// `docs/ios-widget-setup.md`); this is only the Dart half that keeps its data
/// fresh. Failures are swallowed on purpose — a missing widget must never stop
/// the app.
class WidgetPublisher {
  const WidgetPublisher({this.appGroupId = 'group.dev.bassiuz.seedling'});

  /// Shared between the app and the widget extension; both must declare it.
  final String appGroupId;

  static const _dataKey = 'seedling_today';
  static const _iosWidgetName = 'SeedlingWidget';
  static const _androidWidgetName = 'SeedlingWidgetProvider';

  Future<void> publish(WidgetPayload payload) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData<String>(_dataKey, payload.toJson());
      await HomeWidget.updateWidget(
        iOSName: _iosWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (_) {
      // No widget installed, or no app group configured yet.
    }
  }
}
