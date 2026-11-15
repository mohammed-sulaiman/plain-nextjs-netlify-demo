import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'repository.dart';

/// Cloud storage on Supabase (PostgreSQL + Row Level Security + Storage).
/// See `supabase/migrations/0001_init.sql` for the schema and policies.
class SupabaseTreeRepository implements TreeRepository {
  static const photoBucket = 'photos';

  final SupabaseClient client;
  String? _treeId;

  SupabaseTreeRepository(this.client);

  String get treeId => _treeId!;

  @override
  bool get isCloud => true;

  /// Finds the first tree the user belongs to, or creates one.
  Future<void> _ensureTree() async {
    if (_treeId != null) return;
    final uid = client.auth.currentUser!.id;
    final rows = await client
        .from('tree_members')
        .select('tree_id')
        .eq('user_id', uid)
        .order('created_at')
        .limit(1);
    if (rows.isNotEmpty) {
      _treeId = rows.first['tree_id'] as String;
      return;
    }
    final created = await client
        .from('trees')
        .insert({'name': 'My family'})
        .select('id')
        .single();
    _treeId = created['id'] as String;
  }

  @override
  Future<FamilyData> load() async {
    await _ensureTree();
    final results = await Future.wait([
      client.from('persons').select('data').eq('tree_id', treeId),
      client.from('unions').select('data').eq('tree_id', treeId),
      client.from('parent_links').select('data').eq('tree_id', treeId),
    ]);
    Map<String, dynamic> d(dynamic row) =>
        Map<String, dynamic>.from(row['data'] as Map);
    return FamilyData(
      persons: {
        for (final r in results[0])
          (d(r)['id'] as String): Person.fromJson(d(r)),
      },
      unions: results[1].map((r) => Union.fromJson(d(r))).toList(),
      links: results[2].map((r) => ParentLink.fromJson(d(r))).toList(),
    );
  }

  Future<void> _upsert(String table, String id, Map<String, dynamic> json) =>
      client
          .from(table)
          .upsert({'id': id, 'tree_id': treeId, 'data': json});

  Future<void> _delete(String table, String id) =>
      client.from(table).delete().eq('id', id);

  @override
  Future<void> savePerson(Person p) => _upsert('persons', p.id, p.toJson());

  @override
  Future<void> deletePerson(String id) => _delete('persons', id);

  @override
  Future<void> saveUnion(Union u) => _upsert('unions', u.id, u.toJson());

  @override
  Future<void> deleteUnion(String id) => _delete('unions', id);

  @override
  Future<void> saveLink(ParentLink l) =>
      _upsert('parent_links', l.id, l.toJson());

  @override
  Future<void> deleteLink(String id) => _delete('parent_links', id);

  @override
  Future<void> replaceAll(FamilyData data) async {
    await _ensureTree();
    for (final t in ['parent_links', 'unions', 'persons']) {
      await client.from(t).delete().eq('tree_id', treeId);
    }
    Future<void> batch(String table, List<Map<String, dynamic>> rows) async {
      for (var i = 0; i < rows.length; i += 500) {
        await client.from(table).insert(
            rows.sublist(i, i + 500 > rows.length ? rows.length : i + 500));
      }
    }

    final persons = <Map<String, dynamic>>[];
    for (final p in data.persons.values) {
      var person = p;
      // Move inline photos to cloud storage.
      final photo = p.photo;
      if (photo != null && photo.startsWith('data:')) {
        final bytes = UriData.parse(photo).contentAsBytes();
        person = p.copyWith(photo: await storePhoto(p.id, bytes));
      }
      persons.add({'id': p.id, 'tree_id': treeId, 'data': person.toJson()});
    }
    await batch('persons', persons);
    await batch('unions', [
      for (final u in data.unions)
        {'id': u.id, 'tree_id': treeId, 'data': u.toJson()}
    ]);
    await batch('parent_links', [
      for (final l in data.links)
        {'id': l.id, 'tree_id': treeId, 'data': l.toJson()}
    ]);
  }

  @override
  Future<String> storePhoto(String personId, Uint8List bytes) async {
    await _ensureTree();
    final path =
        '$treeId/$personId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await client.storage.from(photoBucket).uploadBinary(
          path,
          bytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return 'storage:$path';
  }
}
