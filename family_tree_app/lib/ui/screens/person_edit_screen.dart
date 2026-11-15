import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../../state/tree_store.dart';
import '../common.dart';
import '../widgets/person_widgets.dart';
import 'map_screen.dart';

class PersonEditScreen extends StatefulWidget {
  /// null → brand-new unlinked person.
  final Person? person;
  final bool isNew;
  final String? relativeOf;
  final RelativeType? relativeType;
  final String? otherParentId;

  const PersonEditScreen({
    super.key,
    this.person,
    this.isNew = false,
    this.relativeOf,
    this.relativeType,
    this.otherParentId,
  });

  @override
  State<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends State<PersonEditScreen> {
  final _form = GlobalKey<FormState>();
  late Person _p;
  late bool _isNew;
  Uint8List? _newPhoto;
  bool _saving = false;

  late final _given = TextEditingController(text: _p.givenName);
  late final _family = TextEditingController(text: _p.familyName);
  late final _kunya = TextEditingController(text: _p.kunya);
  late final _nick = TextEditingController(text: _p.nickname);
  late final _tribe = TextEditingController(text: _p.tribe);
  late final _birthPlace = TextEditingController(text: _p.birthPlace);
  late final _notes = TextEditingController(text: _p.notes);

  @override
  void initState() {
    super.initState();
    _isNew = widget.person == null || widget.isNew;
    _p = widget.person ??
        Person(id: treeOf(context).newId(), givenName: '');
  }

  @override
  void dispose() {
    for (final c in [_given, _family, _kunya, _nick, _tribe, _birthPlace, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
        source: source, maxWidth: 512, maxHeight: 512, imageQuality: 82);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _newPhoto = bytes);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final store = treeOf(context);
    final person = _p.copyWith(
      givenName: _given.text.trim(),
      familyName: _family.text.trim(),
      kunya: _kunya.text.trim(),
      nickname: _nick.text.trim(),
      tribe: _tribe.text.trim(),
      birthPlace: _birthPlace.text.trim(),
      notes: _notes.text.trim(),
    );
    try {
      if (_isNew && widget.relativeOf != null && widget.relativeType != null) {
        await store.addRelative(widget.relativeOf!, widget.relativeType!, person,
            photo: _newPhoto, otherParentId: widget.otherParentId);
      } else {
        await store.savePerson(person, newPhoto: _newPhoto);
      }
      if (mounted) Navigator.pop(context, person.id);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.snack('${context.l10n.saveFailed}: $e');
      }
    }
  }

  Future<void> _editResidence([int? index]) async {
    final r = await showDialog<Residence>(
      context: context,
      builder: (_) => _ResidenceDialog(
          initial: index == null ? null : _p.residences[index]),
    );
    if (r == null) return;
    final list = [..._p.residences];
    index == null ? list.add(r) : list[index] = r;
    list.sort((a, b) => (a.from ?? DateTime(0)).compareTo(b.from ?? DateTime(0)));
    setState(() => _p = _p.copyWith(residences: list));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final title = _isNew
        ? (widget.relativeType != null
            ? relativeTypeLabel(l, widget.relativeType!)
            : l.addPerson)
        : l.editPerson;

    InputDecoration deco(String label, {IconData? icon, String? hint}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          border: const OutlineInputBorder(),
        );

    final preview = _newPhoto != null
        ? CircleAvatar(radius: 48, backgroundImage: MemoryImage(_newPhoto!))
        : PersonAvatar(person: _p, size: 96);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(l.save),
            ),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      preview,
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(l.choosePhoto),
                          ),
                          TextButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(l.takePhoto),
                          ),
                          if (_p.photo != null || _newPhoto != null)
                            TextButton.icon(
                              onPressed: () => setState(() {
                                _newPhoto = null;
                                _p = _p.copyWith(clearPhoto: true);
                              }),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l.removePhoto),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _given,
                        decoration: deco(l.givenName, icon: Icons.person_outline),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l.required : null,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _family,
                        decoration: deco(l.familyName),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<Gender>(
                  segments: [
                    for (final g in Gender.values)
                      ButtonSegment(value: g, label: Text(genderLabel(l, g))),
                  ],
                  selected: {_p.gender},
                  onSelectionChanged: (s) =>
                      setState(() => _p = _p.copyWith(gender: s.first)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                          controller: _kunya,
                          decoration: deco(l.fieldKunya, hint: l.kunyaHint)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                          controller: _nick, decoration: deco(l.nickname)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _tribe,
                    decoration: deco(l.fieldTribe, icon: Icons.groups_outlined)),
                const SizedBox(height: 20),
                Text(l.lifeEvents, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                DateField(
                  label: l.fieldBirthDate,
                  value: _p.birthDate,
                  onChanged: (d) => setState(() => _p = d == null
                      ? _p.copyWith(clearBirthDate: true)
                      : _p.copyWith(birthDate: d)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _birthPlace,
                    decoration: deco(l.fieldBirthPlace, icon: Icons.place_outlined)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.deceased),
                  value: _p.isDeceased,
                  onChanged: (v) => setState(() => _p = v
                      ? _p.copyWith(deceased: true)
                      : _p.copyWith(deceased: false, clearDeathDate: true)),
                ),
                if (_p.isDeceased)
                  DateField(
                    label: l.fieldDeathDate,
                    value: _p.deathDate,
                    onChanged: (d) => setState(() => _p = d == null
                        ? _p.copyWith(clearDeathDate: true)
                        : _p.copyWith(deathDate: d)),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: Text(l.residences,
                            style: theme.textTheme.titleMedium)),
                    TextButton.icon(
                      onPressed: () => _editResidence(),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(l.addResidence),
                    ),
                  ],
                ),
                if (_p.residences.isEmpty)
                  Text(l.noResidences, style: theme.textTheme.bodySmall),
                for (var i = 0; i < _p.residences.length; i++)
                  Card(
                    child: ListTile(
                      leading: Icon(_p.residences[i].hasLocation
                          ? Icons.location_on
                          : Icons.location_off_outlined),
                      title: Text(_p.residences[i].place),
                      subtitle: Text(_rangeText(context, _p.residences[i])),
                      onTap: () => _editResidence(i),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _p = _p.copyWith(
                            residences: [..._p.residences]..removeAt(i))),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _notes,
                  decoration: deco(l.notes, icon: Icons.notes),
                  minLines: 2,
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _p.faceConsent,
                  onChanged: (v) =>
                      setState(() => _p = _p.copyWith(faceConsent: v ?? false)),
                  title: Text(l.faceConsent),
                  subtitle: Text(l.faceConsentHint),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _rangeText(BuildContext context, Residence r) {
  final d = context.dates;
  final l = context.l10n;
  if (r.from == null && r.to == null) return '';
  final from = r.from == null ? '…' : d.year(r.from);
  final to = r.to == null ? l.present : d.year(r.to);
  return '$from – $to';
}

/// Date input that shows the chosen date in the selected calendar(s).
class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const DateField(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(1980),
          firstDate: DateTime(1000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialEntryMode: DatePickerEntryMode.input,
          helpText: label,
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: l.clear,
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(value == null ? l.notSet : dates.format(value)),
      ),
    );
  }
}

class _ResidenceDialog extends StatefulWidget {
  final Residence? initial;
  const _ResidenceDialog({this.initial});

  @override
  State<_ResidenceDialog> createState() => _ResidenceDialogState();
}

class _ResidenceDialogState extends State<_ResidenceDialog> {
  late final _place = TextEditingController(text: widget.initial?.place ?? '');
  late Residence _r = widget.initial ?? const Residence(place: '');

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.initial == null ? l.addResidence : l.editResidence),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _place,
                decoration: InputDecoration(
                  labelText: l.placeName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await Navigator.push<PickedLocation>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationPickerScreen(
                        initial: _r.hasLocation ? LatLng(_r.lat!, _r.lng!) : null,
                        initialQuery: _place.text,
                      ),
                    ),
                  );
                  if (picked == null) return;
                  setState(() {
                    _r = _r.copyWith(lat: picked.point.latitude, lng: picked.point.longitude);
                    if (_place.text.trim().isEmpty && picked.label != null) {
                      _place.text = picked.label!;
                    }
                  });
                },
                icon: Icon(_r.hasLocation ? Icons.location_on : Icons.map_outlined),
                label: Text(_r.hasLocation
                    ? '${_r.lat!.toStringAsFixed(3)}, ${_r.lng!.toStringAsFixed(3)}'
                    : l.pickOnMap),
              ),
              const SizedBox(height: 12),
              DateField(
                label: l.fromDate,
                value: _r.from,
                onChanged: (d) => setState(() =>
                    _r = d == null ? _r.copyWith(clearFrom: true) : _r.copyWith(from: d)),
              ),
              const SizedBox(height: 12),
              DateField(
                label: l.toDate,
                value: _r.to,
                onChanged: (d) => setState(() =>
                    _r = d == null ? _r.copyWith(clearTo: true) : _r.copyWith(to: d)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            if (_place.text.trim().isEmpty) return;
            Navigator.pop(context, _r.copyWith(place: _place.text.trim()));
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
