import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../data/repository.dart';
import '../models/models.dart';

enum RelativeType {
  father,
  mother,
  son,
  daughter,
  husband,
  wife,
  brother,
  sister,
}

/// Single source of truth for the currently open tree.
class TreeStore extends ChangeNotifier {
  static const _uuid = Uuid();

  TreeRepository _repo;
  FamilyData data = FamilyData();
  String? focusId;
  bool loading = true;
  Object? error;

  TreeStore(this._repo);

  StreamSubscription<void>? _remoteSub;
  Timer? _reloadDebounce;

  TreeRepository get repository => _repo;
  bool get isCloud => _repo.isCloud;

  /// False when the user only has view access to a shared tree.
  bool get canEdit => _repo.canEdit;
  String newId() => _uuid.v4();

  /// Loads the tree. [silent] keeps the current view on screen (used when
  /// a collaborator changed something).
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      data = await _repo.load();
      if (focusId == null || data[focusId!] == null) {
        focusId = data.persons.keys.isEmpty ? null : data.persons.keys.first;
      }
    } catch (e) {
      error = e;
    }
    loading = false;
    notifyListeners();
    _listenRemote();
  }

  void _listenRemote() {
    _remoteSub?.cancel();
    _remoteSub = _repo.remoteChanges?.listen((_) {
      // Collapse bursts (e.g. a GEDCOM import by a collaborator).
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(
        const Duration(milliseconds: 600),
        () => load(silent: true),
      );
    });
  }

  /// Switches backend (e.g. login/logout or another shared tree) and reloads.
  Future<void> switchRepository(TreeRepository repo) async {
    _remoteSub?.cancel();
    _remoteSub = null;
    _reloadDebounce?.cancel();
    _repo.dispose();
    _repo = repo;
    focusId = null;
    data = FamilyData();
    await load();
  }

  @override
  void dispose() {
    _remoteSub?.cancel();
    _reloadDebounce?.cancel();
    _repo.dispose();
    super.dispose();
  }

  void setFocus(String id) {
    focusId = id;
    notifyListeners();
  }

  /// Viewers can't change anything; the database enforces the same rule.
  void _guard() {
    if (!canEdit) throw StateError('read_only');
  }

  Future<void> _run(Future<void> Function() op) async {
    notifyListeners();
    try {
      await op();
    } catch (e) {
      error = e;
      notifyListeners();
      rethrow;
    }
  }

  // ------------------------------------------------------------- persons

  Future<Person> savePerson(Person p, {Uint8List? newPhoto}) async {
    _guard();
    var person = p;
    if (newPhoto != null) {
      person = p.copyWith(photo: await _repo.storePhoto(p.id, newPhoto));
    }
    data.persons[person.id] = person;
    focusId ??= person.id;
    await _run(() => _repo.savePerson(person));
    return person;
  }

  Future<void> deletePerson(String id) async {
    _guard();
    final unions = data.unions.where((u) => u.involves(id)).toList();
    final links = data.links
        .where((l) => l.parentId == id || l.childId == id)
        .toList();
    data.persons.remove(id);
    data.unions.removeWhere(unions.contains);
    data.links.removeWhere(links.contains);
    if (focusId == id) {
      focusId = data.persons.keys.isEmpty ? null : data.persons.keys.first;
    }
    await _run(() async {
      for (final l in links) {
        await _repo.deleteLink(l.id);
      }
      for (final u in unions) {
        await _repo.deleteUnion(u.id);
      }
      await _repo.deletePerson(id);
    });
  }

  // --------------------------------------------------------------- links

  Future<void> addParent(
    String childId,
    String parentId, {
    ParentKind kind = ParentKind.biological,
  }) async {
    _guard();
    if (childId == parentId) return;
    if (data.links.any(
      (l) => l.childId == childId && l.parentId == parentId && l.kind == kind,
    )) {
      return;
    }
    final l = ParentLink(
      id: newId(),
      parentId: parentId,
      childId: childId,
      kind: kind,
    );
    data.links.add(l);
    await _run(() => _repo.saveLink(l));
  }

  Future<void> removeLink(String linkId) async {
    _guard();
    data.links.removeWhere((l) => l.id == linkId);
    await _run(() => _repo.deleteLink(linkId));
  }

  Future<Union?> addUnion(
    String a,
    String b, {
    UnionStatus status = UnionStatus.married,
    DateTime? start,
  }) async {
    _guard();
    if (a == b || data.unionBetween(a, b) != null) return null;
    final u = Union(
      id: newId(),
      partnerA: a,
      partnerB: b,
      status: status,
      startDate: start,
    );
    data.unions.add(u);
    await _run(() => _repo.saveUnion(u));
    return u;
  }

  Future<void> updateUnion(Union u) async {
    _guard();
    data.unions.removeWhere((x) => x.id == u.id);
    data.unions.add(u);
    await _run(() => _repo.saveUnion(u));
  }

  Future<void> removeUnion(String id) async {
    _guard();
    data.unions.removeWhere((u) => u.id == id);
    await _run(() => _repo.deleteUnion(id));
  }

  /// Creates [newPerson] and connects it to [baseId] as the given relative.
  /// For children, [otherParentId] is the spouse who is the other parent.
  Future<void> addRelative(
    String baseId,
    RelativeType type,
    Person newPerson, {
    Uint8List? photo,
    String? otherParentId,
  }) async {
    _guard();
    final p = await savePerson(newPerson, newPhoto: photo);
    switch (type) {
      case RelativeType.father:
      case RelativeType.mother:
        await addParent(baseId, p.id);
        // Marry the new parent to the existing parent of the other gender.
        for (final other in data.parentsOf(
          baseId,
          kinds: {ParentKind.biological},
        )) {
          if (other != p.id && data[other]!.gender != p.gender) {
            await addUnion(other, p.id);
          }
        }
        break;
      case RelativeType.son:
      case RelativeType.daughter:
        await addParent(p.id, baseId);
        if (otherParentId != null) await addParent(p.id, otherParentId);
        break;
      case RelativeType.husband:
      case RelativeType.wife:
        await addUnion(baseId, p.id);
        break;
      case RelativeType.brother:
      case RelativeType.sister:
        for (final parent in data.parentsOf(
          baseId,
          kinds: {ParentKind.biological},
        )) {
          await addParent(p.id, parent);
        }
        break;
    }
  }

  Future<void> replaceAll(FamilyData newData) async {
    _guard();
    data = newData;
    focusId = newData.persons.keys.isEmpty ? null : newData.persons.keys.first;
    await _run(() => _repo.replaceAll(newData));
    await load();
  }

  /// Adds every record of [other] to the current tree (ids are unique UUIDs).
  Future<void> merge(FamilyData other) async {
    _guard();
    final merged = FamilyData(
      persons: {...data.persons, ...other.persons},
      unions: [...data.unions, ...other.unions],
      links: [...data.links, ...other.links],
    );
    await replaceAll(merged);
  }
}
