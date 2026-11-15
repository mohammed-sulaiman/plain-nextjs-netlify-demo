import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/dates.dart';
import '../logic/tree_layout.dart';

/// Fields that can be shown on each person's card in the tree view.
enum CardField {
  photo,
  lineage,
  age,
  birthDate,
  deathDate,
  birthPlace,
  residence,
  tribe,
  kunya,
}

class SettingsStore extends ChangeNotifier {
  static const _key = 'family_tree_settings_v1';

  /// null → follow the device language.
  Locale? locale;
  CalendarMode calendar = CalendarMode.both;
  ThemeMode themeMode = ThemeMode.system;
  Set<CardField> cardFields = {CardField.photo, CardField.age, CardField.residence};
  TreeScope scope = const TreeScope();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final l = j['locale'] as String?;
      locale = l == null ? null : Locale(l);
      calendar = CalendarMode.values.firstWhere((c) => c.name == j['calendar'],
          orElse: () => CalendarMode.both);
      themeMode = ThemeMode.values.firstWhere((c) => c.name == j['theme'],
          orElse: () => ThemeMode.system);
      cardFields = ((j['cardFields'] as List?) ?? [])
          .map((n) => CardField.values.where((f) => f.name == n))
          .expand((e) => e)
          .toSet();
      scope = TreeScope.fromJson(
          Map<String, dynamic>.from(j['scope'] as Map? ?? {}));
    } catch (_) {}
  }

  Future<void> _save() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key,
        jsonEncode({
          'locale': locale?.languageCode,
          'calendar': calendar.name,
          'theme': themeMode.name,
          'cardFields': cardFields.map((f) => f.name).toList(),
          'scope': scope.toJson(),
        }));
  }

  void setLocale(Locale? l) {
    locale = l;
    _save();
  }

  void setCalendar(CalendarMode c) {
    calendar = c;
    _save();
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    _save();
  }

  void toggleField(CardField f, bool on) {
    cardFields = {...cardFields};
    on ? cardFields.add(f) : cardFields.remove(f);
    _save();
  }

  void setScope(TreeScope s) {
    scope = s;
    _save();
  }
}
