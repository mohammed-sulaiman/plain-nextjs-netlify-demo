// Core data model of the family tree.
//
// The tree is stored as three flat collections:
//  * [Person]      – an individual.
//  * [Union]       – a marriage between two persons (supports multiple
//                    marriages per person, divorce and widowhood).
//  * [ParentLink]  – a parent → child edge (biological, adoptive or milk /
//                    nursing "رضاعة").
//
// Keeping the graph flat makes it trivial to persist (local JSON or Supabase
// rows) and to export to GEDCOM.

enum Gender { male, female, unknown }

enum ParentKind {
  /// Biological parent (نسب).
  biological,

  /// Adoptive / guardian parent (كفالة / تبنٍّ) – does not create mahram ties.
  adoptive,

  /// Milk / nursing parent (رضاعة) – creates mahram ties.
  milk,
}

enum UnionStatus { married, divorced, widowed }

DateTime? _date(dynamic v) =>
    v == null || v == '' ? null : DateTime.tryParse(v as String);
String? _dateStr(DateTime? d) => d?.toIso8601String().substring(0, 10);

T _enum<T extends Enum>(List<T> values, dynamic name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

class Residence {
  final String place;
  final double? lat;
  final double? lng;
  final DateTime? from;
  final DateTime? to;

  const Residence({
    required this.place,
    this.lat,
    this.lng,
    this.from,
    this.to,
  });

  bool get hasLocation => lat != null && lng != null;

  Residence copyWith({
    String? place,
    double? lat,
    double? lng,
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearLocation = false,
  }) =>
      Residence(
        place: place ?? this.place,
        lat: clearLocation ? null : (lat ?? this.lat),
        lng: clearLocation ? null : (lng ?? this.lng),
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
      );

  Map<String, dynamic> toJson() => {
        'place': place,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (from != null) 'from': _dateStr(from),
        if (to != null) 'to': _dateStr(to),
      };

  factory Residence.fromJson(Map<String, dynamic> j) => Residence(
        place: j['place'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        from: _date(j['from']),
        to: _date(j['to']),
      );
}

class Person {
  final String id;

  /// Given name (الاسم الأول).
  final String givenName;

  /// Family / last name (اسم العائلة).
  final String familyName;

  /// Kunya, e.g. "أبو محمد" (الكنية).
  final String kunya;

  /// Nickname / title (اللقب).
  final String nickname;

  /// Tribe / clan (القبيلة / العشيرة).
  final String tribe;

  final Gender gender;
  final DateTime? birthDate;
  final String birthPlace;
  final bool deceased;
  final DateTime? deathDate;

  /// Residences in chronological order; the last one with no `to` date is the
  /// current residence.
  final List<Residence> residences;

  /// Photo reference: `data:` URI (local), `http(s)://` URL, or
  /// `storage:<path>` (Supabase storage object).
  final String? photo;

  /// Explicit consent to use the photo for face similarity comparison.
  final bool faceConsent;

  final String notes;

  const Person({
    required this.id,
    required this.givenName,
    this.familyName = '',
    this.kunya = '',
    this.nickname = '',
    this.tribe = '',
    this.gender = Gender.unknown,
    this.birthDate,
    this.birthPlace = '',
    this.deceased = false,
    this.deathDate,
    this.residences = const [],
    this.photo,
    this.faceConsent = false,
    this.notes = '',
  });

  bool get isDeceased => deceased || deathDate != null;

  String get displayName =>
      [givenName, familyName].where((s) => s.trim().isNotEmpty).join(' ');

  Residence? get currentResidence {
    if (residences.isEmpty) return null;
    final open = residences.where((r) => r.to == null).toList();
    return open.isNotEmpty ? open.last : residences.last;
  }

  /// Age in whole years at [at] (defaults to today, or death date).
  int? ageAt([DateTime? at]) {
    final b = birthDate;
    if (b == null) return null;
    final end = at ?? deathDate ?? DateTime.now();
    var age = end.year - b.year;
    if (end.month < b.month || (end.month == b.month && end.day < b.day)) {
      age--;
    }
    return age < 0 ? null : age;
  }

  Person copyWith({
    String? givenName,
    String? familyName,
    String? kunya,
    String? nickname,
    String? tribe,
    Gender? gender,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? birthPlace,
    bool? deceased,
    DateTime? deathDate,
    bool clearDeathDate = false,
    List<Residence>? residences,
    String? photo,
    bool clearPhoto = false,
    bool? faceConsent,
    String? notes,
  }) =>
      Person(
        id: id,
        givenName: givenName ?? this.givenName,
        familyName: familyName ?? this.familyName,
        kunya: kunya ?? this.kunya,
        nickname: nickname ?? this.nickname,
        tribe: tribe ?? this.tribe,
        gender: gender ?? this.gender,
        birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
        birthPlace: birthPlace ?? this.birthPlace,
        deceased: deceased ?? this.deceased,
        deathDate: clearDeathDate ? null : (deathDate ?? this.deathDate),
        residences: residences ?? this.residences,
        photo: clearPhoto ? null : (photo ?? this.photo),
        faceConsent: faceConsent ?? this.faceConsent,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'givenName': givenName,
        'familyName': familyName,
        'kunya': kunya,
        'nickname': nickname,
        'tribe': tribe,
        'gender': gender.name,
        'birthDate': _dateStr(birthDate),
        'birthPlace': birthPlace,
        'deceased': deceased,
        'deathDate': _dateStr(deathDate),
        'residences': residences.map((r) => r.toJson()).toList(),
        'photo': photo,
        'faceConsent': faceConsent,
        'notes': notes,
      };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as String,
        givenName: j['givenName'] as String? ?? '',
        familyName: j['familyName'] as String? ?? '',
        kunya: j['kunya'] as String? ?? '',
        nickname: j['nickname'] as String? ?? '',
        tribe: j['tribe'] as String? ?? '',
        gender: _enum(Gender.values, j['gender'], Gender.unknown),
        birthDate: _date(j['birthDate']),
        birthPlace: j['birthPlace'] as String? ?? '',
        deceased: j['deceased'] as bool? ?? false,
        deathDate: _date(j['deathDate']),
        residences: ((j['residences'] as List?) ?? [])
            .map((e) => Residence.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        photo: j['photo'] as String?,
        faceConsent: j['faceConsent'] as bool? ?? false,
        notes: j['notes'] as String? ?? '',
      );
}

class Union {
  final String id;
  final String partnerA;
  final String partnerB;
  final UnionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;

  const Union({
    required this.id,
    required this.partnerA,
    required this.partnerB,
    this.status = UnionStatus.married,
    this.startDate,
    this.endDate,
  });

  bool involves(String personId) =>
      partnerA == personId || partnerB == personId;

  String other(String personId) => partnerA == personId ? partnerB : partnerA;

  Union copyWith({
    UnionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStart = false,
    bool clearEnd = false,
  }) =>
      Union(
        id: id,
        partnerA: partnerA,
        partnerB: partnerB,
        status: status ?? this.status,
        startDate: clearStart ? null : (startDate ?? this.startDate),
        endDate: clearEnd ? null : (endDate ?? this.endDate),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'partnerA': partnerA,
        'partnerB': partnerB,
        'status': status.name,
        'startDate': _dateStr(startDate),
        'endDate': _dateStr(endDate),
      };

  factory Union.fromJson(Map<String, dynamic> j) => Union(
        id: j['id'] as String,
        partnerA: j['partnerA'] as String,
        partnerB: j['partnerB'] as String,
        status: _enum(UnionStatus.values, j['status'], UnionStatus.married),
        startDate: _date(j['startDate']),
        endDate: _date(j['endDate']),
      );
}

class ParentLink {
  final String id;
  final String parentId;
  final String childId;
  final ParentKind kind;

  const ParentLink({
    required this.id,
    required this.parentId,
    required this.childId,
    this.kind = ParentKind.biological,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentId': parentId,
        'childId': childId,
        'kind': kind.name,
      };

  factory ParentLink.fromJson(Map<String, dynamic> j) => ParentLink(
        id: j['id'] as String,
        parentId: j['parentId'] as String,
        childId: j['childId'] as String,
        kind: _enum(ParentKind.values, j['kind'], ParentKind.biological),
      );
}

/// Immutable snapshot of a whole tree with fast lookup helpers.
class FamilyData {
  final Map<String, Person> persons;
  final List<Union> unions;
  final List<ParentLink> links;

  FamilyData({
    Map<String, Person>? persons,
    List<Union>? unions,
    List<ParentLink>? links,
  })  : persons = persons ?? {},
        unions = unions ?? [],
        links = links ?? [];

  bool get isEmpty => persons.isEmpty;

  Person? operator [](String id) => persons[id];

  Iterable<ParentLink> parentLinksOf(String childId,
          {Set<ParentKind>? kinds}) =>
      links.where((l) =>
          l.childId == childId && (kinds == null || kinds.contains(l.kind)));

  Iterable<ParentLink> childLinksOf(String parentId,
          {Set<ParentKind>? kinds}) =>
      links.where((l) =>
          l.parentId == parentId && (kinds == null || kinds.contains(l.kind)));

  List<String> parentsOf(String id, {Set<ParentKind>? kinds}) =>
      parentLinksOf(id, kinds: kinds)
          .map((l) => l.parentId)
          .where(persons.containsKey)
          .toList();

  List<String> childrenOf(String id, {Set<ParentKind>? kinds}) {
    final ids = childLinksOf(id, kinds: kinds)
        .map((l) => l.childId)
        .where(persons.containsKey)
        .toSet()
        .toList();
    ids.sort(compareByBirth);
    return ids;
  }

  String? fatherOf(String id) {
    for (final p in parentsOf(id, kinds: {ParentKind.biological})) {
      if (persons[p]!.gender == Gender.male) return p;
    }
    return null;
  }

  String? motherOf(String id) {
    for (final p in parentsOf(id, kinds: {ParentKind.biological})) {
      if (persons[p]!.gender == Gender.female) return p;
    }
    return null;
  }

  List<Union> unionsOf(String id) {
    final u = unions.where((u) => u.involves(id)).toList();
    u.sort((a, b) => _cmpDate(a.startDate, b.startDate));
    return u;
  }

  List<String> spousesOf(String id) => unionsOf(id)
      .map((u) => u.other(id))
      .where(persons.containsKey)
      .toList();

  Union? unionBetween(String a, String b) {
    for (final u in unions) {
      if (u.involves(a) && u.involves(b)) return u;
    }
    return null;
  }

  /// Siblings sharing at least one biological parent, sorted by birth.
  List<String> siblingsOf(String id) {
    final parents = parentsOf(id, kinds: {ParentKind.biological});
    final s = <String>{};
    for (final p in parents) {
      s.addAll(childrenOf(p, kinds: {ParentKind.biological}));
    }
    s.remove(id);
    final list = s.toList()..sort(compareByBirth);
    return list;
  }

  int compareByBirth(String a, String b) =>
      _cmpDate(persons[a]?.birthDate, persons[b]?.birthDate);

  static int _cmpDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'persons': persons.values.map((p) => p.toJson()).toList(),
        'unions': unions.map((u) => u.toJson()).toList(),
        'links': links.map((l) => l.toJson()).toList(),
      };

  factory FamilyData.fromJson(Map<String, dynamic> j) => FamilyData(
        persons: {
          for (final p in (j['persons'] as List? ?? []))
            (p['id'] as String):
                Person.fromJson(Map<String, dynamic>.from(p as Map)),
        },
        unions: (j['unions'] as List? ?? [])
            .map((u) => Union.fromJson(Map<String, dynamic>.from(u as Map)))
            .toList(),
        links: (j['links'] as List? ?? [])
            .map((l) =>
                ParentLink.fromJson(Map<String, dynamic>.from(l as Map)))
            .toList(),
      );
}
