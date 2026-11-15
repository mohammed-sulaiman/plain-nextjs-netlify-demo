import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/dates.dart';
import '../logic/lineage.dart';
import '../models/models.dart';
import '../state/settings_store.dart';
import '../state/tree_store.dart';

extension ContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  DateFormatter get dates => DateFormatter(
        locale: Localizations.localeOf(this).languageCode,
        mode: watch<SettingsStore>().calendar,
      );

  DateFormatter get datesRead => DateFormatter(
        locale: Localizations.localeOf(this).languageCode,
        mode: read<SettingsStore>().calendar,
      );

  void snack(String msg) => ScaffoldMessenger.of(this)
      .showSnackBar(SnackBar(content: Text(msg)));
}

String lineageOf(BuildContext context, FamilyData d, String id,
    {int depth = 4, bool family = true}) {
  final l = context.l10n;
  return lineage(d, id,
      sonWord: l.lineageSon,
      daughterWord: l.lineageDaughter,
      depth: depth,
      includeFamilyName: family);
}

Color genderColor(BuildContext context, Gender g) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  switch (g) {
    case Gender.male:
      return dark ? const Color(0xFF2B4A6B) : const Color(0xFFDCEBFA);
    case Gender.female:
      return dark ? const Color(0xFF6B2B4A) : const Color(0xFFFADCEB);
    case Gender.unknown:
      return dark ? const Color(0xFF444444) : const Color(0xFFEDEDED);
  }
}

String genderLabel(AppLocalizations l, Gender g) => switch (g) {
      Gender.male => l.male,
      Gender.female => l.female,
      Gender.unknown => l.unknownGender,
    };

String parentKindLabel(AppLocalizations l, ParentKind k) => switch (k) {
      ParentKind.biological => l.kindBiological,
      ParentKind.adoptive => l.kindAdoptive,
      ParentKind.milk => l.kindMilk,
    };

String unionStatusLabel(AppLocalizations l, UnionStatus s) => switch (s) {
      UnionStatus.married => l.statusMarried,
      UnionStatus.divorced => l.statusDivorced,
      UnionStatus.widowed => l.statusWidowed,
    };

String relativeTypeLabel(AppLocalizations l, RelativeType t) => switch (t) {
      RelativeType.father => l.addFather,
      RelativeType.mother => l.addMother,
      RelativeType.son => l.addSon,
      RelativeType.daughter => l.addDaughter,
      RelativeType.husband => l.addHusband,
      RelativeType.wife => l.addWife,
      RelativeType.brother => l.addBrother,
      RelativeType.sister => l.addSister,
    };

String cardFieldLabel(AppLocalizations l, CardField f) => switch (f) {
      CardField.photo => l.fieldPhoto,
      CardField.lineage => l.fieldLineage,
      CardField.age => l.fieldAge,
      CardField.birthDate => l.fieldBirthDate,
      CardField.deathDate => l.fieldDeathDate,
      CardField.birthPlace => l.fieldBirthPlace,
      CardField.residence => l.fieldResidence,
      CardField.tribe => l.fieldTribe,
      CardField.kunya => l.fieldKunya,
    };

/// Age text for a person, e.g. "37 years" or "died aged 71".
String? ageText(AppLocalizations l, Person p) {
  final age = p.ageAt();
  if (age == null) return p.isDeceased ? l.deceased : null;
  return p.isDeceased ? l.diedAged(age) : l.ageYears(age);
}

/// Convenience to read the store without listening.
TreeStore treeOf(BuildContext context) => context.read<TreeStore>();
