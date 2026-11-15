import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../data/sample_data.dart';
import '../../logic/gedcom.dart';
import '../../models/models.dart';
import '../../state/account.dart';
import '../../state/tree_store.dart';
import '../common.dart';
import '../widgets/display_options.dart';
import '../widgets/person_widgets.dart';
import '../widgets/tree_view.dart';
import 'map_screen.dart';
import 'person_detail_screen.dart';
import 'person_edit_screen.dart';
import 'relationship_screen.dart';
import 'sharing_screens.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Menu { importGed, exportGed, exportPdf, exportPng, sample, settings }

class _HomeScreenState extends State<HomeScreen> {
  final _treeKey = GlobalKey<FamilyTreeViewState>();
  final _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Opened from an invite link: go straight to the join screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final account = context.read<AccountController>();
      final code = account.pendingInvite;
      if (code == null) return;
      account.pendingInvite = null;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => JoinTreeScreen(initialCode: code)));
    });
  }

  void _openDetails(String id) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: id)));

  Future<void> _personActions(String id) async {
    final store = treeOf(context);
    final p = store.data[id]!;
    final l = context.l10n;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: PersonAvatar(person: p, size: 44),
                title: Text(p.displayName.isEmpty ? l.unnamed : p.displayName,
                    style: Theme.of(ctx).textTheme.titleMedium),
                subtitle: Text(lineageOf(ctx, store.data, id)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.center_focus_strong),
                title: Text(l.setAsFocus),
                onTap: () {
                  Navigator.pop(ctx);
                  store.setFocus(id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(l.viewDetails),
                onTap: () {
                  Navigator.pop(ctx);
                  _openDetails(id);
                },
              ),
              if (store.canEdit) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l.edit),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PersonEditScreen(person: p)));
                  },
                ),
                const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(l.addRelative,
                      style: Theme.of(ctx).textTheme.labelLarge),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in RelativeType.values)
                      ActionChip(
                        avatar: const Icon(Icons.person_add_alt, size: 18),
                        label: Text(relativeTypeLabel(l, t)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          addRelativeFlow(context, id, t);
                        },
                      ),
                  ],
                ),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _menu(_Menu m) async {
    final l = context.l10n;
    final store = treeOf(context);
    switch (m) {
      case _Menu.settings:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      case _Menu.sample:
        await _loadSample();
      case _Menu.exportGed:
        final text = Gedcom.export(store.data);
        await FilePicker.saveFile(
          fileName: 'family_tree.ged',
          bytes: utf8.encode(text),
          mimeType: 'text/plain',
        );
      case _Menu.importGed:
        final file = await FilePicker.pickFile(
            type: FileType.custom, allowedExtensions: ['ged']);
        if (file == null) return;
        final text = utf8.decode(await file.xFile.readAsBytes(),
            allowMalformed: true);
        final imported = Gedcom.import(text);
        if (!mounted) return;
        if (imported.isEmpty) {
          context.snack(l.importEmpty);
          return;
        }
        final merge = store.data.isEmpty
            ? false
            : await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.importTitle),
                  content: Text(l.importQuestion(imported.persons.length)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l.importReplace)),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l.importMerge)),
                  ],
                ),
              );
        if (merge == null) return;
        merge ? await store.merge(imported) : await store.replaceAll(imported);
        if (mounted) context.snack(l.importDone(imported.persons.length));
      case _Menu.exportPng:
      case _Menu.exportPdf:
        final png = await _captureTree();
        if (png == null) return;
        if (m == _Menu.exportPng) {
          await FilePicker.saveFile(
              fileName: 'family_tree.png', bytes: png, mimeType: 'image/png');
        } else {
          final doc = pw.Document();
          final image = pw.MemoryImage(png);
          final w = image.width!.toDouble(), h = image.height!.toDouble();
          doc.addPage(pw.Page(
            pageFormat: PdfPageFormat(w, h, marginAll: 0),
            build: (_) => pw.Image(image),
          ));
          await Printing.sharePdf(
              bytes: await doc.save(), filename: 'family_tree.pdf');
        }
    }
  }

  Future<Uint8List?> _captureTree() async {
    final boundary = _captureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final size = boundary.size;
    // Keep the bitmap within sensible memory limits for huge trees.
    final ratio = (6000 / (size.longestSide == 0 ? 1 : size.longestSide))
        .clamp(0.5, 2.0);
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _loadSample() async {
    final store = treeOf(context);
    final sample = sampleFamily();
    store.data.isEmpty ? await store.replaceAll(sample) : await store.merge(sample);
    final ahmed = store.data.persons.values
        .where((p) => p.givenName == 'أحمد' && p.familyName == 'الحسني');
    if (ahmed.isNotEmpty) store.setFocus(ahmed.last.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TreeStore>();
    final account = context.watch<AccountController>();
    final l = context.l10n;
    final focus = store.focusId == null ? null : store.data[store.focusId!];
    final cloud = account.cloudTree;
    final treeName = cloud?.treeName;

    return Scaffold(
      appBar: AppBar(
        title: cloud == null
            ? Text(l.appTitle)
            : InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TreesScreen())),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          treeName == null || treeName.isEmpty
                              ? l.appTitle
                              : treeName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                      if (!store.canEdit) ...[
                        const SizedBox(width: 4),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar:
                              const Icon(Icons.visibility_outlined, size: 16),
                          label: Text(l.viewOnly),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
        actions: [
          if (store.isCloud)
            IconButton(
              tooltip: l.shareTree,
              icon: const Icon(Icons.group_add_outlined),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShareTreeScreen())),
            ),
          IconButton(
            tooltip: l.search,
            icon: const Icon(Icons.search),
            onPressed: store.data.isEmpty
                ? null
                : () async {
                    final id = await pickPerson(context, title: l.search);
                    if (id != null) store.setFocus(id);
                  },
          ),
          IconButton(
            tooltip: l.displayOptions,
            icon: const Icon(Icons.tune),
            onPressed: () => showDisplayOptions(context),
          ),
          IconButton(
            tooltip: l.relationshipCalculator,
            icon: const Icon(Icons.diversity_3),
            onPressed: store.data.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RelationshipScreen())),
          ),
          IconButton(
            tooltip: l.familyMap,
            icon: const Icon(Icons.map_outlined),
            onPressed: store.data.isEmpty
                ? null
                : () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MapScreen())),
          ),
          PopupMenuButton<_Menu>(
            onSelected: _menu,
            itemBuilder: (_) => [
              if (store.canEdit)
                PopupMenuItem(
                    value: _Menu.importGed, child: Text(l.importGedcom)),
              PopupMenuItem(value: _Menu.exportGed, child: Text(l.exportGedcom)),
              PopupMenuItem(value: _Menu.exportPdf, child: Text(l.exportPdf)),
              PopupMenuItem(value: _Menu.exportPng, child: Text(l.exportImage)),
              if (store.canEdit)
                PopupMenuItem(value: _Menu.sample, child: Text(l.loadSample)),
              const PopupMenuDivider(),
              PopupMenuItem(value: _Menu.settings, child: Text(l.settings)),
            ],
          ),
        ],
      ),
      body: store.loading
          ? const Center(child: CircularProgressIndicator())
          : store.data.isEmpty
              ? _EmptyState(onSample: _loadSample, canEdit: store.canEdit)
              : Stack(
                  children: [
                    FamilyTreeView(
                      key: _treeKey,
                      captureKey: _captureKey,
                      onPersonTap: _personActions,
                      onPersonDoubleTap: (id) => store.setFocus(id),
                    ),
                    if (focus != null)
                      PositionedDirectional(
                        start: 12,
                        top: 12,
                        child: _FocusChip(person: focus, onTap: () => _openDetails(focus.id)),
                      ),
                    PositionedDirectional(
                      end: 12,
                      bottom: 96,
                      child: Column(
                        children: [
                          _RoundButton(
                              icon: Icons.add,
                              tooltip: l.zoomIn,
                              onTap: () => _treeKey.currentState?.zoom(1.25)),
                          const SizedBox(height: 8),
                          _RoundButton(
                              icon: Icons.remove,
                              tooltip: l.zoomOut,
                              onTap: () => _treeKey.currentState?.zoom(0.8)),
                          const SizedBox(height: 8),
                          _RoundButton(
                              icon: Icons.my_location,
                              tooltip: l.recenter,
                              onTap: () => _treeKey.currentState?.recenter()),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: store.data.isEmpty || !store.canEdit
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PersonEditScreen())),
              icon: const Icon(Icons.person_add),
              label: Text(l.addPerson),
            ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
      tooltip: tooltip, onPressed: onTap, icon: Icon(icon));
}

class _FocusChip extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;
  const _FocusChip({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 14, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonAvatar(person: person, size: 28),
              const SizedBox(width: 8),
              Text('${l.focusLabel}: ${person.displayName}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onSample;
  final bool canEdit;
  const _EmptyState({required this.onSample, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined,
                  size: 88, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(l.emptyTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(canEdit ? l.emptyBody : l.emptyViewOnly,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (canEdit) ...[
              FilledButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PersonEditScreen())),
                icon: const Icon(Icons.person_add),
                label: Text(l.addFirstPerson),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onSample,
                icon: const Icon(Icons.auto_awesome),
                label: Text(l.loadSample),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the edit screen for a new relative of [baseId].
Future<void> addRelativeFlow(
    BuildContext context, String baseId, RelativeType type) async {
  final store = treeOf(context);
  final l = context.l10n;
  final d = store.data;
  final base = d[baseId]!;

  if ((type == RelativeType.brother || type == RelativeType.sister) &&
      d.parentsOf(baseId, kinds: {ParentKind.biological}).isEmpty) {
    context.snack(l.needParentsForSibling);
    return;
  }

  String? otherParent;
  if (type == RelativeType.son || type == RelativeType.daughter) {
    final spouses = d.spousesOf(baseId);
    if (spouses.length == 1) {
      otherParent = spouses.first;
    } else if (spouses.length > 1) {
      otherParent = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(l.chooseOtherParent),
          children: [
            for (final s in spouses)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, s),
                child: Text(d[s]!.displayName),
              ),
          ],
        ),
      );
    }
  }

  final gender = switch (type) {
    RelativeType.father ||
    RelativeType.son ||
    RelativeType.husband ||
    RelativeType.brother =>
      Gender.male,
    _ => Gender.female,
  };
  // Children and siblings inherit the family name along the paternal line.
  final inheritsFamily = type == RelativeType.brother ||
      type == RelativeType.sister ||
      type == RelativeType.father ||
      ((type == RelativeType.son || type == RelativeType.daughter) &&
          base.gender == Gender.male);
  final template = Person(
    id: store.newId(),
    givenName: '',
    gender: gender,
    familyName: inheritsFamily ? base.familyName : '',
    tribe: inheritsFamily ? base.tribe : '',
  );
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PersonEditScreen(
        person: template,
        isNew: true,
        relativeOf: baseId,
        relativeType: type,
        otherParentId: otherParent,
      ),
    ),
  );
}

