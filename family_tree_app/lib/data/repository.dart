import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Storage backend for a single family tree. Implemented locally (on-device,
/// works offline on every platform) and on Supabase (cloud + login).
abstract class TreeRepository {
  bool get isCloud;

  /// False for viewers of a shared tree.
  bool get canEdit;

  /// Fires when someone else changes the tree (cloud only).
  Stream<void>? get remoteChanges;

  /// Releases subscriptions when the repository is replaced.
  void dispose();

  Future<FamilyData> load();

  Future<void> savePerson(Person p);
  Future<void> deletePerson(String id);
  Future<void> saveUnion(Union u);
  Future<void> deleteUnion(String id);
  Future<void> saveLink(ParentLink l);
  Future<void> deleteLink(String id);

  /// Replaces the whole tree (used by import and by "upload local tree").
  Future<void> replaceAll(FamilyData data);

  /// Stores a photo and returns the reference to keep in [Person.photo].
  Future<String> storePhoto(String personId, Uint8List bytes);
}

/// Keeps the tree as a JSON document in SharedPreferences (localStorage on
/// the web, NSUserDefaults/SharedPreferences/files on native platforms).
/// Photos are stored inline as small, pre-resized JPEG data URIs.
class LocalTreeRepository implements TreeRepository {
  static const _key = 'family_tree_data_v1';
  FamilyData _data = FamilyData();

  @override
  bool get isCloud => false;

  @override
  bool get canEdit => true;

  @override
  Stream<void>? get remoteChanges => null;

  @override
  void dispose() {}

  @override
  Future<FamilyData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _data = FamilyData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _data = FamilyData();
      }
    }
    // Hand out a copy: the store mutates its own instance.
    return FamilyData.fromJson(_data.toJson());
  }

  Future<void> _flush() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_data.toJson()));
  }

  @override
  Future<void> savePerson(Person p) async {
    _data.persons[p.id] = p;
    await _flush();
  }

  @override
  Future<void> deletePerson(String id) async {
    _data.persons.remove(id);
    _data.unions.removeWhere((u) => u.involves(id));
    _data.links.removeWhere((l) => l.parentId == id || l.childId == id);
    await _flush();
  }

  @override
  Future<void> saveUnion(Union u) async {
    _data.unions.removeWhere((x) => x.id == u.id);
    _data.unions.add(u);
    await _flush();
  }

  @override
  Future<void> deleteUnion(String id) async {
    _data.unions.removeWhere((x) => x.id == id);
    await _flush();
  }

  @override
  Future<void> saveLink(ParentLink l) async {
    _data.links.removeWhere((x) => x.id == l.id);
    _data.links.add(l);
    await _flush();
  }

  @override
  Future<void> deleteLink(String id) async {
    _data.links.removeWhere((x) => x.id == id);
    await _flush();
  }

  @override
  Future<void> replaceAll(FamilyData data) async {
    _data = FamilyData(
      persons: Map.of(data.persons),
      unions: List.of(data.unions),
      links: List.of(data.links),
    );
    await _flush();
  }

  @override
  Future<String> storePhoto(String personId, Uint8List bytes) async =>
      'data:image/jpeg;base64,${base64Encode(bytes)}';
}
