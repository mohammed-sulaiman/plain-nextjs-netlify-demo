import '../models/models.dart';

/// Builds the Arabic-style lineage (النسب): "أحمد بن محمد بن علي الفلاني".
///
/// [sonWord] / [daughterWord] are localized connectors ("بن"/"بنت" or
/// "bin"/"bint"). Only the first connector depends on the person's gender;
/// further ancestors along the paternal line are always male.
String lineage(
  FamilyData d,
  String id, {
  required String sonWord,
  required String daughterWord,
  int depth = 4,
  bool includeFamilyName = true,
}) {
  final p = d[id];
  if (p == null) return '';
  final parts = <String>[p.givenName];
  var current = id;
  for (var i = 0; i < depth; i++) {
    final f = d.fatherOf(current);
    if (f == null) break;
    final connector =
        i == 0 && p.gender == Gender.female ? daughterWord : sonWord;
    parts.add('$connector ${d[f]!.givenName}');
    current = f;
  }
  // Use the family name of the most distant known paternal ancestor if the
  // person has none.
  var family = p.familyName;
  if (family.isEmpty) family = d[current]?.familyName ?? '';
  if (includeFamilyName && family.isNotEmpty) parts.add(family);
  return parts.join(' ');
}

/// The paternal line from the person up to the earliest known ancestor.
List<String> paternalLine(FamilyData d, String id, {int maxDepth = 50}) {
  final line = <String>[id];
  var current = id;
  for (var i = 0; i < maxDepth; i++) {
    final f = d.fatherOf(current);
    if (f == null || line.contains(f)) break;
    line.add(f);
    current = f;
  }
  return line;
}
