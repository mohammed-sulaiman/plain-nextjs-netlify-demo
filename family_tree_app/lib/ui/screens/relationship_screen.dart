import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../logic/kinship.dart';
import '../../logic/relationship_names.dart';
import '../../models/models.dart';
import '../../state/tree_store.dart';
import '../common.dart';
import '../widgets/person_widgets.dart';

/// "How are these two people related?" — kinship name in both directions,
/// genetic relatedness from the tree, and mahram status.
class RelationshipScreen extends StatefulWidget {
  final String? initialA;
  final String? initialB;
  const RelationshipScreen({super.key, this.initialA, this.initialB});

  @override
  State<RelationshipScreen> createState() => _RelationshipScreenState();
}

class _RelationshipScreenState extends State<RelationshipScreen> {
  String? _a;
  String? _b;

  @override
  void initState() {
    super.initState();
    final store = treeOf(context);
    _a = widget.initialA ?? store.focusId;
    _b = widget.initialB;
    if (_b == _a) _b = null;
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<TreeStore>().data;
    final l = context.l10n;
    final theme = Theme.of(context);
    final a = _a == null ? null : d[_a!];
    final b = _b == null ? null : d[_b!];

    Widget picker(Person? p, String label, ValueChanged<String> onPick) =>
        Expanded(
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final id = await pickPerson(context, title: label);
                if (id != null) onPick(id);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (p == null)
                      const CircleAvatar(radius: 32, child: Icon(Icons.person_search))
                    else
                      PersonAvatar(person: p, size: 64),
                    const SizedBox(height: 8),
                    Text(p?.displayName ?? label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
            ),
          ),
        );

    Widget? results;
    if (a != null && b != null) {
      final calc = KinshipCalculator(d);
      final namer = RelationshipNamer.forLocale(
          Localizations.localeOf(context).languageCode);
      final ab = calc.relation(a.id, b.id);
      final ba = calc.relation(b.id, a.id);
      final r = calc.coefficientOfRelationship(a.id, b.id);
      final mahram = calc.mahram(a.id, b.id);
      final path = ab.type == RelationType.blood ? ab.path : null;

      results = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultCard(
            icon: Icons.diversity_3,
            title: l.relationship,
            children: [
              Text(l.isRelationOf(b.displayName, namer.name(ab, d), a.displayName),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(l.isRelationOf(a.displayName, namer.name(ba, d), b.displayName),
                  style: theme.textTheme.bodyMedium),
              if (path != null) ...[
                const SizedBox(height: 12),
                Text(l.commonAncestor(d[path.commonAncestor]!.displayName),
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                _PathView(path: path, data: d),
              ],
            ],
          ),
          _ResultCard(
            icon: Icons.biotech_outlined,
            title: l.geneticRelatedness,
            children: [
              Row(
                children: [
                  Text('${(r * 100).toStringAsFixed(r * 100 < 1 && r > 0 ? 2 : 1)}%',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: r,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l.geneticRelatednessHint, style: theme.textTheme.bodySmall),
            ],
          ),
          _ResultCard(
            icon: Icons.shield_outlined,
            title: l.mahramStatus,
            children: [
              Text(_mahramText(l, mahram), style: theme.textTheme.titleMedium),
              if (mahram.requiresConsummation) ...[
                const SizedBox(height: 6),
                Text(l.mahramConsummation, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 8),
              Text(l.mahramDisclaimer, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.relationshipCalculator)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  picker(a, l.firstPerson, (id) => setState(() => _a = id)),
                  IconButton(
                    tooltip: l.swap,
                    onPressed: () => setState(() {
                      final t = _a;
                      _a = _b;
                      _b = t;
                    }),
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  picker(b, l.secondPerson, (id) => setState(() => _b = id)),
                ],
              ),
              const SizedBox(height: 8),
              results ??
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l.pickTwoPeople, textAlign: TextAlign.center),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String _mahramText(AppLocalizations l, MahramResult m) {
    switch (m.status) {
      case MahramStatus.mahram:
        switch (m.reason) {
          case MahramReason.milk:
            return l.mahramMilk;
          case MahramReason.marriage:
            return l.mahramMarriage;
          default:
            return l.mahramBlood;
        }
      case MahramStatus.notMahram:
        return l.notMahram;
      case MahramStatus.spouse:
        return l.mahramSpouse;
      case MahramStatus.formerSpouse:
        return l.mahramFormerSpouse;
      case MahramStatus.sameGender:
        return l.mahramSameGender;
      case MahramStatus.unknownGender:
        return l.mahramUnknownGender;
      case MahramStatus.notApplicable:
        return '—';
    }
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _ResultCard(
      {required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.labelLarge),
              ]),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );
}

/// A → … → common ancestor ← … ← B as a chain of chips.
class _PathView extends StatelessWidget {
  final BloodPath path;
  final FamilyData data;
  const _PathView({required this.path, required this.data});

  @override
  Widget build(BuildContext context) {
    final ids = [...path.pathA, ...path.pathB.reversed.skip(1)];
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 6,
      children: [
        for (var i = 0; i < ids.length; i++) ...[
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: PersonAvatar(person: data[ids[i]]!, size: 22),
            label: Text(data[ids[i]]!.givenName),
            side: ids[i] == path.commonAncestor
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
          if (i < ids.length - 1)
            Icon(
              i < path.up
                  ? Icons.north
                  : (rtl ? Icons.south_west : Icons.south_east),
              size: 16,
            ),
        ],
      ],
    );
  }
}
