import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../logic/dates.dart';
import '../../state/account.dart';
import '../../state/settings_store.dart';
import '../../state/tree_store.dart';
import '../common.dart';
import 'login_screen.dart';
import 'sharing_screens.dart';

/// Native names of the supported languages. Adding a language = adding an
/// ARB file in lib/l10n and its native name here.
const languageNames = {'ar': 'العربية', 'en': 'English'};

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final account = context.watch<AccountController>();
    final store = context.watch<TreeStore>();
    final l = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            children: [
              _Header(l.account),
              if (!account.available)
                ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: Text(l.cloudNotConfigured),
                  subtitle: Text(l.cloudNotConfiguredHint),
                )
              else if (account.signedIn) ...[
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(account.user!.email ?? ''),
                  subtitle: Text(store.isCloud ? l.cloudSynced : l.localOnly),
                ),
                ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(l.myTrees),
                  subtitle: Text(account.cloudTree?.treeName ?? ''),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TreesScreen())),
                ),
                if (store.isCloud)
                  ListTile(
                    leading: const Icon(Icons.group_add_outlined),
                    title: Text(l.shareTree),
                    subtitle: Text(l.shareTreeHint),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ShareTreeScreen())),
                  ),
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: Text(l.joinWithCode),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const JoinTreeScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l.signOut),
                  onTap: () => account.signOut(),
                ),
              ] else
                ListTile(
                  leading: const Icon(Icons.login),
                  title: Text(l.signIn),
                  subtitle: Text(l.signInHint),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                ),
              _Header(l.language),
              RadioGroup<String>(
                groupValue: s.locale?.languageCode ?? 'system',
                onChanged: (v) =>
                    s.setLocale(v == null || v == 'system' ? null : Locale(v)),
                child: Column(
                  children: [
                    RadioListTile(value: 'system', title: Text(l.systemDefault)),
                    for (final code in AppLocalizations.supportedLocales
                        .map((e) => e.languageCode))
                      RadioListTile(
                          value: code,
                          title: Text(languageNames[code] ?? code)),
                  ],
                ),
              ),
              _Header(l.calendar),
              RadioGroup<CalendarMode>(
                groupValue: s.calendar,
                onChanged: (v) => s.setCalendar(v!),
                child: Column(
                  children: [
                    RadioListTile(
                        value: CalendarMode.gregorian,
                        title: Text(l.calendarGregorian)),
                    RadioListTile(
                        value: CalendarMode.hijri, title: Text(l.calendarHijri)),
                    RadioListTile(
                        value: CalendarMode.both, title: Text(l.calendarBoth)),
                  ],
                ),
              ),
              _Header(l.theme),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto),
                        label: Text(l.systemDefault)),
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode),
                        label: Text(l.themeLight)),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode),
                        label: Text(l.themeDark)),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => s.setThemeMode(v.first),
                ),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.appTitle),
                subtitle: Text(l.aboutText),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l.peopleCount(store.data.persons.length),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
