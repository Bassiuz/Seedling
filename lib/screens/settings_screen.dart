import 'package:flutter/material.dart';

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
    this.onExportVault,
    this.vaultPath,
    this.exportStatus,
    this.mirroring = true,
    this.onMirroringChanged,
    required this.onSignOut,
    this.signedInAs,
  });

  final bool einkMode;
  final ValueChanged<bool> onEinkChanged;
  final VoidCallback onOpenTags;
  final VoidCallback onOpenQuestions;
  final VoidCallback onOpenSomeday;

  /// Null where this machine cannot hold a vault, which hides the whole block.
  final VoidCallback? onExportVault;
  final String? vaultPath;
  final String? exportStatus;

  /// Whether the vault follows the app as you type.
  final bool mirroring;
  final ValueChanged<bool>? onMirroringChanged;
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
                ],
              ),
            ),
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
    this.onExportVault,
    this.vaultPath,
    this.exportStatus,
    required this.onSignOut,
    this.signedInAs,
  });

  final SettingsStore settings;
  final VoidCallback onOpenTags;
  final VoidCallback onOpenQuestions;
  final VoidCallback onOpenSomeday;

  /// Null where this machine cannot hold a vault, which hides the whole block.
  final VoidCallback? onExportVault;
  final String? vaultPath;
  final String? exportStatus;
  final VoidCallback onSignOut;
  final String? signedInAs;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SettingsView(
        einkMode: settings.einkMode,
        onEinkChanged: settings.setEinkMode,
        onOpenTags: onOpenTags,
        onOpenQuestions: onOpenQuestions,
        onOpenSomeday: onOpenSomeday,
        onSignOut: onSignOut,
        signedInAs: signedInAs,
        onExportVault: onExportVault,
        vaultPath: vaultPath,
        exportStatus: exportStatus,
        mirroring: settings.vaultMirroring,
        onMirroringChanged: settings.setVaultMirroring,
      ),
    );
  }
}
