import 'package:uuid/uuid.dart';

import '../models/models.dart';

/// A small demo family covering the interesting cases: three generations,
/// cousins, a second marriage, a milk (nursing) relationship and residences
/// with coordinates for the map.
FamilyData sampleFamily() {
  const uuid = Uuid();
  final persons = <String, Person>{};
  final unions = <Union>[];
  final links = <ParentLink>[];

  const damascus = Residence(place: 'دمشق', lat: 33.5138, lng: 36.2765);
  const amman = Residence(place: 'عمّان', lat: 31.9539, lng: 35.9106);
  const dubai = Residence(place: 'دبي', lat: 25.2048, lng: 55.2708);
  const riyadh = Residence(place: 'الرياض', lat: 24.7136, lng: 46.6753);

  String add(String name, Gender g, int? year,
      {String family = 'الحسني',
      int? death,
      List<Residence> res = const [],
      String kunya = '',
      String tribe = ''}) {
    final id = uuid.v4();
    persons[id] = Person(
      id: id,
      givenName: name,
      familyName: family,
      gender: g,
      kunya: kunya,
      tribe: tribe,
      birthDate: year == null ? null : DateTime(year, 3, 14),
      deathDate: death == null ? null : DateTime(death, 9, 2),
      deceased: death != null,
      birthPlace: res.isNotEmpty ? res.first.place : '',
      residences: res,
    );
    return id;
  }

  void marry(String a, String b, int? year,
      {UnionStatus status = UnionStatus.married}) {
    unions.add(Union(
      id: uuid.v4(),
      partnerA: a,
      partnerB: b,
      status: status,
      startDate: year == null ? null : DateTime(year, 6, 1),
    ));
  }

  void child(String c, List<String> parents,
      {ParentKind kind = ParentKind.biological}) {
    for (final p in parents) {
      links.add(ParentLink(id: uuid.v4(), parentId: p, childId: c, kind: kind));
    }
  }

  const m = Gender.male, f = Gender.female;

  final hasan = add('حسن', m, 1905, death: 1980, res: [damascus], tribe: 'بني هاشم');
  final ali = add('علي', m, 1930,
      death: 2001, res: [damascus], kunya: 'أبو محمد', tribe: 'بني هاشم');
  final fatima = add('فاطمة', f, 1935, family: 'العمري', res: [damascus]);
  child(ali, [hasan]);
  marry(ali, fatima, 1953);

  final mohammed = add('محمد', m, 1955,
      res: [damascus, amman.copyWith(from: DateTime(1990))], kunya: 'أبو أحمد');
  final khadija = add('خديجة', f, 1960, family: 'الشامي', res: [amman]);
  final sara = add('سارة', f, 1958, res: [damascus]);
  final omar = add('عمر', m, 1962, res: [riyadh]);
  for (final c in [mohammed, sara, omar]) {
    child(c, [ali, fatima]);
  }
  marry(mohammed, khadija, 1983);

  final yousef = add('يوسف', m, 1954, family: 'الخطيب', res: [damascus]);
  marry(sara, yousef, 1980);
  final hala = add('هالة', f, 1984, family: 'الخطيب', res: [dubai]);
  child(hala, [sara, yousef]);

  final ahmed = add('أحمد', m, 1985,
      res: [amman, dubai.copyWith(from: DateTime(2010))], kunya: 'أبو يوسف');
  final maryam = add('مريم', f, 1988, res: [amman]);
  final khaled = add('خالد', m, 1992, res: [riyadh]);
  for (final c in [ahmed, maryam, khaled]) {
    child(c, [mohammed, khadija]);
  }
  // Khaled was nursed by his aunt Sara → milk son of Sara and Yousef.
  child(khaled, [sara, yousef], kind: ParentKind.milk);

  final layla = add('ليلى', f, 1989, family: 'النابلسي', res: [dubai]);
  marry(ahmed, layla, 2011);
  final yousefJr = add('يوسف', m, 2012, res: [dubai]);
  final nour = add('نور', f, 2015, res: [dubai]);
  child(yousefJr, [ahmed, layla]);
  child(nour, [ahmed, layla]);

  final noura = add('نورة', f, 1965, family: 'القحطاني', res: [riyadh]);
  marry(omar, noura, 1990);
  final salem = add('سالم', m, 1993, res: [riyadh]);
  child(salem, [omar, noura]);

  // Ali's second marriage.
  final aisha = add('عائشة', f, 1945, family: 'الحلبي', res: [damascus]);
  marry(ali, aisha, 1970);
  final zaid = add('زيد', m, 1972, res: [damascus]);
  child(zaid, [ali, aisha]);

  return FamilyData(persons: persons, unions: unions, links: links);
}
