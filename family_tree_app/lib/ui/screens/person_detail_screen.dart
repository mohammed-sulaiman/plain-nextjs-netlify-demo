import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../logic/kinship.dart';
import '../../logic/relationship_names.dart';
import '../../models/models.dart';
import '../../state/tree_store.dart';
import '../common.dart';
import '../widgets/person_widgets.dart';
import 'face_similarity_screen.dart';
import 'home_screen.dart' show addRelativeFlow;
import 'map_screen.dart';
import 'person_edit_screen.dart';
import 'relationship_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  void _open(BuildContext context, String id) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: id)));

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TreeStore>();
    final d = store.data;
    final p = d[personId];
    final l = context.l10n;
    final theme = Theme.of(context);
    final dates = context.dates;
    if (p == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(l.notFound)));
    }

    final focus = store.focusId;
    String? relationToFocus;
    if (focus != null && focus != p.id) {
      final namer = RelationshipNamer.forLocale(
          Localizations.localeOf(context).languageCode);
      final rel = KinshipCalculator(d).relation(focus, p.id);
      if (rel.type != RelationType.none) {
        relationToFocus = l.relationTo(namer.name(rel, d), d[focus]!.displayName);
      }
    }
    final lin = lineageOf(context, d, p.id, depth: 6);

    final parentLinks = d.parentLinksOf(p.id).toList();
    final unions = d.unionsOf(p.id);
    final childLinks = d.childLinksOf(p.id).toList();
    final siblings = d.siblingsOf(p.id);

    Widget personTile(String id,
        {String? subtitle, VoidCallback? onRemove, Widget? extra}) {
      final x = d[id]!;
      return ListTile(
        leading: PersonAvatar(person: x, size: 40),
        title: Text(x.displayName.isEmpty ? l.unnamed : x.displayName),
        subtitle: subtitle == null ? null : Text(subtitle),
        onTap: () => _open(context, id),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?extra,
            if (onRemove != null)
              IconButton(
                tooltip: l.unlink,
                icon: const Icon(Icons.link_off),
                onPressed: () async {
                  final ok = await _confirm(context, l.unlinkConfirm);
                  if (ok) onRemove();
                },
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(p.displayName),
        actions: [
          IconButton(
            tooltip: l.setAsFocus,
            icon: Icon(store.focusId == p.id
                ? Icons.center_focus_strong
                : Icons.center_focus_weak),
            onPressed: () {
              store.setFocus(p.id);
              context.snack(l.focusSet(p.displayName));
            },
          ),
          IconButton(
            tooltip: l.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PersonEditScreen(person: p))),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'faces':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => FaceSimilarityScreen(personId: p.id)));
                case 'relation':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RelationshipScreen(initialB: p.id)));
                case 'map':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MapScreen(personId: p.id)));
                case 'delete':
                  if (await _confirm(context, l.deleteConfirm(p.displayName))) {
                    await store.deletePerson(p.id);
                    if (context.mounted) Navigator.pop(context);
                  }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'faces', child: Text(l.faceSimilarity)),
              PopupMenuItem(value: 'relation', child: Text(l.relationshipCalculator)),
              PopupMenuItem(value: 'map', child: Text(l.familyMap)),
              const PopupMenuDivider(),
              PopupMenuItem(
                  value: 'delete',
                  child: Text(l.deletePerson,
                      style: TextStyle(color: theme.colorScheme.error))),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // ---------------------------------------------------- header
              Container(
                padding: const EdgeInsets.all(20),
                color: genderColor(context, p.gender).withValues(alpha: 0.5),
                child: Column(
                  children: [
                    PersonAvatar(person: p, size: 112),
                    const SizedBox(height: 12),
                    Text(p.displayName,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center),
                    if (lin != p.displayName) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: lin));
                          context.snack(l.copied);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(lin,
                              style: theme.textTheme.titleSmall,
                              textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (p.kunya.isNotEmpty) Chip(label: Text(p.kunya)),
                        if (p.nickname.isNotEmpty) Chip(label: Text(p.nickname)),
                        if (p.tribe.isNotEmpty)
                          Chip(
                              avatar: const Icon(Icons.groups_outlined, size: 18),
                              label: Text(p.tribe)),
                        if (ageText(l, p) != null)
                          Chip(
                              avatar: const Icon(Icons.cake_outlined, size: 18),
                              label: Text(ageText(l, p)!)),
                        if (relationToFocus != null)
                          Chip(
                              avatar: const Icon(Icons.diversity_3, size: 18),
                              label: Text(relationToFocus)),
                      ],
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------- basic info
              _Section(title: l.basicInfo, children: [
                _InfoRow(Icons.wc, l.gender, genderLabel(l, p.gender)),
                if (p.birthDate != null)
                  _InfoRow(Icons.cake_outlined, l.fieldBirthDate,
                      dates.format(p.birthDate)),
                if (p.birthPlace.isNotEmpty)
                  _InfoRow(Icons.place_outlined, l.fieldBirthPlace, p.birthPlace),
                if (p.isDeceased)
                  _InfoRow(Icons.local_florist_outlined, l.fieldDeathDate,
                      p.deathDate == null ? l.deceased : dates.format(p.deathDate)),
                if (p.currentResidence != null)
                  _InfoRow(Icons.home_outlined, l.fieldResidence,
                      p.currentResidence!.place),
                if (p.notes.isNotEmpty)
                  _InfoRow(Icons.notes, l.notes, p.notes),
              ]),

              // ---------------------------------------------------- parents
              _Section(
                title: l.parents,
                action: _AddMenu(
                  label: l.add,
                  items: {
                    l.addFather: () => addRelativeFlow(context, p.id, RelativeType.father),
                    l.addMother: () => addRelativeFlow(context, p.id, RelativeType.mother),
                    l.linkExistingParent: () => _linkParent(context, p.id),
                  },
                ),
                children: [
                  if (parentLinks.isEmpty) _Empty(l.none),
                  for (final link in parentLinks)
                    if (d[link.parentId] != null)
                      personTile(link.parentId,
                          subtitle: parentKindLabel(l, link.kind),
                          onRemove: () => store.removeLink(link.id)),
                ],
              ),

              // ---------------------------------------------------- spouses
              _Section(
                title: l.spouses,
                action: _AddMenu(
                  label: l.add,
                  items: {
                    (p.gender == Gender.female ? l.addHusband : l.addWife): () =>
                        addRelativeFlow(
                            context,
                            p.id,
                            p.gender == Gender.female
                                ? RelativeType.husband
                                : RelativeType.wife),
                    l.linkExistingSpouse: () async {
                      final id = await pickPerson(context,
                          title: l.linkExistingSpouse, exclude: {p.id});
                      if (id != null) await store.addUnion(p.id, id);
                    },
                  },
                ),
                children: [
                  if (unions.isEmpty) _Empty(l.none),
                  for (final u in unions)
                    if (d[u.other(p.id)] != null)
                      personTile(
                        u.other(p.id),
                        subtitle: [
                          unionStatusLabel(l, u.status),
                          if (u.startDate != null) dates.format(u.startDate),
                        ].join(' • '),
                        onRemove: () => store.removeUnion(u.id),
                        extra: IconButton(
                          tooltip: l.editMarriage,
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () => _editUnion(context, u),
                        ),
                      ),
                ],
              ),

              // --------------------------------------------------- children
              _Section(
                title: l.children,
                action: _AddMenu(
                  label: l.add,
                  items: {
                    l.addSon: () => addRelativeFlow(context, p.id, RelativeType.son),
                    l.addDaughter: () =>
                        addRelativeFlow(context, p.id, RelativeType.daughter),
                    l.linkExistingChild: () async {
                      final id = await pickPerson(context,
                          title: l.linkExistingChild, exclude: {p.id});
                      if (id != null && context.mounted) {
                        final kind = await _pickKind(context);
                        if (kind != null) {
                          await store.addParent(id, p.id, kind: kind);
                        }
                      }
                    },
                  },
                ),
                children: [
                  if (childLinks.isEmpty) _Empty(l.none),
                  for (final link in childLinks)
                    if (d[link.childId] != null)
                      personTile(link.childId,
                          subtitle: [
                            if (link.kind != ParentKind.biological)
                              parentKindLabel(l, link.kind),
                            if (ageText(l, d[link.childId]!) != null)
                              ageText(l, d[link.childId]!)!,
                          ].join(' • '),
                          onRemove: () => store.removeLink(link.id)),
                ],
              ),

              // --------------------------------------------------- siblings
              _Section(
                title: l.siblings,
                action: _AddMenu(label: l.add, items: {
                  l.addBrother: () =>
                      addRelativeFlow(context, p.id, RelativeType.brother),
                  l.addSister: () =>
                      addRelativeFlow(context, p.id, RelativeType.sister),
                }),
                children: [
                  if (siblings.isEmpty) _Empty(l.none),
                  for (final s in siblings) personTile(s),
                ],
              ),

              // ------------------------------------------------- residences
              _Section(
                title: l.residences,
                action: p.residences.any((r) => r.hasLocation)
                    ? TextButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MapScreen(personId: p.id))),
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l.showOnMap),
                      )
                    : null,
                children: [
                  if (p.residences.isEmpty) _Empty(l.noResidences),
                  for (final r in p.residences)
                    ListTile(
                      leading: Icon(r.hasLocation
                          ? Icons.location_on_outlined
                          : Icons.home_outlined),
                      title: Text(r.place),
                      subtitle: (r.from == null && r.to == null)
                          ? null
                          : Text(
                              '${r.from == null ? '…' : dates.format(r.from)} – '
                              '${r.to == null ? l.present : dates.format(r.to)}'),
                    ),
                ],
              ),

              // --------------------------------------------------- timeline
              _Section(
                title: l.timeline,
                children: [_Timeline(person: p, data: d)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _linkParent(BuildContext context, String childId) async {
    final l = context.l10n;
    final id = await pickPerson(context,
        title: l.linkExistingParent, exclude: {childId});
    if (id == null || !context.mounted) return;
    final kind = await _pickKind(context);
    if (kind == null || !context.mounted) return;
    await treeOf(context).addParent(childId, id, kind: kind);
  }

  Future<ParentKind?> _pickKind(BuildContext context) {
    final l = context.l10n;
    return showDialog<ParentKind>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.linkType),
        children: [
          for (final k in ParentKind.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, k),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(parentKindLabel(l, k)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editUnion(BuildContext context, Union u) async {
    final result = await showDialog<Union>(
        context: context, builder: (_) => _UnionDialog(union: u));
    if (result != null && context.mounted) {
      await treeOf(context).updateUnion(result);
    }
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final l = context.l10n;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
      ],
    ),
  );
  return r ?? false;
}

class _Section extends StatelessWidget {
  final String title;
  final Widget? action;
  final List<Widget> children;
  const _Section({required this.title, this.action, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ?action,
                  ],
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMenu extends StatelessWidget {
  final String label;
  final Map<String, VoidCallback> items;
  const _AddMenu({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final e in items.entries)
          MenuItemButton(onPressed: e.value, child: Text(e.key)),
      ],
      builder: (context, controller, _) => TextButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.add),
        label: Text(label),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(value),
        subtitle: Text(label),
        dense: true,
      );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

class _TimelineEvent {
  final DateTime date;
  final IconData icon;
  final String text;
  const _TimelineEvent(this.date, this.icon, this.text);
}

class _Timeline extends StatelessWidget {
  final Person person;
  final FamilyData data;
  const _Timeline({required this.person, required this.data});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final theme = Theme.of(context);
    final p = person;
    final events = <_TimelineEvent>[];
    if (p.birthDate != null) {
      events.add(_TimelineEvent(p.birthDate!, Icons.cake_outlined,
          p.birthPlace.isEmpty ? l.evBorn : l.evBornIn(p.birthPlace)));
    }
    for (final u in data.unionsOf(p.id)) {
      final s = data[u.other(p.id)];
      if (s == null) continue;
      if (u.startDate != null) {
        events.add(_TimelineEvent(
            u.startDate!, Icons.favorite_outline, l.evMarried(s.displayName)));
      }
      if (u.endDate != null) {
        events.add(_TimelineEvent(
            u.endDate!,
            Icons.heart_broken_outlined,
            u.status == UnionStatus.divorced
                ? l.evDivorced(s.displayName)
                : l.evWidowed(s.displayName)));
      }
    }
    for (final c in data.childrenOf(p.id)) {
      final child = data[c]!;
      if (child.birthDate != null) {
        events.add(_TimelineEvent(child.birthDate!, Icons.child_care,
            l.evChildBorn(child.displayName)));
      }
    }
    for (final r in p.residences) {
      if (r.from != null) {
        events.add(_TimelineEvent(r.from!, Icons.moving, l.evMoved(r.place)));
      }
    }
    for (final parent in data.parentsOf(p.id, kinds: {ParentKind.biological})) {
      final x = data[parent]!;
      if (x.deathDate != null &&
          (p.birthDate == null || x.deathDate!.isAfter(p.birthDate!))) {
        events.add(_TimelineEvent(x.deathDate!, Icons.local_florist_outlined,
            l.evParentDied(x.displayName)));
      }
    }
    if (p.deathDate != null) {
      events.add(
          _TimelineEvent(p.deathDate!, Icons.local_florist, l.evDied));
    }
    events.sort((a, b) => a.date.compareTo(b.date));
    if (events.isEmpty) return _Empty(l.noEvents);

    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: 16),
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Expanded(
                        child: VerticalDivider(
                            width: 2,
                            thickness: 2,
                            color: i == 0
                                ? Colors.transparent
                                : theme.colorScheme.outlineVariant),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(events[i].icon,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                      Expanded(
                        child: VerticalDivider(
                            width: 2,
                            thickness: 2,
                            color: i == events.length - 1
                                ? Colors.transparent
                                : theme.colorScheme.outlineVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(events[i].text, style: theme.textTheme.bodyLarge),
                        Text(
                          [
                            dates.format(events[i].date),
                            if (p.ageAt(events[i].date) != null &&
                                events[i].date != p.birthDate)
                              l.ageYears(p.ageAt(events[i].date)!),
                          ].join(' • '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
      ],
    );
  }
}

class _UnionDialog extends StatefulWidget {
  final Union union;
  const _UnionDialog({required this.union});

  @override
  State<_UnionDialog> createState() => _UnionDialogState();
}

class _UnionDialogState extends State<_UnionDialog> {
  late Union _u = widget.union;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.editMarriage),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<UnionStatus>(
              segments: [
                for (final s in UnionStatus.values)
                  ButtonSegment(value: s, label: Text(unionStatusLabel(l, s))),
              ],
              selected: {_u.status},
              onSelectionChanged: (s) =>
                  setState(() => _u = _u.copyWith(status: s.first)),
            ),
            const SizedBox(height: 12),
            DateField(
              label: l.marriageDate,
              value: _u.startDate,
              onChanged: (d) => setState(() => _u = d == null
                  ? _u.copyWith(clearStart: true)
                  : _u.copyWith(startDate: d)),
            ),
            if (_u.status != UnionStatus.married) ...[
              const SizedBox(height: 12),
              DateField(
                label: l.endDate,
                value: _u.endDate,
                onChanged: (d) => setState(() => _u = d == null
                    ? _u.copyWith(clearEnd: true)
                    : _u.copyWith(endDate: d)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, _u), child: Text(l.save)),
      ],
    );
  }
}
