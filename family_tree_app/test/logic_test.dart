import 'package:family_tree/data/sample_data.dart';
import 'package:family_tree/logic/gedcom.dart';
import 'package:family_tree/logic/kinship.dart';
import 'package:family_tree/logic/lineage.dart';
import 'package:family_tree/logic/relationship_names.dart';
import 'package:family_tree/logic/tree_layout.dart';
import 'package:family_tree/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FamilyData d;
  late KinshipCalculator k;
  final ar = ArabicRelationshipNamer();
  final en = EnglishRelationshipNamer();

  String id(String given, [String family = 'الحسني']) => d.persons.values
      .lastWhere((p) => p.givenName == given && p.familyName == family)
      .id;

  setUp(() {
    d = sampleFamily();
    k = KinshipCalculator(d);
  });

  group('relationship names', () {
    String nameAr(String a, String b) => ar.name(k.relation(a, b), d);
    String nameEn(String a, String b) => en.name(k.relation(a, b), d);

    test('direct line', () {
      expect(nameAr(id('أحمد'), id('محمد')), 'الأب');
      expect(nameAr(id('أحمد'), id('علي')), 'الجد من جهة الأب');
      expect(nameAr(id('أحمد'), id('فاطمة', 'العمري')), 'الجدة من جهة الأب');
      expect(nameAr(id('أحمد'), id('خديجة', 'الشامي')), 'الأم');
      expect(nameAr(id('علي'), id('نور')), 'ابنة الحفيد');
      expect(nameEn(id('أحمد'), id('حسن')), 'Great-grandfather (paternal)');
      expect(nameEn(id('حسن'), id('نور')), 'Great-great-granddaughter');
    });

    test('siblings, half siblings, uncles and cousins', () {
      expect(nameAr(id('أحمد'), id('مريم')), 'الأخت الشقيقة');
      expect(nameAr(id('محمد'), id('زيد')), 'الأخ لأب');
      expect(nameEn(id('محمد'), id('زيد')), 'Half-brother (paternal)');
      expect(nameAr(id('أحمد'), id('عمر')), 'العم');
      expect(nameAr(id('أحمد'), id('سارة')), 'العمة');
      expect(nameAr(id('أحمد'), id('هالة', 'الخطيب')), 'ابنة العمة');
      expect(nameAr(id('أحمد'), id('سالم')), 'ابن العم');
      expect(nameAr(id('هالة', 'الخطيب'), id('أحمد')), 'ابن الخال');
      expect(nameEn(id('أحمد'), id('سالم')), 'First cousin (paternal)');
      expect(nameEn(id('يوسف'), id('سالم')), 'First cousin once removed (paternal)');
      expect(nameAr(id('عمر'), id('يوسف')), 'حفيد الأخ');
    });

    test('marriage and in-laws', () {
      expect(nameAr(id('أحمد'), id('ليلى', 'النابلسي')), 'الزوجة');
      expect(nameAr(id('محمد'), id('ليلى', 'النابلسي')), 'زوجة الابن (الكنّة)');
      expect(nameAr(id('ليلى', 'النابلسي'), id('محمد')), 'والد الزوج (الحمو)');
      expect(nameAr(id('محمد'), id('عائشة', 'الحلبي')), 'زوجة الأب');
      expect(nameEn(id('أحمد'), id('يوسف', 'الخطيب')), "Aunt's husband");
    });
  });

  group('genetic relatedness', () {
    test('standard coefficients', () {
      expect(k.coefficientOfRelationship(id('أحمد'), id('محمد')), 0.5);
      expect(k.coefficientOfRelationship(id('أحمد'), id('مريم')), 0.5);
      expect(k.coefficientOfRelationship(id('محمد'), id('زيد')), 0.25);
      expect(k.coefficientOfRelationship(id('أحمد'), id('عمر')), 0.25);
      expect(k.coefficientOfRelationship(id('أحمد'), id('سالم')), 0.125);
      expect(k.coefficientOfRelationship(id('أحمد'), id('ليلى', 'النابلسي')), 0);
    });

    test('milk links do not count genetically', () {
      // Khaled is Sara's milk son but her nephew by blood (0.25).
      expect(k.coefficientOfRelationship(id('خالد'), id('سارة')), 0.25);
    });
  });

  group('mahram', () {
    MahramResult m(String a, String b) => k.mahram(a, b);

    test('blood', () {
      final r = m(id('أحمد'), id('سارة'));
      expect(r.status, MahramStatus.mahram);
      expect(r.reason, MahramReason.blood);
      expect(m(id('أحمد'), id('هالة', 'الخطيب')).status, MahramStatus.notMahram);
      expect(m(id('أحمد'), id('نور')).reason, MahramReason.blood);
    });

    test('milk', () {
      // Hala (Sara's daughter) is Khaled's milk sister.
      final r = m(id('خالد'), id('هالة', 'الخطيب'));
      expect(r.status, MahramStatus.mahram);
      expect(r.reason, MahramReason.milk);
      // ...but not Ahmed's (Khaled's brother).
      expect(m(id('أحمد'), id('هالة', 'الخطيب')).status, MahramStatus.notMahram);
    });

    test('marriage', () {
      expect(m(id('محمد'), id('ليلى', 'النابلسي')).reason, MahramReason.marriage);
      expect(m(id('ليلى', 'النابلسي'), id('محمد')).reason, MahramReason.marriage);
      final step = m(id('محمد'), id('عائشة', 'الحلبي'));
      expect(step.reason, MahramReason.marriage);
      expect(step.requiresConsummation, isFalse);
      expect(m(id('أحمد'), id('ليلى', 'النابلسي')).status, MahramStatus.spouse);
      expect(m(id('أحمد'), id('محمد')).status, MahramStatus.sameGender);
    });
  });

  test('lineage', () {
    expect(lineage(d, id('نور'), sonWord: 'بن', daughterWord: 'بنت'),
        'نور بنت أحمد بن محمد بن علي بن حسن الحسني');
    expect(
        lineage(d, id('أحمد'),
            sonWord: 'bin', daughterWord: 'bint', depth: 1, includeFamilyName: false),
        'أحمد bin محمد');
  });

  test('GEDCOM round trip keeps people, marriages and links', () {
    final text = Gedcom.export(d);
    expect(text, contains('0 HEAD'));
    expect(text, contains('2 PEDI foster'));
    final back = Gedcom.import(text);
    expect(back.persons.length, d.persons.length);
    expect(back.unions.length, d.unions.length);
    expect(back.links.length, d.links.length);
    expect(back.links.where((l) => l.kind == ParentKind.milk).length, 2);
    final noor = back.persons.values.firstWhere((p) => p.givenName == 'نور');
    expect(noor.birthDate, DateTime(2015, 3, 14));
    expect(noor.residences.first.lat, closeTo(25.2048, 1e-6));
    final k2 = KinshipCalculator(back);
    final ahmed = back.persons.values
        .lastWhere((p) => p.givenName == 'أحمد');
    final salem = back.persons.values.firstWhere((p) => p.givenName == 'سالم');
    expect(ar.name(k2.relation(ahmed.id, salem.id), back), 'ابن العم');
  });

  test('GEDCOM import of a foreign file', () {
    const ged = '''
0 HEAD
1 CHAR UTF-8
0 @I1@ INDI
1 NAME John /Smith/
1 SEX M
1 BIRT
2 DATE ABT 1950
0 @I2@ INDI
1 NAME Mary /Jones/
1 SEX F
0 @I3@ INDI
1 NAME Ann /Smith/
1 SEX F
1 BIRT
2 DATE 3 FEB 1980
2 PLAC London
0 @F1@ FAM
1 HUSB @I1@
1 WIFE @I2@
1 MARR
2 DATE JUN 1975
1 CHIL @I3@
0 TRLR
''';
    final g = Gedcom.import(ged);
    expect(g.persons.length, 3);
    final ann = g.persons.values.firstWhere((p) => p.givenName == 'Ann');
    expect(ann.familyName, 'Smith');
    expect(ann.birthPlace, 'London');
    expect(ann.birthDate, DateTime(1980, 2, 3));
    expect(g.parentsOf(ann.id).length, 2);
    expect(g.unions.single.startDate, DateTime(1975, 6, 1));
  });

  group('layout', () {
    test('no overlapping cards and generations stacked', () {
      for (final focus in d.persons.keys) {
        final layout = TreeLayoutEngine(d,
                scope: const TreeScope(showUnclesAunts: true))
            .layout(focus);
        expect(layout.positions.containsKey(focus), isTrue);
        final rects = layout.positions.keys.map(layout.rectOf).toList();
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            expect(rects[i].overlaps(rects[j]), isFalse,
                reason: 'cards overlap with focus ${d[focus]!.givenName}');
          }
        }
        for (final e in layout.familyEdges) {
          for (final p in e.parents) {
            expect(layout.positions[p]!.dy < layout.positions[e.child]!.dy,
                isTrue);
          }
        }
      }
    });

    test('focus shows parents, siblings, spouse and children', () {
      final layout = TreeLayoutEngine(d).layout(id('أحمد'));
      for (final who in [
        id('محمد'),
        id('خديجة', 'الشامي'),
        id('مريم'),
        id('خالد'),
        id('ليلى', 'النابلسي'),
        id('نور'),
        id('حسن'),
      ]) {
        expect(layout.positions.containsKey(who), isTrue);
      }
      expect(layout.generation[id('نور')], 1);
      expect(layout.generation[id('علي')], -2);
    });

    test('RTL mirrors horizontally', () {
      final ltr = TreeLayoutEngine(d).layout(id('أحمد'));
      final rtl = TreeLayoutEngine(d).layout(id('أحمد'), rtl: true);
      final a = id('محمد');
      expect(rtl.positions[a]!.dx,
          closeTo(ltr.size.width - ltr.positions[a]!.dx - ltr.cardSize.width, 1e-6));
    });
  });
}
