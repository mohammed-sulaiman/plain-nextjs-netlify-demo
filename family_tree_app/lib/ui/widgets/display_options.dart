import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/settings_store.dart';
import '../common.dart';

/// Bottom sheet that chooses what each card shows and how much of the
/// family appears around the focus person.
Future<void> showDisplayOptions(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _DisplayOptionsSheet(),
  );
}

class _DisplayOptionsSheet extends StatelessWidget {
  const _DisplayOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final l = context.l10n;
    final theme = Theme.of(context);
    final scope = s.scope;

    Widget depth(String label, int value, void Function(int) onChanged) => Row(
          children: [
            Expanded(child: Text(label)),
            IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
                width: 28,
                child: Text('$value',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium)),
            IconButton(
              onPressed: value < 8 ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.cardContents, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in CardField.values)
                  FilterChip(
                    label: Text(cardFieldLabel(l, f)),
                    selected: s.cardFields.contains(f),
                    onSelected: (v) => s.toggleField(f, v),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l.treeScope, style: theme.textTheme.titleMedium),
            depth(l.ancestorGenerations, scope.ancestorDepth,
                (v) => s.setScope(scope.copyWith(ancestorDepth: v))),
            depth(l.descendantGenerations, scope.descendantDepth,
                (v) => s.setScope(scope.copyWith(descendantDepth: v))),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.showSiblings),
              value: scope.showSiblings,
              onChanged: (v) => s.setScope(scope.copyWith(showSiblings: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.showUnclesAunts),
              value: scope.showUnclesAunts,
              onChanged: (v) => s.setScope(scope.copyWith(showUnclesAunts: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.showSpouses),
              value: scope.showSpouses,
              onChanged: (v) => s.setScope(scope.copyWith(showSpouses: v)),
            ),
            const SizedBox(height: 8),
            Text(l.treeHint, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
