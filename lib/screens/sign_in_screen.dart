import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/seedling_palette.dart';
import '../theme/seedling_theme.dart';

/// The sign-in form on its own, with no Firebase in sight, so it can be
/// golden-tested and driven in widget tests.
class SignInForm extends StatefulWidget {
  const SignInForm({super.key, required this.onSubmit, this.error, this.busy = false});

  final Future<void> Function(String email, String password) onSubmit;
  final String? error;
  final bool busy;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Seedling', style: text.displayMedium),
              Text('Your day on one page', style: text.bodyLarge),
              const SizedBox(height: 32),
              _Field(controller: _email, label: 'Email'),
              const SizedBox(height: 16),
              _Field(controller: _password, label: 'Password', obscure: true),
              if (widget.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.error!,
                  style: text.bodyMedium?.copyWith(color: SeedlingPalette.red),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: widget.busy
                    ? null
                    : () => widget.onSubmit(_email.text.trim(), _password.text),
                style: FilledButton.styleFrom(
                  backgroundColor: SeedlingPalette.greenDeep,
                  foregroundColor: colors.paper,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(widget.busy ? 'One moment…' : 'Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType:
          obscure ? TextInputType.text : TextInputType.emailAddress,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: colors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.faint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.faint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SeedlingPalette.greenDeep),
        ),
      ),
    );
  }
}

/// Signs in, creating the account on first use — this is a single-person app,
/// so a separate sign-up flow would be ceremony for an audience of one.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.auth});

  final FirebaseAuth auth;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _error;
  bool _busy = false;

  Future<void> _submit(String email, String password) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      try {
        await widget.auth
            .signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'user-not-found' && e.code != 'invalid-credential') {
          rethrow;
        }
        await widget.auth
            .createUserWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: SignInForm(onSubmit: _submit, error: _error, busy: _busy),
        ),
      );
}
