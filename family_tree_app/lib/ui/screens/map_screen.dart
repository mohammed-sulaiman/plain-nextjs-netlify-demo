import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/tree_store.dart';
import '../common.dart';
import '../widgets/person_widgets.dart';
import 'person_detail_screen.dart';

const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _userAgent = 'com.familytree.family_tree';

TileLayer _tiles() => TileLayer(
      urlTemplate: _tileUrl,
      userAgentPackageName: _userAgent,
    );

Widget _attribution() => const RichAttributionWidget(
      attributions: [TextSourceAttribution('OpenStreetMap contributors')],
    );

/// Map of where family members lived. With [personId], shows one person's
/// moves connected in chronological order.
class MapScreen extends StatelessWidget {
  final String? personId;
  const MapScreen({super.key, this.personId});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<TreeStore>().data;
    final l = context.l10n;
    final persons = personId == null
        ? data.persons.values.toList()
        : [if (data[personId!] != null) data[personId!]!];

    // Group people by location so one marker lists everyone who lived there.
    final groups = <String, List<(Person, Residence)>>{};
    for (final p in persons) {
      for (final r in p.residences.where((r) => r.hasLocation)) {
        final key = '${r.lat!.toStringAsFixed(3)},${r.lng!.toStringAsFixed(3)}';
        groups.putIfAbsent(key, () => []).add((p, r));
      }
    }
    final points = groups.values
        .map((g) => LatLng(g.first.$2.lat!, g.first.$2.lng!))
        .toList();
    final route = personId == null
        ? <LatLng>[]
        : persons.first.residences
            .where((r) => r.hasLocation)
            .map((r) => LatLng(r.lat!, r.lng!))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(personId == null
            ? l.familyMap
            : '${l.familyMap} — ${persons.first.displayName}'),
      ),
      body: points.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.noMapData, textAlign: TextAlign.center),
              ),
            )
          : FlutterMap(
              options: MapOptions(
                initialCameraFit: points.length == 1
                    ? null
                    : CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(60),
                        maxZoom: 10),
                initialCenter: points.first,
                initialZoom: 8,
              ),
              children: [
                _tiles(),
                if (route.length > 1)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 3,
                      color: Theme.of(context).colorScheme.primary,
                      pattern: const StrokePattern.dotted(),
                    ),
                  ]),
                MarkerLayer(
                  markers: [
                    for (final g in groups.values)
                      Marker(
                        point: LatLng(g.first.$2.lat!, g.first.$2.lng!),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _showGroup(context, g),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.location_on,
                                  size: 44,
                                  color: Theme.of(context).colorScheme.primary),
                              Positioned(
                                top: 6,
                                child: Text('${g.map((e) => e.$1.id).toSet().length}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                _attribution(),
              ],
            ),
    );
  }

  void _showGroup(BuildContext context, List<(Person, Residence)> g) {
    final dates = context.datesRead;
    final l = context.l10n;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(g.first.$2.place,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final (p, r) in g)
              ListTile(
                leading: PersonAvatar(person: p, size: 36),
                title: Text(p.displayName),
                subtitle: Text([
                  if (r.from != null) dates.year(r.from),
                  if (r.from != null || r.to != null)
                    r.to == null ? l.present : dates.year(r.to),
                ].join(' – ')),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PersonDetailScreen(personId: p.id)));
                },
              ),
          ],
        ),
      ),
    );
  }
}

class PickedLocation {
  final LatLng point;
  final String? label;
  const PickedLocation(this.point, this.label);
}

/// Tap to drop a pin, or search a place name (OpenStreetMap Nominatim).
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  final String? initialQuery;
  const LocationPickerScreen({super.key, this.initial, this.initialQuery});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  late final _query = TextEditingController(text: widget.initialQuery ?? '');
  LatLng? _point;
  String? _label;
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _point = widget.initial;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'json',
        'limit': '6',
        'accept-language': lang,
      });
      final res = await http.get(uri, headers: {'User-Agent': _userAgent});
      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      setState(() => _results = list);
    } catch (_) {
      if (mounted) context.snack(context.l10n.searchFailed);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.pickOnMap),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton(
              onPressed: _point == null
                  ? null
                  : () => Navigator.pop(context, PickedLocation(_point!, _label)),
              child: Text(l.done),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: l.searchPlace,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _search),
              ),
            ),
          ),
          if (_results.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView(
                children: [
                  for (final r in _results)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(r['display_name'] as String? ?? '',
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        final p = LatLng(double.parse(r['lat'] as String),
                            double.parse(r['lon'] as String));
                        setState(() {
                          _point = p;
                          _label = (r['display_name'] as String?)
                              ?.split(',')
                              .first
                              .trim();
                          _results = [];
                        });
                        _map.move(p, 11);
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _point ?? const LatLng(29, 42),
                initialZoom: _point == null ? 4 : 10,
                onTap: (_, p) => setState(() {
                  _point = p;
                  _label = null;
                }),
              ),
              children: [
                _tiles(),
                if (_point != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _point!,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.location_on,
                          size: 44, color: Theme.of(context).colorScheme.error),
                    ),
                  ]),
                _attribution(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
