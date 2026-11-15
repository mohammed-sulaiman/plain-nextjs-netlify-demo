import 'dart:math' as math;

import '../models/models.dart';

const _bio = {ParentKind.biological};
const _bioMilk = {ParentKind.biological, ParentKind.milk};
const _all = {ParentKind.biological, ParentKind.adoptive, ParentKind.milk};

/// A path between two persons through their closest common ancestor.
class BloodPath {
  /// Ids from A up to the common ancestor (inclusive on both ends).
  final List<String> pathA;

  /// Ids from B up to the common ancestor (inclusive on both ends).
  final List<String> pathB;

  /// The link kinds used along the path.
  final Set<ParentKind> kindsUsed;

  const BloodPath(this.pathA, this.pathB, this.kindsUsed);

  String get commonAncestor => pathA.last;
  int get up => pathA.length - 1;
  int get down => pathB.length - 1;
  int get distance => up + down;
  bool get viaMilk => kindsUsed.contains(ParentKind.milk);
  bool get viaAdoption => kindsUsed.contains(ParentKind.adoptive);
}

enum RelationType { self, spouse, blood, spouseOfBlood, bloodOfSpouse, none }

/// Structured description of how B is related to A. Rendering into words is
/// done per language by a `RelationshipNamer` (see relationship_names.dart),
/// which keeps the algorithm independent from any language.
class Relation {
  final RelationType type;
  final String a;
  final String b;

  /// For [RelationType.blood], [RelationType.spouseOfBlood] (A → R) and
  /// [RelationType.bloodOfSpouse] (S → B).
  final BloodPath? path;

  /// The intermediate person: R for spouseOfBlood (B is R's spouse), S for
  /// bloodOfSpouse (S is A's spouse).
  final String? via;

  /// For spouse relations: the union.
  final Union? union;

  const Relation(this.type, this.a, this.b,
      {this.path, this.via, this.union});
}

class KinshipCalculator {
  final FamilyData data;

  KinshipCalculator(this.data);

  /// Shortest ancestor map: ancestor id → path from [id] to that ancestor.
  Map<String, _AncPath> _ancestors(String id, Set<ParentKind> kinds,
      {int maxDepth = 25}) {
    final result = <String, _AncPath>{id: _AncPath([id], const {})};
    var frontier = [id];
    for (var depth = 0; depth < maxDepth && frontier.isNotEmpty; depth++) {
      final next = <String>[];
      for (final x in frontier) {
        for (final l in data.parentLinksOf(x, kinds: kinds)) {
          if (!data.persons.containsKey(l.parentId)) continue;
          if (result.containsKey(l.parentId)) continue;
          final prev = result[x]!;
          result[l.parentId] =
              _AncPath([...prev.ids, l.parentId], {...prev.kinds, l.kind});
          next.add(l.parentId);
        }
      }
      frontier = next;
    }
    return result;
  }

  /// Closest blood path between [a] and [b], preferring biological links.
  BloodPath? bloodPath(String a, String b) {
    return _bloodPath(a, b, _bio) ?? _bloodPath(a, b, _all);
  }

  BloodPath? _bloodPath(String a, String b, Set<ParentKind> kinds) {
    final ancA = _ancestors(a, kinds);
    final ancB = _ancestors(b, kinds);
    BloodPath? best;
    for (final e in ancA.entries) {
      final pb = ancB[e.key];
      if (pb == null) continue;
      final candidate = BloodPath(
          e.value.ids, pb.ids, {...e.value.kinds, ...pb.kinds});
      if (best == null ||
          candidate.distance < best.distance ||
          (candidate.distance == best.distance &&
              candidate.kindsUsed.length < best.kindsUsed.length)) {
        best = candidate;
      }
    }
    return best;
  }

  /// Determines how [b] is related to [a].
  Relation relation(String a, String b) {
    if (a == b) return Relation(RelationType.self, a, b);
    final u = data.unionBetween(a, b);
    if (u != null) return Relation(RelationType.spouse, a, b, union: u);

    final blood = bloodPath(a, b);
    if (blood != null) {
      return Relation(RelationType.blood, a, b, path: blood);
    }

    // B is the spouse of one of A's blood relatives (e.g. brother's wife).
    Relation? best;
    for (final r in data.spousesOf(b)) {
      final p = r == a ? null : bloodPath(a, r);
      if (p == null) continue;
      if (best == null || p.distance < best.path!.distance) {
        best = Relation(RelationType.spouseOfBlood, a, b, path: p, via: r);
      }
    }
    // B is a blood relative of A's spouse (e.g. wife's father).
    for (final s in data.spousesOf(a)) {
      final p = bloodPath(s, b);
      if (p == null) continue;
      if (best == null || p.distance < best.path!.distance) {
        best = Relation(RelationType.bloodOfSpouse, a, b, path: p, via: s);
      }
    }
    return best ?? Relation(RelationType.none, a, b);
  }

  /// Coefficient of relationship (Wright): the expected fraction of DNA
  /// shared by descent, counting every path through common biological
  /// ancestors. Siblings ≈ 0.5, first cousins ≈ 0.125. Consanguineous
  /// marriages in the tree naturally raise the value.
  double coefficientOfRelationship(String a, String b) {
    if (a == b) return 1;
    final pathsA = _allAncestorPaths(a);
    final pathsB = _allAncestorPaths(b);
    var sum = 0.0;
    for (final entry in pathsA.entries) {
      final listB = pathsB[entry.key];
      if (listB == null) continue;
      for (final pa in entry.value) {
        final setA = pa.toSet();
        for (final pb in listB) {
          // Paths may only meet at the common ancestor itself.
          var ok = true;
          for (var i = 0; i < pb.length - 1; i++) {
            if (setA.contains(pb[i])) {
              ok = false;
              break;
            }
          }
          if (!ok) continue;
          sum += math.pow(0.5, (pa.length - 1) + (pb.length - 1));
        }
      }
    }
    return math.min(sum, 1);
  }

  Map<String, List<List<String>>> _allAncestorPaths(String id,
      {int maxDepth = 12, int maxPaths = 5000}) {
    final res = <String, List<List<String>>>{};
    var count = 0;
    void walk(List<String> path) {
      if (count++ > maxPaths) return;
      final x = path.last;
      res.putIfAbsent(x, () => []).add(path);
      if (path.length > maxDepth) return;
      for (final p in data.parentsOf(x, kinds: _bio)) {
        if (path.contains(p)) continue; // guard against cyclic data
        walk([...path, p]);
      }
    }

    walk([id]);
    return res;
  }

  // ---------------------------------------------------------------- Mahram

  Set<String> _ancSet(String id, Set<ParentKind> kinds) =>
      _ancestors(id, kinds).keys.toSet()..remove(id);

  Set<String> _descSet(String id, Set<ParentKind> kinds) {
    final res = <String>{};
    var frontier = [id];
    while (frontier.isNotEmpty) {
      final next = <String>[];
      for (final x in frontier) {
        for (final c in data.childrenOf(x, kinds: kinds)) {
          if (res.add(c)) next.add(c);
        }
      }
      frontier = next;
    }
    res.remove(id);
    return res;
  }

  /// Blood-style mahram rule evaluated over the given link kinds:
  /// ancestors, descendants, descendants of parents (siblings, nephews …)
  /// and children of any ancestor (aunts / uncles of every degree).
  bool _bloodMahram(String a, String b, Set<ParentKind> kinds) {
    final anc = _ancSet(a, kinds);
    if (anc.contains(b)) return true;
    if (_descSet(a, kinds).contains(b)) return true;
    for (final p in data.parentsOf(a, kinds: kinds)) {
      if (_descSet(p, kinds).contains(b)) return true;
    }
    for (final x in anc) {
      if (data.childrenOf(x, kinds: kinds).contains(b)) return true;
    }
    return false;
  }

  MahramResult mahram(String a, String b) {
    final pa = data[a], pb = data[b];
    if (pa == null || pb == null || a == b) {
      return const MahramResult(MahramStatus.notApplicable);
    }
    if (pa.gender == Gender.unknown || pb.gender == Gender.unknown) {
      return const MahramResult(MahramStatus.unknownGender);
    }
    if (pa.gender == pb.gender) {
      return const MahramResult(MahramStatus.sameGender);
    }
    final union = data.unionBetween(a, b);
    if (union != null && union.status == UnionStatus.married) {
      return const MahramResult(MahramStatus.spouse);
    }
    if (_bloodMahram(a, b, _bio)) {
      return const MahramResult(MahramStatus.mahram, reason: MahramReason.blood);
    }
    if (_bloodMahram(a, b, _bioMilk)) {
      return const MahramResult(MahramStatus.mahram, reason: MahramReason.milk);
    }

    // Marriage (مصاهرة) – contracts create permanent prohibition even after
    // divorce or death, except step-children which need consummation.
    final ancA = _ancSet(a, _bioMilk);
    final descA = _descSet(a, _bioMilk);
    final aIsMale = pa.gender == Gender.male;

    // B married one of A's ancestors (step-parent).
    for (final x in ancA) {
      if (data.spousesOf(x).contains(b)) {
        // A man is mahram to his father's wife by contract; a woman is
        // mahram to her mother's husband only after consummation.
        return MahramResult(MahramStatus.mahram,
            reason: MahramReason.marriage, requiresConsummation: !aIsMale);
      }
    }
    // B married one of A's descendants (son's wife / daughter's husband).
    for (final x in descA) {
      if (data.spousesOf(x).contains(b)) {
        return const MahramResult(MahramStatus.mahram,
            reason: MahramReason.marriage);
      }
    }
    for (final s in data.spousesOf(a)) {
      // B is an ancestor of A's spouse (mother/father-in-law).
      if (_ancSet(s, _bioMilk).contains(b)) {
        return const MahramResult(MahramStatus.mahram,
            reason: MahramReason.marriage);
      }
      // B is a descendant of A's spouse (step-child).
      if (_descSet(s, _bioMilk).contains(b)) {
        return MahramResult(MahramStatus.mahram,
            reason: MahramReason.marriage, requiresConsummation: aIsMale);
      }
    }
    if (union != null) {
      // Former spouse (divorced / widowed) and no other permanent tie.
      return const MahramResult(MahramStatus.formerSpouse);
    }
    return const MahramResult(MahramStatus.notMahram);
  }
}

class _AncPath {
  final List<String> ids;
  final Set<ParentKind> kinds;
  const _AncPath(this.ids, this.kinds);
}

enum MahramStatus {
  mahram,
  notMahram,
  spouse,
  formerSpouse,
  sameGender,
  unknownGender,
  notApplicable,
}

enum MahramReason { blood, milk, marriage }

class MahramResult {
  final MahramStatus status;
  final MahramReason? reason;
  final bool requiresConsummation;

  const MahramResult(this.status,
      {this.reason, this.requiresConsummation = false});
}
