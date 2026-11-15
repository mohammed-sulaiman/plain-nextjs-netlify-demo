import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'data/repository.dart';
import 'l10n/gen/app_localizations.dart';
import 'services/cloud.dart';
import 'state/account.dart';
import 'state/settings_store.dart';
import 'state/tree_store.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CloudConfig.init();
  final settings = SettingsStore();
  await settings.load();
  final store = TreeStore(LocalTreeRepository());
  final account = AccountController(store);
  // Opened from an invite link (web): https://…/?invite=CODE
  final invite = Uri.base.queryParameters['invite'];
  if (invite != null && invite.isNotEmpty) account.pendingInvite = invite;
  // Don't block the first frame on network: the store shows a spinner.
  account.init();
  runApp(FamilyTreeApp(settings: settings, store: store, account: account));
}

class FamilyTreeApp extends StatelessWidget {
  final SettingsStore settings;
  final TreeStore store;
  final AccountController account;

  const FamilyTreeApp({
    super.key,
    required this.settings,
    required this.store,
    required this.account,
  });

  static const seed = Color(0xFF2E7D6B);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider.value(value: account),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, s, _) => MaterialApp(
          onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
          debugShowCheckedModeBanner: false,
          locale: s.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          themeMode: s.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: seed),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
