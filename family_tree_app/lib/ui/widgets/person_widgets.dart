import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/cloud.dart';
import '../../state/settings_store.dart';
import '../../state/tree_store.dart';
import '../common.dart';

class PersonAvatar extends StatefulWidget {
  final Person person;
  final double size;
  const PersonAvatar({super.key, required this.person, this.size = 48});

  @override
  State<PersonAvatar> createState() => _PersonAvatarState();
}

class _PersonAvatarState extends State<PersonAvatar> {
  late Future<Object?> _future;

  @override
  void initState() {
    super.initState();
    _future = PhotoResolver.resolve(widget.person.photo);
  }

  @override
  void didUpdateWidget(PersonAvatar old) {
    super.didUpdateWidget(old);
    if (old.person.photo != widget.person.photo) {
      _future = PhotoResolver.resolve(widget.person.photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    final initials = p.givenName.isEmpty ? '?' : p.givenName.characters.first;
    final scheme = Theme.of(context).colorScheme;
    final fallback = CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: Color.alphaBlend(
          scheme.onSurface.withValues(alpha: 0.08), genderColor(context, p.gender)),
      child: Text(initials,
          style: TextStyle(
              fontSize: widget.size * 0.4,
              color: Theme.of(context).colorScheme.onSurface)),
    );
    if (p.photo == null) return fallback;
    return FutureBuilder<Object?>(
      future: _future,
      builder: (context, snap) {
        final v = snap.data;
        ImageProvider? img;
        if (v is Uint8List) img = MemoryImage(v);
        if (v is String) img = NetworkImage(v);
        if (img == null) return fallback;
        return CircleAvatar(
          radius: widget.size / 2,
          backgroundColor: genderColor(context, p.gender),
          backgroundImage: img,
        );
      },
    );
  }
}

/// Card height for the tree depends on which fields are shown.
double cardHeightFor(Set<CardField> fields) {
  var h = 16.0 + 26; // padding + name (+ slack)
  if (fields.contains(CardField.photo)) h += 62;
  final textFields = fields.where((f) => f != CardField.photo).length;
  h += textFields * 17;
  return h;
}

const double cardWidth = 156;

class PersonCard extends StatelessWidget {
  final Person person;
  final bool isFocus;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const PersonCard({
    super.key,
    required this.person,
    this.isFocus = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final fields = context.watch<SettingsStore>().cardFields;
    final data = context.watch<TreeStore>().data;
    final l = context.l10n;
    final dates = context.dates;
    final theme = Theme.of(context);
    final p = person;

    final lines = <String>[];
    for (final f in CardField.values) {
      if (!fields.contains(f)) continue;
      String? t;
      switch (f) {
        case CardField.photo:
          continue;
        case CardField.lineage:
          final lin = lineageOf(context, data, p.id, depth: 2, family: false);
          t = lin == p.givenName ? null : lin;
        case CardField.age:
          t = ageText(l, p);
        case CardField.birthDate:
          t = p.birthDate == null ? null : l.bornShort(dates.year(p.birthDate));
        case CardField.deathDate:
          t = p.deathDate == null ? null : l.diedShort(dates.year(p.deathDate));
        case CardField.birthPlace:
          t = p.birthPlace.isEmpty ? null : p.birthPlace;
        case CardField.residence:
          t = p.currentResidence?.place;
        case CardField.tribe:
          t = p.tribe.isEmpty ? null : p.tribe;
        case CardField.kunya:
          t = p.kunya.isEmpty ? null : p.kunya;
      }
      lines.add(t ?? '');
    }

    final border = isFocus
        ? Border.all(color: theme.colorScheme.primary, width: 3)
        : Border.all(color: theme.colorScheme.outlineVariant);

    return Semantics(
      button: true,
      label: p.displayName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Ink(
            decoration: BoxDecoration(
              color: genderColor(context, p.gender),
              borderRadius: BorderRadius.circular(14),
              border: border,
              boxShadow: isFocus
                  ? [
                      BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 14)
                    ]
                  : const [],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fields.contains(CardField.photo)) ...[
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PersonAvatar(person: p, size: 56),
                      if (p.isDeceased)
                        PositionedDirectional(
                          end: -4,
                          bottom: -2,
                          child: Icon(Icons.local_florist,
                              size: 16, color: theme.colorScheme.outline),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  p.displayName.isEmpty ? l.unnamed : p.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                ),
                for (final t in lines)
                  SizedBox(
                    height: 17,
                    child: Text(
                      t,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Searchable dialog for picking a person from the tree.
Future<String?> pickPerson(BuildContext context,
    {String? title, Set<String> exclude = const {}}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PersonPickerDialog(title: title, exclude: exclude),
  );
}

class _PersonPickerDialog extends StatefulWidget {
  final String? title;
  final Set<String> exclude;
  const _PersonPickerDialog({this.title, required this.exclude});

  @override
  State<_PersonPickerDialog> createState() => _PersonPickerDialogState();
}

class _PersonPickerDialogState extends State<_PersonPickerDialog> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<TreeStore>().data;
    final l = context.l10n;
    final q = _q.trim().toLowerCase();
    final list = data.persons.values
        .where((p) => !widget.exclude.contains(p.id))
        .where((p) {
      if (q.isEmpty) return true;
      final hay =
          '${lineageOf(context, data, p.id)} ${p.kunya} ${p.nickname} ${p.tribe}'
              .toLowerCase();
      return hay.contains(q);
    }).toList()
      ..sort((a, b) => a.givenName.compareTo(b.givenName));

    return AlertDialog(
      title: Text(widget.title ?? l.choosePerson),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 420,
        height: 460,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.searchHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text(l.noResults))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final p = list[i];
                        return ListTile(
                          leading: PersonAvatar(person: p, size: 36),
                          title: Text(p.displayName.isEmpty
                              ? l.unnamed
                              : p.displayName),
                          subtitle: Text(
                            lineageOf(context, data, p.id, depth: 3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(context, p.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
      ],
    );
  }
}
