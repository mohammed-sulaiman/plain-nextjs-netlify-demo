import 'package:uuid/uuid.dart';

import '../models/models.dart';

/// Minimal GEDCOM 5.5.1 import / export (INDI + FAM records), the standard
/// interchange format understood by virtually every genealogy program.
class Gedcom {
  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  static String _date(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static DateTime? parseDate(String? s) {
    if (s == null) return null;
    final cleaned = s
        .toUpperCase()
        .replaceAll(RegExp(r'\b(ABT|ABOUT|EST|CAL|BEF|AFT|CIRCA|C\.)\b'), '')
        .trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    try {
      if (parts.length >= 3) {
        final m = _months.indexOf(parts[1]);
        if (m >= 0) {
          return DateTime(int.parse(parts[2]), m + 1, int.parse(parts[0]));
        }
      }
      if (parts.length == 2) {
        final m = _months.indexOf(parts[0]);
        if (m >= 0) return DateTime(int.parse(parts[1]), m + 1, 1);
      }
      if (parts.length == 1 && parts[0].isNotEmpty) {
        return DateTime(int.parse(parts[0]), 1, 1);
      }
    } catch (_) {}
    return null;
  }

  static String _clean(String s) => s.replaceAll(RegExp(r'[\r\n]+'), ' ');

  // ------------------------------------------------------------ export

  static String export(FamilyData d, {String source = 'FamilyTreeApp'}) {
    final b = StringBuffer();
    void w(int level, String tag, [String? value]) {
      b.write('$level $tag');
      if (value != null && value.isNotEmpty) b.write(' ${_clean(value)}');
      b.write('\n');
    }

    final indiId = <String, String>{};
    var i = 1;
    for (final id in d.persons.keys) {
      indiId[id] = '@I${i++}@';
    }

    // Families: one per union, plus single-parent groups.
    final fams = <_Fam>[];
    for (final u in d.unions) {
      if (!d.persons.containsKey(u.partnerA) ||
          !d.persons.containsKey(u.partnerB)) {
        continue;
      }
      final a = d[u.partnerA]!, bb = d[u.partnerB]!;
      final husb = a.gender == Gender.female ? bb.id : a.id;
      final wife = husb == a.id ? bb.id : a.id;
      fams.add(_Fam(husb, wife, u));
    }
    for (final child in d.persons.keys) {
      for (final kind in ParentKind.values) {
        final parents = d.parentsOf(child, kinds: {kind});
        if (parents.isEmpty) continue;
        _Fam? fam;
        for (final f in fams) {
          final fp = {f.husb, f.wife}..remove(null);
          if (fp.length == parents.length && fp.containsAll(parents)) {
            fam = f;
            break;
          }
        }
        if (fam == null) {
          String? husb, wife;
          for (final p in parents) {
            if (d[p]!.gender == Gender.female) {
              wife ??= p;
            } else {
              husb ??= p;
            }
          }
          fam = _Fam(husb, wife, null);
          fams.add(fam);
        }
        fam.children.add(MapEntry(child, kind));
      }
    }
    for (var k = 0; k < fams.length; k++) {
      fams[k].xref = '@F${k + 1}@';
    }

    w(0, 'HEAD');
    w(1, 'SOUR', source);
    w(1, 'GEDC');
    w(2, 'VERS', '5.5.1');
    w(2, 'FORM', 'LINEAGE-LINKED');
    w(1, 'CHAR', 'UTF-8');

    for (final p in d.persons.values) {
      w(0, indiId[p.id]!, 'INDI');
      w(1, 'NAME', '${p.givenName} /${p.familyName}/');
      if (p.givenName.isNotEmpty) w(2, 'GIVN', p.givenName);
      if (p.familyName.isNotEmpty) w(2, 'SURN', p.familyName);
      if (p.nickname.isNotEmpty) w(2, 'NICK', p.nickname);
      if (p.kunya.isNotEmpty) w(1, '_KUNYA', p.kunya);
      if (p.tribe.isNotEmpty) w(1, '_TRIBE', p.tribe);
      w(1, 'SEX', switch (p.gender) {
        Gender.male => 'M',
        Gender.female => 'F',
        Gender.unknown => 'U',
      });
      if (p.birthDate != null || p.birthPlace.isNotEmpty) {
        w(1, 'BIRT');
        if (p.birthDate != null) w(2, 'DATE', _date(p.birthDate!));
        if (p.birthPlace.isNotEmpty) w(2, 'PLAC', p.birthPlace);
      }
      if (p.isDeceased) {
        w(1, 'DEAT', p.deathDate == null ? 'Y' : null);
        if (p.deathDate != null) w(2, 'DATE', _date(p.deathDate!));
      }
      for (final r in p.residences) {
        w(1, 'RESI');
        if (r.from != null || r.to != null) {
          final from = r.from != null ? _date(r.from!) : null;
          final to = r.to != null ? _date(r.to!) : null;
          w(2, 'DATE', from != null && to != null
              ? 'FROM $from TO $to'
              : from != null
                  ? 'FROM $from'
                  : 'TO $to');
        }
        w(2, 'PLAC', r.place);
        if (r.hasLocation) {
          w(3, 'MAP');
          w(4, 'LATI', '${r.lat! >= 0 ? 'N' : 'S'}${r.lat!.abs()}');
          w(4, 'LONG', '${r.lng! >= 0 ? 'E' : 'W'}${r.lng!.abs()}');
        }
      }
      if (p.photo != null && p.photo!.startsWith('http')) {
        w(1, 'OBJE');
        w(2, 'FILE', p.photo);
      }
      if (p.notes.isNotEmpty) w(1, 'NOTE', p.notes);
      for (final f in fams) {
        if (f.husb == p.id || f.wife == p.id) w(1, 'FAMS', f.xref);
        for (final c in f.children) {
          if (c.key == p.id) {
            w(1, 'FAMC', f.xref);
            if (c.value == ParentKind.adoptive) w(2, 'PEDI', 'adopted');
            if (c.value == ParentKind.milk) w(2, 'PEDI', 'foster');
          }
        }
      }
    }
    for (final f in fams) {
      w(0, f.xref, 'FAM');
      if (f.husb != null) w(1, 'HUSB', indiId[f.husb]);
      if (f.wife != null) w(1, 'WIFE', indiId[f.wife]);
      final u = f.union;
      if (u != null) {
        w(1, 'MARR', u.startDate == null ? 'Y' : null);
        if (u.startDate != null) w(2, 'DATE', _date(u.startDate!));
        if (u.status == UnionStatus.divorced) {
          w(1, 'DIV', u.endDate == null ? 'Y' : null);
          if (u.endDate != null) w(2, 'DATE', _date(u.endDate!));
        }
      }
      for (final c in f.children) {
        w(1, 'CHIL', indiId[c.key]);
      }
    }
    w(0, 'TRLR');
    return b.toString();
  }

  // ------------------------------------------------------------ import

  static FamilyData import(String text) {
    const uuid = Uuid();
    final records = <_Node>[];
    final stack = <_Node>[];
    final lineRe = RegExp(r'^\s*(\d+)\s+(@[^@]+@\s+)?(\S+)(?:\s(.*))?$');
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.replaceFirst('﻿', '');
      final m = lineRe.firstMatch(line);
      if (m == null) continue;
      final level = int.parse(m.group(1)!);
      final node = _Node(level, m.group(2)?.trim(), m.group(3)!,
          m.group(4)?.trim() ?? '');
      while (stack.isNotEmpty && stack.last.level >= level) {
        stack.removeLast();
      }
      if (level == 0) {
        records.add(node);
      } else if (stack.isNotEmpty) {
        final parent = stack.last;
        if (node.tag == 'CONC') {
          parent.value += node.value;
          continue;
        }
        if (node.tag == 'CONT') {
          parent.value += '\n${node.value}';
          continue;
        }
        parent.children.add(node);
      }
      stack.add(node);
    }

    final idMap = <String, String>{};
    final persons = <String, Person>{};
    for (final r in records.where((r) => r.tag == 'INDI' && r.xref != null)) {
      final id = uuid.v4();
      idMap[r.xref!] = id;
      final nameNode = r.child('NAME');
      var given = nameNode?.child('GIVN')?.value ?? '';
      var surname = nameNode?.child('SURN')?.value ?? '';
      if (nameNode != null && given.isEmpty && surname.isEmpty) {
        final mm = RegExp(r'^([^/]*)/?([^/]*)/?').firstMatch(nameNode.value);
        given = mm?.group(1)?.trim() ?? nameNode.value;
        surname = mm?.group(2)?.trim() ?? '';
      }
      final sex = r.child('SEX')?.value.toUpperCase();
      final birt = r.child('BIRT');
      final deat = r.child('DEAT');
      final residences = <Residence>[];
      for (final res in r.all('RESI')) {
        final dateStr = res.child('DATE')?.value ?? '';
        final fm = RegExp(r'FROM\s+(.+?)(\s+TO|$)').firstMatch(dateStr);
        final tm = RegExp(r'TO\s+(.+)$').firstMatch(dateStr);
        final plac = res.child('PLAC');
        final map = plac?.child('MAP');
        double? coord(String? v) {
          if (v == null || v.isEmpty) return null;
          final sign = 'SW'.contains(v[0]) ? -1 : 1;
          final n = double.tryParse(v.replaceAll(RegExp(r'[NSEW]'), ''));
          return n == null ? null : sign * n;
        }

        residences.add(Residence(
          place: plac?.value ?? res.value,
          from: parseDate(fm?.group(1)),
          to: parseDate(tm?.group(1)),
          lat: coord(map?.child('LATI')?.value),
          lng: coord(map?.child('LONG')?.value),
        ));
      }
      final photo = r.child('OBJE')?.child('FILE')?.value;
      persons[id] = Person(
        id: id,
        givenName: given,
        familyName: surname,
        nickname: nameNode?.child('NICK')?.value ?? '',
        kunya: r.child('_KUNYA')?.value ?? '',
        tribe: r.child('_TRIBE')?.value ?? '',
        gender: sex == 'M'
            ? Gender.male
            : sex == 'F'
                ? Gender.female
                : Gender.unknown,
        birthDate: parseDate(birt?.child('DATE')?.value),
        birthPlace: birt?.child('PLAC')?.value ?? '',
        deceased: deat != null,
        deathDate: parseDate(deat?.child('DATE')?.value),
        residences: residences,
        photo: photo != null && photo.startsWith('http') ? photo : null,
        notes: r.all('NOTE').map((n) => n.value).join('\n'),
      );
    }

    // Pedigree types are declared on the child's FAMC line.
    final pedi = <String, ParentKind>{}; // "famXref|childXref" → kind
    for (final r in records.where((r) => r.tag == 'INDI')) {
      for (final famc in r.all('FAMC')) {
        final v = famc.child('PEDI')?.value.toLowerCase();
        if (v == 'adopted') pedi['${famc.value}|${r.xref}'] = ParentKind.adoptive;
        if (v == 'foster') pedi['${famc.value}|${r.xref}'] = ParentKind.milk;
      }
    }

    final unions = <Union>[];
    final links = <ParentLink>[];
    for (final f in records.where((r) => r.tag == 'FAM')) {
      final h = idMap[f.child('HUSB')?.value];
      final wv = idMap[f.child('WIFE')?.value];
      if (h != null && wv != null) {
        final div = f.child('DIV');
        unions.add(Union(
          id: uuid.v4(),
          partnerA: h,
          partnerB: wv,
          status: div != null ? UnionStatus.divorced : UnionStatus.married,
          startDate: parseDate(f.child('MARR')?.child('DATE')?.value),
          endDate: parseDate(div?.child('DATE')?.value),
        ));
      }
      for (final c in f.all('CHIL')) {
        final cid = idMap[c.value];
        if (cid == null) continue;
        final kind = pedi['${f.xref}|${c.value}'] ?? ParentKind.biological;
        for (final p in [h, wv].whereType<String>()) {
          links.add(ParentLink(
              id: uuid.v4(), parentId: p, childId: cid, kind: kind));
        }
      }
    }
    return FamilyData(persons: persons, unions: unions, links: links);
  }
}

class _Fam {
  final String? husb;
  final String? wife;
  final Union? union;
  final children = <MapEntry<String, ParentKind>>[];
  String xref = '';
  _Fam(this.husb, this.wife, this.union);
}

class _Node {
  final int level;
  final String? xref;
  final String tag;
  String value;
  final children = <_Node>[];
  _Node(this.level, this.xref, this.tag, this.value);

  _Node? child(String tag) {
    for (final c in children) {
      if (c.tag == tag) return c;
    }
    return null;
  }

  Iterable<_Node> all(String tag) => children.where((c) => c.tag == tag);
}
