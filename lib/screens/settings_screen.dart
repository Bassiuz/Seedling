import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/seedling_repo.dart';

import '../data/settings_store.dart';
import '../theme/seedling_theme.dart';
import '../widgets/back_line.dart';
import '../widgets/block_frame.dart';

/// Settings without any store behind it, so it can be golden-tested.
class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.einkMode,
    required this.onEinkChanged,
    required this.onOpenTags,
    required this.onOpenQuestions,
    required this.onOpenSomeday,
    required this.onOpenGoals,
    this.onExportVault,
    this.vaultPath,
    this.exportStatus,
    this.mirroring = true,
    this.onMirroringChanged,
    this.readsDeviceCalendar = false,
    this.onReadsCalendarChanged,
    this.calendarShare,
    this.standupName = '',
    this.onStandupNameChanged,
    this.onOpenTimesheet,
    required this.onSignOut,
    this.signedInAs,
  });

  final bool einkMode;
  final ValueChanged<bool> onEinkChanged;
  final VoidCallback onOpenTags;
  final VoidCallback onOpenQuestions;
  final VoidCallback onOpenSomeday;
  final VoidCallback onOpenGoals;

  /// Null where this machine cannot hold a vault, which hides the whole block.
  final VoidCallback? onExportVault;
  final String? vaultPath;
  final String? exportStatus;

  /// Whether the vault follows the app as you type.
  final bool mirroring;
  final ValueChanged<bool>? onMirroringChanged;

  /// Whether this device reads its own calendar or shows what another one
  /// published. Null hides the row where no calendar can be read at all.
  final bool readsDeviceCalendar;
  final ValueChanged<bool>? onReadsCalendarChanged;

  /// What was last shared, so a device that only reads can tell the
  /// difference between "no appointments" and "nothing ever arrived".
  final String? calendarShare;

  /// Heads the standup you copy for Slack. Null hides the field.
  final String standupName;
  final ValueChanged<String>? onStandupNameChanged;

  /// Sends the hours logged against a ticket to its Jira worklog.
  final VoidCallback? onOpenTimesheet;
  final VoidCallback onSignOut;
  final String? signedInAs;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const BackLine(),
            Text('Settings', style: text.displaySmall),
            const SizedBox(height: 24),
            BlockFrame(
              title: 'Display',
              icon: Icons.contrast,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: einkMode,
                onChanged: onEinkChanged,
                title: Text('E-ink mode', style: text.bodyLarge),
                subtitle: Text(
                  'Black on white, no animation. This setting belongs to this '
                  'device, so the BigMe can use it while the phone does not.',
                  style: text.labelMedium,
                ),
              ),
            ),
            const SizedBox(height: 28),
            BlockFrame(
              title: 'Projects',
              icon: Icons.label_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Tags', style: text.bodyLarge),
                    trailing: Icon(Icons.chevron_right, color: colors.muted),
                    onTap: onOpenTags,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Daily questions', style: text.bodyLarge),
                    trailing: Icon(Icons.chevron_right, color: colors.muted),
                    onTap: onOpenQuestions,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Someday', style: text.bodyLarge),
                    trailing: Icon(Icons.chevron_right, color: colors.muted),
                    onTap: onOpenSomeday,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Goals', style: text.bodyLarge),
                    subtitle: Text('Quarterly and yearly, for week reviews',
                        style: text.labelMedium),
                    trailing: Icon(Icons.chevron_right, color: colors.muted),
                    onTap: onOpenGoals,
                  ),
                  if (onOpenTimesheet != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Timesheet', style: text.bodyLarge),
                      subtitle: Text(
                          'The week as a grid, and the way into Jira',
                          style: text.labelMedium),
                      trailing:
                          Icon(Icons.chevron_right, color: colors.muted),
                      onTap: onOpenTimesheet,
                    ),
                ],
              ),
            ),
            if (onReadsCalendarChanged != null) ...[
              const SizedBox(height: 28),
              BlockFrame(
                title: 'Calendar',
                icon: Icons.event_outlined,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: readsDeviceCalendar,
                  onChanged: onReadsCalendarChanged,
                  title: Text('Read this device\u2019s calendar',
                      style: text.bodyLarge),
                  subtitle: Text(
                    readsDeviceCalendar
                        ? 'This device reads your calendar and shares it with '
                            'the others.'
                        : 'This device shows the appointments another device '
                            'shared. Leave it off where there is no calendar '
                            'account, like the BigMe.',
                    style: text.labelMedium,
                  ),
                ),
              ),
              if (calendarShare != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 4),
                  child: Text(calendarShare!,
                      style: text.labelMedium?.copyWith(color: colors.muted)),
                ),
            ],
            if (onStandupNameChanged != null) ...[
              const SizedBox(height: 28),
              BlockFrame(
                title: 'Standup',
                icon: Icons.groups_outlined,
                child: _StandupName(
                  initial: standupName,
                  onChanged: onStandupNameChanged!,
                ),
              ),
            ],
            if (onExportVault != null) ...[
              const SizedBox(height: 28),
              BlockFrame(
                title: 'Markdown vault',
                icon: Icons.folder_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Writes every day, review and list as Markdown so an '
                      'agent can read them. One way — nothing there is read '
                      'back.',
                      style: text.labelMedium,
                    ),
                    if (vaultPath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(vaultPath!,
                            style: text.labelMedium
                                ?.copyWith(color: colors.muted)),
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: mirroring,
                      onChanged: onMirroringChanged,
                      title: Text('Keep it up to date automatically',
                          style: text.bodyLarge),
                      subtitle: Text(
                        'Rewrites a day as you change it. Days you do not '
                        'open are left alone — use the full export for those.',
                        style: text.labelMedium,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Export everything now',
                          style: text.bodyLarge),
                      subtitle: exportStatus == null
                          ? null
                          : Text(exportStatus!, style: text.labelMedium),
                      trailing:
                          Icon(Icons.ios_share, color: colors.muted),
                      onTap: onExportVault,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            BlockFrame(
              title: 'Account',
              icon: Icons.person_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (signedInAs != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(signedInAs!, style: text.labelMedium),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Sign out', style: text.bodyLarge),
                    trailing: Icon(Icons.logout, color: colors.muted),
                    onTap: onSignOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The live settings screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onOpenTags,
    required this.onOpenQuestions,
    required this.onOpenSomeday,
    required this.onOpenGoals,
    this.onExportVault,
    this.vaultPath,
    this.exportStatus,
    this.canReadDeviceCalendar = false,
    required this.onSignOut,
    this.signedInAs,
    required this.repo,
    this.onOpenTimesheet,
  });

  final SettingsStore settings;
  final VoidCallback onOpenTags;
  final VoidCallback onOpenQuestions;
  final VoidCallback onOpenSomeday;
  final VoidCallback onOpenGoals;

  /// Null where this machine cannot hold a vault, which hides the whole block.
  final VoidCallback? onExportVault;
  final String? vaultPath;
  final String? exportStatus;

  /// False where the platform has no calendar to read, which hides the row.
  final bool canReadDeviceCalendar;

  /// Reads the last publish, so the row can say what actually arrived.
  final SeedlingRepo repo;
  final VoidCallback? onOpenTimesheet;
  final VoidCallback onSignOut;
  final String? signedInAs;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CalendarShare?>(
      stream: repo.watchCalendarShare(),
      builder: (context, shareSnap) => ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SettingsView(
        calendarShare: _shareLine(shareSnap.data),
        einkMode: settings.einkMode,
        onEinkChanged: settings.setEinkMode,
        onOpenTags: onOpenTags,
        onOpenQuestions: onOpenQuestions,
        onOpenSomeday: onOpenSomeday,
        onOpenGoals: onOpenGoals,
        onSignOut: onSignOut,
        signedInAs: signedInAs,
        onExportVault: onExportVault,
        vaultPath: vaultPath,
        exportStatus: exportStatus,
        mirroring: settings.vaultMirroring,
        onMirroringChanged: settings.setVaultMirroring,
        onOpenTimesheet: onOpenTimesheet,
        standupName: settings.standupName,
        onStandupNameChanged: settings.setStandupName,
        readsDeviceCalendar: settings.readsDeviceCalendar,
        onReadsCalendarChanged:
            canReadDeviceCalendar ? settings.setReadsDeviceCalendar : null,
      ),
      ),
    );
  }

  /// Nothing at all reads as nothing having arrived, which is the case worth
  /// being able to see.
  static String? _shareLine(CalendarShare? share) {
    if (share == null) return 'No device has shared a calendar yet.';
    final when = share.at;
    final stamp = when == null
        ? ''
        : ' on ${DateFormat('MMM d, HH:mm', 'en_US').format(when)}';
    return share.count == 1
        ? 'Last shared: 1 appointment$stamp.'
        : 'Last shared: ${share.count} appointments$stamp.';
  }
}

/// The name the copied standup is headed with.
///
/// Typed rather than taken from the email address: "devaan.bas" is not what
/// anyone calls you, and a wrong name pasted into Slack is worse than none.
class _StandupName extends StatefulWidget {
  const _StandupName({required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_StandupName> createState() => _StandupNameState();
}

class _StandupNameState extends State<_StandupName> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          style: text.bodyLarge,
          decoration: InputDecoration.collapsed(
            hintText: 'Your name…',
            hintStyle: text.bodyLarge?.copyWith(color: colors.faint),
          ),
        ),
        const SizedBox(height: 6),
        Text('Heads the standup you copy for Slack. Leave it empty to copy '
            'just the two lists.', style: text.labelMedium),
      ],
    );
  }
}
