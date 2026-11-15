import 'package:supabase_flutter/supabase_flutter.dart';

/// Tree roles: owners manage sharing, editors change the tree, viewers read.
enum TreeRole { owner, editor, viewer }

TreeRole _role(Object? v) => TreeRole.values.firstWhere(
  (r) => r.name == v,
  orElse: () => TreeRole.viewer,
);

class TreeInfo {
  final String id;
  final String name;
  final TreeRole role;
  const TreeInfo(this.id, this.name, this.role);
}

class TreeMember {
  final String userId;
  final String email;
  final TreeRole role;
  final DateTime? joinedAt;
  const TreeMember(this.userId, this.email, this.role, this.joinedAt);
}

class TreeInvite {
  final String id;
  final String code;
  final TreeRole role;
  final String? email;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  const TreeInvite(
    this.id,
    this.code,
    this.role,
    this.email,
    this.expiresAt,
    this.acceptedAt,
  );

  bool get isExpired =>
      acceptedAt == null && expiresAt.isBefore(DateTime.now());
  bool get isPending => acceptedAt == null && !isExpired;
}

class InvitePreview {
  final String treeName;
  final TreeRole role;
  final String? invitedBy;
  final DateTime expiresAt;

  /// valid, used or expired.
  final String status;
  const InvitePreview(
    this.treeName,
    this.role,
    this.invitedBy,
    this.expiresAt,
    this.status,
  );
}

/// Error codes raised by the database functions in 0002_collaboration.sql.
class CollaborationException implements Exception {
  final String code;
  const CollaborationException(this.code);

  static const known = [
    'not_authenticated',
    'invite_not_found',
    'invite_used',
    'invite_expired',
    'invite_wrong_email',
  ];

  static CollaborationException from(Object e) {
    final msg = e is PostgrestException ? e.message : e.toString();
    return CollaborationException(
      known.firstWhere(msg.contains, orElse: () => 'failed'),
    );
  }

  @override
  String toString() => 'CollaborationException($code)';
}

/// Sharing a family tree with relatives (Supabase).
class CollaborationService {
  final SupabaseClient client;
  CollaborationService(this.client);

  String get _uid => client.auth.currentUser!.id;

  /// Normalises what people type or paste: spaces, lower case, or a whole
  /// invite link.
  static String normalizeCode(String input) {
    final s = input.trim();
    final uri = Uri.tryParse(s);
    final fromLink = uri?.queryParameters['invite'];
    return (fromLink ?? s)
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
  }

  Future<List<TreeInfo>> myTrees() async {
    final rows = await client
        .from('tree_members')
        .select('tree_id, role, trees(name)')
        .eq('user_id', _uid)
        .order('created_at');
    return [
      for (final r in rows)
        TreeInfo(
          r['tree_id'] as String,
          ((r['trees'] as Map?)?['name'] as String?) ?? '',
          _role(r['role']),
        ),
    ];
  }

  Future<String> createTree(String name) async {
    final row = await client
        .from('trees')
        .insert({'name': name})
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> renameTree(String treeId, String name) =>
      client.from('trees').update({'name': name}).eq('id', treeId);

  Future<void> deleteTree(String treeId) =>
      client.from('trees').delete().eq('id', treeId);

  Future<List<TreeMember>> members(String treeId) async {
    final rows = await client.rpc(
      'tree_members_with_email',
      params: {'p_tree': treeId},
    ) as List;
    return [
      for (final r in rows)
        TreeMember(
          r['user_id'] as String,
          r['email'] as String? ?? '',
          _role(r['role']),
          DateTime.tryParse(r['joined_at'] as String? ?? ''),
        ),
    ];
  }

  Future<void> setRole(String treeId, String userId, TreeRole role) => client
      .from('tree_members')
      .update({'role': role.name})
      .eq('tree_id', treeId)
      .eq('user_id', userId);

  Future<void> removeMember(String treeId, String userId) => client
      .from('tree_members')
      .delete()
      .eq('tree_id', treeId)
      .eq('user_id', userId);

  Future<void> leaveTree(String treeId) => removeMember(treeId, _uid);

  Future<List<TreeInvite>> invites(String treeId) async {
    final rows = await client
        .from('tree_invites')
        .select()
        .eq('tree_id', treeId)
        .order('created_at', ascending: false);
    return rows.map(_invite).toList();
  }

  TreeInvite _invite(Map<String, dynamic> r) => TreeInvite(
    r['id'] as String,
    r['code'] as String,
    _role(r['role']),
    r['email'] as String?,
    DateTime.parse(r['expires_at'] as String).toLocal(),
    r['accepted_at'] == null
        ? null
        : DateTime.parse(r['accepted_at'] as String).toLocal(),
  );

  Future<TreeInvite> createInvite(
    String treeId,
    TreeRole role, {
    String? email,
  }) async {
    final row = await client
        .from('tree_invites')
        .insert({
          'tree_id': treeId,
          'role': role.name,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        })
        .select()
        .single();
    return _invite(row);
  }

  Future<void> revokeInvite(String inviteId) =>
      client.from('tree_invites').delete().eq('id', inviteId);

  Future<InvitePreview?> previewInvite(String code) async {
    try {
      final rows = await client.rpc(
        'invite_info',
        params: {'p_code': normalizeCode(code)},
      ) as List;
      if (rows.isEmpty) return null;
      final r = rows.first as Map;
      return InvitePreview(
        r['tree_name'] as String? ?? '',
        _role(r['role']),
        r['invited_by'] as String?,
        DateTime.parse(r['expires_at'] as String).toLocal(),
        r['status'] as String,
      );
    } catch (e) {
      throw CollaborationException.from(e);
    }
  }

  /// Joins the tree and returns its id.
  Future<String> acceptInvite(String code) async {
    try {
      final id = await client.rpc(
        'accept_invite',
        params: {'p_code': normalizeCode(code)},
      );
      return id as String;
    } catch (e) {
      throw CollaborationException.from(e);
    }
  }

  /// Link that opens the web app on the join screen. Uses INVITE_BASE_URL
  /// when the app is hosted, otherwise the current web origin; null on
  /// native builds without a hosted URL (the code alone is shared then).
  static String? inviteLink(String code, {Uri? webBase}) {
    const configured = String.fromEnvironment('INVITE_BASE_URL');
    final base = configured.isNotEmpty ? Uri.parse(configured) : webBase;
    if (base == null) return null;
    return base.replace(queryParameters: {'invite': code}).toString();
  }
}
