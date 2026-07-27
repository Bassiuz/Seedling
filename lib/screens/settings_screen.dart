import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../theme/seedling_theme.dart';
import '../widgets/block_frame.dart';

/// Settings without any store behind it, so it can be golden-tested.
class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.einkMode,
    required this.onEinkChanged,
    required this.onOpenTags,
    required this.onSignOut,
    this.signedInAs,
  });

  final bool einkMode;
  final ValueChanged<bool> onEinkChanged;
  final VoidCallback onOpenTags;
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
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Tags', style: text.bodyLarge),
                trailing: Icon(Icons.chevron_right, color: colors.muted),
                onTap: onOpenTags,
              ),
            ),
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
    required this.onSignOut,
    this.signedInAs,
  });

  final SettingsStore settings;
  final VoidCallback onOpenTags;
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
        onSignOut: onSignOut,
        signedInAs: signedInAs,
      ),
    );
  }
}
