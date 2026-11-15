import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../state/account.dart';
import '../../state/tree_store.dart';
import '../common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final account = context.read<AccountController>();
    final l = context.l10n;
    // Read the device tree before switching to the cloud one.
    final local = await account.localTree();
    setState(() => _busy = true);
    try {
      if (_register) {
        final active = await account.signUp(_email.text.trim(), _password.text);
        if (!active) {
          if (mounted) context.snack(l.checkEmail);
          setState(() => _busy = false);
          return;
        }
      } else {
        await account.signIn(_email.text.trim(), _password.text);
      }
      if (!mounted) return;
      final store = context.read<TreeStore>();
      if (store.data.isEmpty && !local.isEmpty) {
        final upload = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.uploadTitle),
            content: Text(l.uploadQuestion(local.persons.length)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.notNow)),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l.upload)),
            ],
          ),
        );
        if (upload == true) await store.replaceAll(local);
      }
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      if (mounted) context.snack(e.message);
    } catch (e) {
      if (mounted) context.snack('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final account = context.read<AccountController>();
    return Scaffold(
      appBar: AppBar(title: Text(_register ? l.createAccount : l.signIn)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.cloud_sync_outlined,
                      size: 72, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(l.signInHint, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l.email,
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v != null && v.contains('@') ? null : l.invalidEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: l.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        v != null && v.length >= 8 ? null : l.passwordTooShort,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_register ? l.createAccount : l.signIn),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            try {
                              await account.signInWithGoogle();
                            } catch (e) {
                              if (context.mounted) context.snack('$e');
                            }
                          },
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(l.continueWithGoogle),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _register = !_register),
                    child: Text(_register ? l.haveAccount : l.noAccount),
                  ),
                  if (!_register)
                    TextButton(
                      onPressed: () async {
                        if (!_email.text.contains('@')) {
                          context.snack(l.invalidEmail);
                          return;
                        }
                        await account.resetPassword(_email.text.trim());
                        if (context.mounted) context.snack(l.checkEmail);
                      },
                      child: Text(l.forgotPassword),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
