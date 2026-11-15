import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../services/cloud.dart';
import '../../state/tree_store.dart';
import '../common.dart';
import '../widgets/person_widgets.dart';
import 'person_detail_screen.dart';
import 'settings_screen.dart';

/// Ranks family members by facial resemblance to one person.
class FaceSimilarityScreen extends StatefulWidget {
  final String personId;
  const FaceSimilarityScreen({super.key, required this.personId});

  @override
  State<FaceSimilarityScreen> createState() => _FaceSimilarityScreenState();
}

class _FaceSimilarityScreenState extends State<FaceSimilarityScreen> {
  final _service = FaceSimilarityService();
  List<FaceComparison>? _results;
  bool _busy = false;
  String? _error;

  Future<void> _run() async {
    final d = treeOf(context).data;
    final l = context.l10n;
    final source = d[widget.personId]!;
    final targets = d.persons.values.where((p) => p.id != source.id).toList();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _service.compareMany(source, targets);
      setState(() => _results = r);
    } on FaceSimilarityException catch (e) {
      setState(() => _error = switch (e.code) {
            'not_configured' => l.faceNotConfigured,
            'not_signed_in' => l.faceNotSignedIn,
            'no_consent' => l.faceNoConsent,
            'no_face' => l.faceNoFace,
            _ => '${l.faceFailed}${e.detail == null ? '' : ' (${e.detail})'}',
          });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<TreeStore>().data;
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = d[widget.personId];
    if (p == null) return Scaffold(appBar: AppBar());
    final eligible = d.persons.values
        .where((x) => x.id != p.id && x.faceConsent && x.photo != null)
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(l.faceSimilarity)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: PersonAvatar(person: p, size: 120)),
              const SizedBox(height: 8),
              Text(p.displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.privacy_tip_outlined),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l.facePrivacy)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(l.faceEligible(eligible), style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _run,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.face_retouching_natural),
                label: Text(l.findLookalikes),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                if (!CloudConfig.isConfigured ||
                    CloudConfig.client?.auth.currentUser == null)
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    child: Text(l.openSettings),
                  ),
              ],
              if (_results != null) ...[
                const SizedBox(height: 16),
                if (_results!.isEmpty) Text(l.noResults),
                for (final r in _results!)
                  if (d[r.personId] != null)
                    Card(
                      child: ListTile(
                        leading: PersonAvatar(person: d[r.personId]!, size: 44),
                        title: Text(d[r.personId]!.displayName),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: LinearProgressIndicator(
                            value: r.similarity / 100,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        trailing: Text('${r.similarity.toStringAsFixed(0)}%',
                            style: theme.textTheme.titleMedium),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    PersonDetailScreen(personId: r.personId))),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
