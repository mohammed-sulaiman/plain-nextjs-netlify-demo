import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/collaboration.dart';
import '../../state/account.dart';
import '../../state/tree_store.dart';
import '../common.dart';
import 'login_screen.dart';

String roleLabel(AppLocalizations l, TreeRole r) => switch (r) {
  TreeRole.owner => l.roleOwner,
  TreeRole.editor => l.roleEditor,
  TreeRole.viewer => l.roleViewer,
};

String roleHint(AppLocalizations l, TreeRole r) => switch (r) {
  TreeRole.owner => l.roleOwnerHint,
  TreeRole.editor => l.roleEditorHint,
  TreeRole.viewer => l.roleViewerHint,
};

String collabError(AppLocalizations l, Object e) {
  final code = e is CollaborationException ? e.code : 'failed';
  return switch (code) {
    'invite_not_found' => l.inviteNotFound,
    'invite_used' => l.inviteUsed,
    'invite_expired' => l.inviteExpired,
    'invite_wrong_email' => l.inviteWrongEmail,
    'not_authenticated' => l.signInToJoin,
    _ => '${l.actionFailed}: $e',
  };
}

Future<String?> _askName(
  BuildContext context,
  String title, [
  String? initial,
]) {
  final c = TextEditingController(text: initial);
  final l = context.l10n;
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l.treeName,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: Text(l.save),
        ),
      ],
    ),
  ).whenComplete(c.dispose);
}

Future<bool> _confirm(
  BuildContext context,
  String message, {
  bool destructive = false,
}) async {
  final l = context.l10n;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ================================================================= trees

/// All trees the user owns or was invited to; switch, create, rename, delete.
class TreesScreen extends StatefulWidget {
  const TreesScreen({super.key});

  @override
  State<TreesScreen> createState() => _TreesScreenState();
}

class _TreesScreenState extends State<TreesScreen> {
  late Future<List<TreeInfo>> _trees;
  bool _busy = false;

  CollaborationService get _svc =>
      context.read<AccountController>().collaboration!;

  @override
  void initState() {
    super.initState();
    _trees = _svc.myTrees();
  }

  void _reload() => setState(() => _trees = _svc.myTrees());

  Future<void> _guarded(Future<void> Function() op) async {
    setState(() => _busy = true);
    try {
      await op();
    } catch (e) {
      if (mounted) context.snack(collabError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final account = context.watch<AccountController>();
    context.watch<TreeStore>();
    final activeId = account.cloudTree?.currentTreeId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myTrees),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy
            ? null
            : () async {
                final name = await _askName(context, l.newTree);
                if (name == null || name.isEmpty) return;
                await _guarded(() async {
                  final id = await _svc.createTree(name);
                  await account.switchTree(id);
                });
                if (context.mounted) Navigator.pop(context);
              },
        icon: const Icon(Icons.add),
        label: Text(l.newTree),
      ),
      body: FutureBuilder<List<TreeInfo>>(
        future: _trees,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(collabError(l, snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final trees = snap.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final t in trees)
                    ListTile(
                      leading: Icon(
                        t.id == activeId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(t.name.isEmpty ? l.unnamed : t.name),
                      subtitle: Text(roleLabel(l, t.role)),
                      onTap: _busy
                          ? null
                          : () async {
                              await _guarded(() => account.switchTree(t.id));
                              if (context.mounted) Navigator.pop(context);
                            },
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          switch (v) {
                            case 'rename':
                              final name = await _askName(
                                context,
                                l.renameTree,
                                t.name,
                              );
                              if (name == null || name.isEmpty) return;
                              await _guarded(() => _svc.renameTree(t.id, name));
                              if (t.id == activeId) {
                                await account.switchTree(t.id);
                              }
                            case 'leave':
                              if (!await _confirm(
                                context,
                                l.leaveConfirm(t.name),
                              )) {
                                return;
                              }
                              await _guarded(() => _svc.leaveTree(t.id));
                              if (t.id == activeId) {
                                final rest = trees.where((x) => x.id != t.id);
                                await account.switchTree(
                                  rest.isEmpty ? '' : rest.first.id,
                                );
                              }
                            case 'delete':
                              if (!context.mounted) return;
                              if (!await _confirm(
                                context,
                                l.deleteTreeConfirm(t.name),
                                destructive: true,
                              )) {
                                return;
                              }
                              await _guarded(() => _svc.deleteTree(t.id));
                              if (t.id == activeId) {
                                final rest = trees.where((x) => x.id != t.id);
                                await account.switchTree(
                                  rest.isEmpty ? '' : rest.first.id,
                                );
                              }
                          }
                          _reload();
                        },
                        itemBuilder: (_) => [
                          if (t.role == TreeRole.owner) ...[
                            PopupMenuItem(
                              value: 'rename',
                              child: Text(l.renameTree),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l.deleteTree),
                            ),
                          ] else
                            PopupMenuItem(
                              value: 'leave',
                              child: Text(l.leaveTree),
                            ),
                        ],
                      ),
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.vpn_key_outlined),
                    title: Text(l.joinWithCode),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JoinTreeScreen()),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================================================================= share

/// Members and invitations of the open tree.
class ShareTreeScreen extends StatefulWidget {
  const ShareTreeScreen({super.key});

  @override
  State<ShareTreeScreen> createState() => _ShareTreeScreenState();
}

class _ShareTreeScreenState extends State<ShareTreeScreen> {
  late Future<(List<TreeMember>, List<TreeInvite>)> _future;
  bool _busy = false;

  AccountController get _account => context.read<AccountController>();
  CollaborationService get _svc => _account.collaboration!;
  String get _treeId => _account.cloudTree!.treeId;
  bool get _isOwner => _account.cloudTree!.role == 'owner';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<TreeMember>, List<TreeInvite>)> _load() async {
    final members = await _svc.members(_treeId);
    final invites = _isOwner ? await _svc.invites(_treeId) : <TreeInvite>[];
    return (members, invites);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _guarded(Future<void> Function() op) async {
    setState(() => _busy = true);
    try {
      await op();
      _reload();
    } catch (e) {
      if (mounted) context.snack(collabError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final invite = await showDialog<TreeInvite>(
      context: context,
      builder: (_) => _CreateInviteDialog(svc: _svc, treeId: _treeId),
    );
    if (invite == null || !mounted) return;
    _reload();
    await showInviteDialog(context, invite, _account.cloudTree?.treeName ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final me = _account.user?.id;
    final treeName = _account.cloudTree?.treeName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.shareTree),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton: _isOwner
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _invite,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l.inviteRelative),
            )
          : null,
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(collabError(l, snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (members, invites) = snap.data!;
          final pending = invites.where((i) => i.isPending).toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.account_tree_outlined),
                      title: Text(
                        treeName.isEmpty ? l.unnamed : treeName,
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(l.shareIntro),
                    ),
                    _Header(l.membersCount(members.length)),
                    for (final m in members)
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            m.email.isEmpty
                                ? '?'
                                : m.email.characters.first.toUpperCase(),
                          ),
                        ),
                        title: Text(
                          m.userId == me ? '${m.email} (${l.you})' : m.email,
                        ),
                        subtitle: Text(roleHint(l, m.role)),
                        trailing: _isOwner && m.userId != me
                            ? PopupMenuButton<String>(
                                tooltip: l.changeRole,
                                onSelected: (v) async {
                                  if (v == 'remove') {
                                    if (!await _confirm(
                                      context,
                                      l.removeMemberConfirm(m.email),
                                      destructive: true,
                                    )) {
                                      return;
                                    }
                                    await _guarded(
                                      () =>
                                          _svc.removeMember(_treeId, m.userId),
                                    );
                                  } else {
                                    await _guarded(
                                      () => _svc.setRole(
                                        _treeId,
                                        m.userId,
                                        TreeRole.values.byName(v),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (_) => [
                                  for (final r in [
                                    TreeRole.editor,
                                    TreeRole.viewer,
                                  ])
                                    CheckedPopupMenuItem(
                                      value: r.name,
                                      checked: m.role == r,
                                      child: Text(roleLabel(l, r)),
                                    ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Text(
                                      l.removeMember,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                                child: Chip(label: Text(roleLabel(l, m.role))),
                              )
                            : Chip(label: Text(roleLabel(l, m.role))),
                      ),
                    if (_isOwner) ...[
                      _Header(l.pendingInvites),
                      if (pending.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l.noPendingInvites,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      for (final i in pending)
                        ListTile(
                          leading: const Icon(Icons.mail_outline),
                          title: Text(i.email ?? l.anyoneWithCode),
                          subtitle: Text(
                            '${roleLabel(l, i.role)} • ${i.code} • '
                            '${l.expiresOn(context.dates.gregorian(i.expiresAt))}',
                          ),
                          onTap: () => showInviteDialog(context, i, treeName),
                          trailing: IconButton(
                            tooltip: l.revokeInvite,
                            icon: const Icon(Icons.block),
                            onPressed: () async {
                              if (!await _confirm(context, l.revokeConfirm)) {
                                return;
                              }
                              await _guarded(() => _svc.revokeInvite(i.id));
                            },
                          ),
                        ),
                    ] else ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (!await _confirm(
                              context,
                              l.leaveConfirm(treeName),
                            )) {
                              return;
                            }
                            await _guarded(() async {
                              await _svc.leaveTree(_treeId);
                              final rest = (await _svc.myTrees()).where(
                                (t) => t.id != _treeId,
                              );
                              await _account.switchTree(
                                rest.isEmpty ? '' : rest.first.id,
                              );
                            });
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.logout),
                          label: Text(l.leaveTree),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l.liveEditingNote,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

class _CreateInviteDialog extends StatefulWidget {
  final CollaborationService svc;
  final String treeId;
  const _CreateInviteDialog({required this.svc, required this.treeId});

  @override
  State<_CreateInviteDialog> createState() => _CreateInviteDialogState();
}

class _CreateInviteDialogState extends State<_CreateInviteDialog> {
  TreeRole _role = TreeRole.editor;
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.inviteRelative),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.inviteRoleQuestion),
            const SizedBox(height: 8),
            RadioGroup<TreeRole>(
              groupValue: _role,
              onChanged: (v) => setState(() => _role = v!),
              child: Column(
                children: [
                  for (final r in [TreeRole.editor, TreeRole.viewer])
                    RadioListTile(
                      value: r,
                      contentPadding: EdgeInsets.zero,
                      title: Text(roleLabel(l, r)),
                      subtitle: Text(roleHint(l, r)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l.inviteEmailOptional,
                helperText: l.inviteEmailHint,
                helperMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  final email = _email.text.trim();
                  if (email.isNotEmpty && !email.contains('@')) {
                    context.snack(l.invalidEmail);
                    return;
                  }
                  setState(() => _busy = true);
                  try {
                    final inv = await widget.svc.createInvite(
                      widget.treeId,
                      _role,
                      email: email,
                    );
                    if (context.mounted) Navigator.pop(context, inv);
                  } catch (e) {
                    if (context.mounted) {
                      setState(() => _busy = false);
                      context.snack(collabError(l, e));
                    }
                  }
                },
          child: Text(l.createInvite),
        ),
      ],
    );
  }
}

/// Shows an invite code and link with copy buttons.
Future<void> showInviteDialog(
  BuildContext context,
  TreeInvite invite,
  String treeName,
) {
  final l = context.l10n;
  final link = CollaborationService.inviteLink(
    invite.code,
    webBase: kIsWeb
        ? Uri.base.replace(queryParameters: {}, fragment: '')
        : null,
  );
  final message = l.inviteMessage(treeName, invite.code, link ?? '');
  return showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      void copy(String text) {
        Clipboard.setData(ClipboardData(text: text));
        ctx.snack(l.copied);
      }

      return AlertDialog(
        title: Text(l.inviteReady),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.inviteReadyHint),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  invite.code,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${roleLabel(l, invite.role)} • '
                '${invite.email ?? l.anyoneWithCode} • '
                '${l.expiresOn(ctx.datesRead.gregorian(invite.expiresAt))}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (link != null) ...[
                const SizedBox(height: 12),
                SelectableText(
                  link,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => copy(invite.code),
            icon: const Icon(Icons.copy),
            label: Text(l.copyCode),
          ),
          FilledButton.icon(
            onPressed: () => copy(message),
            icon: const Icon(Icons.share),
            label: Text(l.copyInviteMessage),
          ),
        ],
      );
    },
  );
}

// ================================================================== join

/// Enter (or open a link with) an invite code and join the tree.
class JoinTreeScreen extends StatefulWidget {
  final String? initialCode;
  const JoinTreeScreen({super.key, this.initialCode});

  @override
  State<JoinTreeScreen> createState() => _JoinTreeScreenState();
}

class _JoinTreeScreenState extends State<JoinTreeScreen> {
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  InvitePreview? _preview;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialCode ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final svc = context.read<AccountController>().collaboration;
    if (svc == null || _code.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final p = await svc.previewInvite(_code.text);
      setState(() {
        _preview = p;
        if (p == null) _error = context.l10n.inviteNotFound;
      });
    } catch (e) {
      setState(() => _error = collabError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final account = context.read<AccountController>();
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final id = await account.collaboration!.acceptInvite(_code.text);
      await account.switchTree(id);
      if (!mounted) return;
      Navigator.popUntil(context, (r) => r.isFirst);
      context.snack(l.joined(_preview?.treeName ?? ''));
    } catch (e) {
      if (mounted) setState(() => _error = collabError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final account = context.watch<AccountController>();
    final theme = Theme.of(context);
    final p = _preview;

    Widget body;
    if (!account.available) {
      body = Text(l.cloudNotConfiguredHint, textAlign: TextAlign.center);
    } else if (!account.signedIn) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.signInToJoin, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            icon: const Icon(Icons.login),
            label: Text(l.signIn),
          ),
        ],
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.joinHint, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 3),
            decoration: InputDecoration(
              labelText: l.inviteCode,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _check(),
          ),
          const SizedBox(height: 12),
          if (p == null)
            FilledButton(
              onPressed: _busy ? null : _check,
              child: Text(l.checkInvite),
            ),
          if (p != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_tree,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(p.treeName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(l.invitedAs(roleLabel(l, p.role))),
                    if (p.invitedBy != null)
                      Text(
                        l.invitedBy(p.invitedBy!),
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 12),
                    if (p.status == 'valid')
                      FilledButton.icon(
                        onPressed: _busy ? null : _join,
                        icon: const Icon(Icons.group_add),
                        label: Text(l.joinTree),
                      )
                    else
                      Text(
                        p.status == 'used' ? l.inviteUsed : l.inviteExpired,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ],
                ),
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.joinTree)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: body,
          ),
        ),
      ),
    );
  }
}
