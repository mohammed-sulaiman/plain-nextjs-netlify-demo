import 'dart:math' as math;
import 'dart:ui';

import '../models/models.dart';

/// What part of the family to show around the focus person.
class TreeScope {
  final int ancestorDepth;
  final int descendantDepth;
  final bool showSiblings;
  final bool showUnclesAunts;
  final bool showSpouses;

  const TreeScope({
    this.ancestorDepth = 3,
    this.descendantDepth = 3,
    this.showSiblings = true,
    this.showUnclesAunts = false,
    this.showSpouses = true,
  });

  TreeScope copyWith({
    int? ancestorDepth,
    int? descendantDepth,
    bool? showSiblings,
    bool? showUnclesAunts,
    bool? showSpouses,
  }) =>
      TreeScope(
        ancestorDepth: ancestorDepth ?? this.ancestorDepth,
        descendantDepth: descendantDepth ?? this.descendantDepth,
        showSiblings: showSiblings ?? this.showSiblings,
        showUnclesAunts: showUnclesAunts ?? this.showUnclesAunts,
        showSpouses: showSpouses ?? this.showSpouses,
      );

  Map<String, dynamic> toJson() => {
        'ancestorDepth': ancestorDepth,
        'descendantDepth': descendantDepth,
        'showSiblings': showSiblings,
        'showUnclesAunts': showUnclesAunts,
        'showSpouses': showSpouses,
      };

  factory TreeScope.fromJson(Map<String, dynamic> j) => TreeScope(
        ancestorDepth: j['ancestorDepth'] as int? ?? 3,
        descendantDepth: j['descendantDepth'] as int? ?? 3,
        showSiblings: j['showSiblings'] as bool? ?? true,
        showUnclesAunts: j['showUnclesAunts'] as bool? ?? false,
        showSpouses: j['showSpouses'] as bool? ?? true,
      );
}

class SpouseEdge {
  final String a;
  final String b;
  final UnionStatus status;
  const SpouseEdge(this.a, this.b, this.status);
}

/// Connects one child to its visible parents (one or two).
class FamilyEdge {
  final List<String> parents;
  final String child;
  final ParentKind kind;
  const FamilyEdge(this.parents, this.child, this.kind);
}

class TreeLayout {
  final Map<String, Offset> positions; // top-left of each card
  final Map<String, int> generation; // relative to focus
  final Size size;
  final Size cardSize;
  final List<SpouseEdge> spouseEdges;
  final List<FamilyEdge> familyEdges;

  const TreeLayout({
    required this.positions,
    required this.generation,
    required this.size,
    required this.cardSize,
    required this.spouseEdges,
    required this.familyEdges,
  });

  Rect rectOf(String id) => positions[id]! & cardSize;
}

class _Unit {
  final List<String> members; // left → right
  double desired = double.infinity;
  double x = 0; // left
  _Unit(this.members);
}

/// Generational "hourglass" layout centred on a focus person: ancestors
/// above, descendants below, siblings and spouses on the focus row.
class TreeLayoutEngine {
  final FamilyData data;
  final TreeScope scope;
  final Size cardSize;
  final double unitGap;
  final double spouseGap;
  final double rowGap;
  final double margin;

  TreeLayoutEngine(
    this.data, {
    this.scope = const TreeScope(),
    this.cardSize = const Size(150, 120),
    this.unitGap = 48,
    this.spouseGap = 24,
    this.rowGap = 90,
    this.margin = 60,
  });

  TreeLayout layout(String focusId, {bool rtl = false}) {
    final gen = <String, int>{};
    final spouseOnly = <String>{};
    if (data[focusId] == null) {
      return TreeLayout(
          positions: const {},
          generation: const {},
          size: Size.zero,
          cardSize: cardSize,
          spouseEdges: const [],
          familyEdges: const []);
    }
    gen[focusId] = 0;

    // Ancestors.
    var frontier = [focusId];
    for (var d = 1; d <= scope.ancestorDepth; d++) {
      final next = <String>[];
      for (final x in frontier) {
        final kinds = x == focusId ? null : {ParentKind.biological};
        for (final p in data.parentsOf(x, kinds: kinds)) {
          if (gen.containsKey(p)) continue;
          gen[p] = -d;
          next.add(p);
        }
      }
      frontier = next;
    }

    // Siblings and uncles/aunts.
    if (scope.showSiblings) {
      for (final p in data.parentsOf(focusId)) {
        for (final c in data.childrenOf(p)) {
          gen.putIfAbsent(c, () => 0);
        }
      }
    }
    if (scope.showUnclesAunts && scope.ancestorDepth >= 2) {
      for (final p in data.parentsOf(focusId, kinds: {ParentKind.biological})) {
        for (final s in data.siblingsOf(p)) {
          gen.putIfAbsent(s, () => -1);
        }
      }
    }

    // Descendants.
    frontier = [focusId];
    for (var d = 1; d <= scope.descendantDepth; d++) {
      final next = <String>[];
      for (final x in frontier) {
        for (final c in data.childrenOf(x)) {
          if (gen.containsKey(c)) continue;
          gen[c] = d;
          next.add(c);
        }
      }
      frontier = next;
    }

    // Spouses on the same row.
    if (scope.showSpouses) {
      for (final id in gen.keys.toList()) {
        for (final s in data.spousesOf(id)) {
          if (!gen.containsKey(s)) {
            gen[s] = gen[id]!;
            spouseOnly.add(s);
          }
        }
      }
    }

    // Build rows of units (a person with their visible spouses).
    final rows = <int, List<_Unit>>{};
    final assigned = <String>{};
    final rowMembers = <int, List<String>>{};
    for (final e in gen.entries) {
      rowMembers.putIfAbsent(e.value, () => []).add(e.key);
    }
    for (final entry in rowMembers.entries) {
      final ids = entry.value..sort(data.compareByBirth);
      // Blood-line members first so they become the core of their unit.
      ids.sort((a, b) => (spouseOnly.contains(a) ? 1 : 0)
          .compareTo(spouseOnly.contains(b) ? 1 : 0));
      final units = <_Unit>[];
      for (final id in ids) {
        if (assigned.contains(id)) continue;
        assigned.add(id);
        final spouses = data
            .spousesOf(id)
            .where((s) => gen[s] == entry.key && !assigned.contains(s))
            .toList();
        assigned.addAll(spouses);
        final members = <String>[];
        if (spouses.isEmpty) {
          members.add(id);
        } else {
          // husband in the middle of several wives, or simple couple.
          final first = spouses.first;
          final rest = spouses.skip(1);
          final idMale = data[id]!.gender == Gender.male;
          if (spouses.length == 1) {
            members.addAll(idMale ? [id, first] : [first, id]);
          } else {
            members
              ..add(first)
              ..add(id)
              ..addAll(rest);
          }
        }
        units.add(_Unit(members));
      }
      rows[entry.key] = units;
    }

    final positionsX = <String, double>{};
    double unitWidth(_Unit u) =>
        u.members.length * cardSize.width +
        (u.members.length - 1) * spouseGap;
    double centerOf(String id) => positionsX[id]! + cardSize.width / 2;

    void place(List<_Unit> units) {
      units.sort((a, b) => a.desired.compareTo(b.desired));
      var cursor = -double.infinity;
      for (final u in units) {
        final w = unitWidth(u);
        final want =
            u.desired.isFinite ? u.desired - w / 2 : (cursor.isFinite ? cursor : 0);
        u.x = math.max(cursor, want).toDouble();
        cursor = u.x + w + unitGap;
      }
      // Shift the row so that, on average, units sit where they want to be.
      final finite = units.where((u) => u.desired.isFinite).toList();
      if (finite.isNotEmpty) {
        final avg = finite
                .map((u) => u.desired - (u.x + unitWidth(u) / 2))
                .reduce((a, b) => a + b) /
            finite.length;
        for (final u in units) {
          u.x += avg;
        }
      }
      for (final u in units) {
        for (var i = 0; i < u.members.length; i++) {
          positionsX[u.members[i]] =
              u.x + i * (cardSize.width + spouseGap);
        }
      }
    }

    // Focus row: birth order.
    final row0 = rows[0] ?? [];
    var cursor0 = 0.0;
    for (final u in row0) {
      u.x = cursor0;
      for (var i = 0; i < u.members.length; i++) {
        positionsX[u.members[i]] = u.x + i * (cardSize.width + spouseGap);
      }
      cursor0 += unitWidth(u) + unitGap;
      u.desired = u.x + unitWidth(u) / 2;
    }

    final gens = rows.keys.toList()..sort();
    // Rows below: centre under parents.
    for (final g in gens.where((g) => g > 0)) {
      for (final u in rows[g]!) {
        final parentCenters = <double>[];
        for (final m in u.members) {
          for (final p in data.parentsOf(m)) {
            if (positionsX.containsKey(p) && gen[p] == g - 1) {
              parentCenters.add(centerOf(p));
            }
          }
        }
        if (parentCenters.isNotEmpty) {
          u.desired =
              parentCenters.reduce((a, b) => a + b) / parentCenters.length;
        }
      }
      place(rows[g]!);
    }
    // Rows above: centre over children.
    for (final g in gens.where((g) => g < 0).toList().reversed) {
      final units = rows[g]!;
      for (final u in units) {
        final childCenters = <double>[];
        for (final m in u.members) {
          for (final c in data.childrenOf(m)) {
            if (positionsX.containsKey(c) && gen[c] == g + 1) {
              childCenters.add(centerOf(c));
            }
          }
        }
        if (childCenters.isNotEmpty) {
          u.desired =
              childCenters.reduce((a, b) => a + b) / childCenters.length;
        }
      }
      // Uncles / aunts without visible children: sit next to a sibling.
      for (final u in units.where((u) => !u.desired.isFinite)) {
        for (final m in u.members) {
          final sibs = data.siblingsOf(m);
          final sibUnit = units.where((o) =>
              o.desired.isFinite && o.members.any(sibs.contains));
          if (sibUnit.isNotEmpty) {
            final older = data.compareByBirth(m, sibUnit.first.members.first) < 0;
            u.desired = sibUnit.first.desired + (older ? -0.5 : 0.5);
            break;
          }
        }
      }
      place(units);
    }

    // Normalise to positive coordinates.
    final minX = positionsX.values.fold<double>(double.infinity, math.min);
    final maxX = positionsX.values.fold<double>(-double.infinity, math.max);
    final minG = gens.first;
    final maxG = gens.last;
    final width = (maxX - minX) + cardSize.width + margin * 2;
    final height =
        (maxG - minG + 1) * (cardSize.height + rowGap) - rowGap + margin * 2;
    final positions = <String, Offset>{};
    for (final e in positionsX.entries) {
      var x = e.value - minX + margin;
      if (rtl) x = width - x - cardSize.width;
      final y = (gen[e.key]! - minG) * (cardSize.height + rowGap) + margin;
      positions[e.key] = Offset(x, y);
    }

    // Edges.
    final spouseEdges = <SpouseEdge>[];
    for (final u in data.unions) {
      if (positions.containsKey(u.partnerA) &&
          positions.containsKey(u.partnerB) &&
          gen[u.partnerA] == gen[u.partnerB]) {
        spouseEdges.add(SpouseEdge(u.partnerA, u.partnerB, u.status));
      }
    }
    final familyEdges = <FamilyEdge>[];
    for (final child in positions.keys) {
      final byKind = <ParentKind, List<String>>{};
      for (final l in data.parentLinksOf(child)) {
        if (positions.containsKey(l.parentId) &&
            gen[l.parentId] == gen[child]! - 1) {
          byKind.putIfAbsent(l.kind, () => []).add(l.parentId);
        }
      }
      for (final e in byKind.entries) {
        familyEdges.add(FamilyEdge(e.value, child, e.key));
      }
    }

    return TreeLayout(
      positions: positions,
      generation: gen,
      size: Size(width, height),
      cardSize: cardSize,
      spouseEdges: spouseEdges,
      familyEdges: familyEdges,
    );
  }
}
