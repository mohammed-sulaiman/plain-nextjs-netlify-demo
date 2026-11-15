import '../models/models.dart';
import 'kinship.dart';

/// Turns a structured [Relation] into words. Kinship vocabulary differs a lot
/// between languages (Arabic distinguishes paternal/maternal uncles, English
/// counts cousin degrees), so each language gets its own namer. To support a
/// new language, implement [RelationshipNamer] and register it in [forLocale].
abstract class RelationshipNamer {
  String name(Relation r, FamilyData d);

  static RelationshipNamer forLocale(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return ArabicRelationshipNamer();
      default:
        return EnglishRelationshipNamer();
    }
  }
}

bool _male(FamilyData d, String id) => d[id]?.gender != Gender.female;

enum _SiblingKind { full, paternal, maternal, unknown }

_SiblingKind _siblingKind(FamilyData d, String a, String b) {
  final fa = d.fatherOf(a), fb = d.fatherOf(b);
  final ma = d.motherOf(a), mb = d.motherOf(b);
  final sameF = fa != null && fa == fb;
  final sameM = ma != null && ma == mb;
  if (sameF && sameM) return _SiblingKind.full;
  if (sameF && mb != null && ma != null) return _SiblingKind.paternal;
  if (sameM && fb != null && fa != null) return _SiblingKind.maternal;
  return _SiblingKind.unknown;
}

// --------------------------------------------------------------- Arabic

class ArabicRelationshipNamer implements RelationshipNamer {
  @override
  String name(Relation r, FamilyData d) {
    final bm = _male(d, r.b);
    switch (r.type) {
      case RelationType.self:
        return 'نفس الشخص';
      case RelationType.none:
        return 'لا توجد صلة قرابة مسجلة';
      case RelationType.spouse:
        final s = bm ? 'الزوج' : 'الزوجة';
        switch (r.union?.status) {
          case UnionStatus.divorced:
            return bm ? 'الزوج السابق (طلاق)' : 'الزوجة السابقة (طلاق)';
          case UnionStatus.widowed:
            return '$s (ترمّل)';
          default:
            return s;
        }
      case RelationType.blood:
        return _withQualifiers(_blood(r.path!, d, r.b), r.path!);
      case RelationType.spouseOfBlood:
        final rel = r.path!;
        final viaId = r.via!;
        final spouseWord = bm ? 'زوج' : 'زوجة';
        if (rel.up == 0 && rel.down == 1) {
          return bm ? 'زوج الابنة (الصهر)' : 'زوجة الابن (الكنّة)';
        }
        if (rel.up == 1 && rel.down == 0) {
          return bm ? 'زوج الأم' : 'زوجة الأب';
        }
        return '$spouseWord ${_withQualifiers(_blood(rel, d, viaId), rel)}';
      case RelationType.bloodOfSpouse:
        final rel = r.path!;
        final sm = _male(d, r.via!);
        final spouse = sm ? 'الزوج' : 'الزوجة';
        if (rel.up == 1 && rel.down == 0) {
          return bm ? 'والد $spouse (الحمو)' : 'والدة $spouse (الحماة)';
        }
        if (rel.up == 0 && rel.down == 1) {
          return bm ? 'ابن $spouse (الربيب)' : 'ابنة $spouse (الربيبة)';
        }
        if (rel.up == 1 && rel.down == 1) {
          return bm ? 'أخو $spouse' : 'أخت $spouse';
        }
        return '${_withQualifiers(_blood(rel, d, r.b), rel)} لل${spouse.substring(2)}';
    }
  }

  String _withQualifiers(String s, BloodPath p) {
    if (p.viaMilk) return '$s من الرضاعة';
    if (p.viaAdoption) return '$s بالكفالة/التبني';
    return s;
  }

  String _uncle(bool paternal, bool male) => paternal
      ? (male ? 'عم' : 'عمة')
      : (male ? 'خال' : 'خالة');

  String _blood(BloodPath p, FamilyData d, String b) {
    final bm = _male(d, b);
    final up = p.up, down = p.down;
    final paternal = up >= 1 ? _male(d, p.pathA[1]) : true;
    final side = paternal ? 'من جهة الأب' : 'من جهة الأم';

    if (up == 0) {
      if (down == 1) return bm ? 'الابن' : 'الابنة';
      if (down == 2) return bm ? 'الحفيد' : 'الحفيدة';
      if (down == 3) return bm ? 'ابن الحفيد' : 'ابنة الحفيد';
      return bm ? 'حفيد من الجيل $down' : 'حفيدة من الجيل $down';
    }
    if (down == 0) {
      if (up == 1) return bm ? 'الأب' : 'الأم';
      if (up == 2) return bm ? 'الجد $side' : 'الجدة $side';
      if (up == 3) return bm ? 'والد الجد $side' : 'والدة الجد $side';
      return bm ? 'جد أعلى من الجيل $up' : 'جدة عليا من الجيل $up';
    }
    if (up == 1 && down == 1) {
      final base = bm ? 'الأخ' : 'الأخت';
      switch (_siblingKind(d, p.pathA.first, p.pathB.first)) {
        case _SiblingKind.full:
          return bm ? 'الأخ الشقيق' : 'الأخت الشقيقة';
        case _SiblingKind.paternal:
          return '$base لأب';
        case _SiblingKind.maternal:
          return '$base لأم';
        case _SiblingKind.unknown:
          return base;
      }
    }
    final linkMale = _male(d, p.pathB[p.pathB.length - 2]);
    if (up == 1) {
      final sib = linkMale ? 'الأخ' : 'الأخت';
      if (down == 2) return bm ? 'ابن $sib' : 'ابنة $sib';
      if (down == 3) return bm ? 'حفيد $sib' : 'حفيدة $sib';
    }
    if (down == 1) {
      if (up == 2) return 'ال${_uncle(paternal, bm)}';
      if (up == 3) {
        final grandPaternal = _male(d, p.pathA[2]);
        return '${_uncle(grandPaternal, bm)} ${paternal ? 'الأب' : 'الأم'}';
      }
    }
    if (up == 2 && down == 2) {
      return '${bm ? 'ابن' : 'ابنة'} ال${_uncle(paternal, linkMale)}';
    }
    if (up == 2 && down == 3) {
      return '${bm ? 'حفيد' : 'حفيدة'} ال${_uncle(paternal, linkMale)}';
    }
    if (up == 3 && down == 2) {
      final grandPaternal = _male(d, p.pathA[2]);
      return '${bm ? 'ابن' : 'ابنة'} ${_uncle(grandPaternal, linkMale)} ${paternal ? 'الأب' : 'الأم'}';
    }
    final ca = d[p.commonAncestor]?.displayName ?? '';
    return '${bm ? 'قريب' : 'قريبة'} — يلتقيان في الجد المشترك $ca '
        '($up أجيال للأعلى، $down للأسفل)';
  }
}

// -------------------------------------------------------------- English

class EnglishRelationshipNamer implements RelationshipNamer {
  @override
  String name(Relation r, FamilyData d) {
    final bm = _male(d, r.b);
    switch (r.type) {
      case RelationType.self:
        return 'Same person';
      case RelationType.none:
        return 'No recorded relationship';
      case RelationType.spouse:
        final s = bm ? 'husband' : 'wife';
        switch (r.union?.status) {
          case UnionStatus.divorced:
            return 'Former $s (divorced)';
          case UnionStatus.widowed:
            return '${_cap(s)} (widowed)';
          default:
            return _cap(s);
        }
      case RelationType.blood:
        return _cap(_q(_blood(r.path!, d, r.b), r.path!));
      case RelationType.spouseOfBlood:
        final p = r.path!;
        if (p.up == 0 && p.down == 1) {
          return bm ? 'Son-in-law' : 'Daughter-in-law';
        }
        if (p.up == 1 && p.down == 0) return bm ? 'Stepfather' : 'Stepmother';
        if (p.up == 1 && p.down == 1) {
          return bm ? 'Brother-in-law' : 'Sister-in-law';
        }
        return _cap("${_q(_blood(p, d, r.via!, withSide: false), p)}'s ${bm ? 'husband' : 'wife'}");
      case RelationType.bloodOfSpouse:
        final p = r.path!;
        if (p.up == 1 && p.down == 0) {
          return bm ? 'Father-in-law' : 'Mother-in-law';
        }
        if (p.up == 0 && p.down == 1) return bm ? 'Stepson' : 'Stepdaughter';
        if (p.up == 1 && p.down == 1) {
          return bm ? 'Brother-in-law' : 'Sister-in-law';
        }
        final spouse = _male(d, r.via!) ? 'husband' : 'wife';
        return _cap("$spouse's ${_q(_blood(p, d, r.b, withSide: false), p)}");
    }
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _q(String s, BloodPath p) {
    if (p.viaMilk) return 'milk $s';
    if (p.viaAdoption) return 'adoptive $s';
    return s;
  }

  String _greats(int n) => n <= 0 ? '' : List.filled(n, 'great-').join();

  String _ordinal(int n) {
    const names = ['', 'first', 'second', 'third', 'fourth', 'fifth'];
    if (n < names.length) return names[n];
    return '${n}th';
  }

  String _blood(BloodPath p, FamilyData d, String b, {bool withSide = true}) {
    final bm = _male(d, b);
    final up = p.up, down = p.down;
    final side = up >= 1 && withSide
        ? (_male(d, p.pathA[1]) ? ' (paternal)' : ' (maternal)')
        : '';
    if (up == 0) {
      if (down == 1) return bm ? 'son' : 'daughter';
      return '${_greats(down - 2)}grand${bm ? 'son' : 'daughter'}';
    }
    if (down == 0) {
      if (up == 1) return bm ? 'father' : 'mother';
      return '${_greats(up - 2)}grand${bm ? 'father' : 'mother'}$side';
    }
    if (up == 1 && down == 1) {
      final base = bm ? 'brother' : 'sister';
      switch (_siblingKind(d, p.pathA.first, p.pathB.first)) {
        case _SiblingKind.paternal:
          return 'half-$base (paternal)';
        case _SiblingKind.maternal:
          return 'half-$base (maternal)';
        default:
          return base;
      }
    }
    if (up == 1) {
      final base = bm ? 'nephew' : 'niece';
      return down == 2 ? base : '${_greats(down - 3)}grand$base';
    }
    if (down == 1) {
      final base = bm ? 'uncle' : 'aunt';
      return up == 2 ? '$base$side' : '${_greats(up - 2)}$base$side';
    }
    final degree = (up < down ? up : down) - 1;
    final removed = (up - down).abs();
    final removedStr = removed == 0
        ? ''
        : removed == 1
            ? ' once removed'
            : removed == 2
                ? ' twice removed'
                : ' $removed times removed';
    return '${_ordinal(degree)} cousin$removedStr$side';
  }
}
