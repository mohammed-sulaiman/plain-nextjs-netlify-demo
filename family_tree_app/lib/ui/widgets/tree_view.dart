import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../logic/tree_layout.dart';
import '../../models/models.dart';
import '../../state/settings_store.dart';
import '../../state/tree_store.dart';
import 'person_widgets.dart';

/// Pan/zoom family tree centred on the focus person.
class FamilyTreeView extends StatefulWidget {
  final void Function(String personId) onPersonTap;
  final void Function(String personId) onPersonDoubleTap;

  /// Wraps the full tree canvas so it can be exported as an image.
  final GlobalKey? captureKey;

  const FamilyTreeView({
    super.key,
    required this.onPersonTap,
    required this.onPersonDoubleTap,
    this.captureKey,
  });

  @override
  State<FamilyTreeView> createState() => FamilyTreeViewState();
}

class FamilyTreeViewState extends State<FamilyTreeView>
    with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  Animation<Matrix4>? _matrixAnim;
  String? _centeredOn;
  Size _viewport = Size.zero;
  TreeLayout? _layout;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_matrixAnim != null) _controller.value = _matrixAnim!.value;
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Smoothly brings the focus person to the middle of the viewport.
  void recenter({bool animate = true, bool fit = false}) {
    final layout = _layout;
    final focus = context.read<TreeStore>().focusId;
    if (layout == null || focus == null || !layout.positions.containsKey(focus)) {
      return;
    }
    final rect = layout.rectOf(focus);
    // On first show, zoom out so as much of the tree as possible is visible.
    final fitScale = math.min(_viewport.width / layout.size.width,
        _viewport.height / layout.size.height);
    final scale = fit
        ? fitScale.clamp(0.55, 1.0)
        : _controller.value.getMaxScaleOnAxis().clamp(0.5, 1.2);
    final yFactor = fit && fitScale >= 0.55 ? 2.0 : 2.6;
    final target = Matrix4.identity()
      ..translateByDouble(
          _viewport.width / 2 - rect.center.dx * scale,
          fit && fitScale >= 0.55
              ? (_viewport.height - layout.size.height * scale) / 2
              : _viewport.height / yFactor - rect.center.dy * scale,
          0,
          1)
      ..scaleByDouble(scale, scale, 1, 1);
    if (!animate) {
      _controller.value = target;
      return;
    }
    _matrixAnim = Matrix4Tween(begin: _controller.value, end: target)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic));
    _anim.forward(from: 0);
  }

  void zoom(double factor) {
    final c = Offset(_viewport.width / 2, _viewport.height / 2);
    final m = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(factor, factor, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
    _controller.value = m * _controller.value;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TreeStore>();
    final settings = context.watch<SettingsStore>();
    final focus = store.focusId;
    if (focus == null) return const SizedBox.shrink();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final cardSize = Size(cardWidth, cardHeightFor(settings.cardFields));
    final layout = TreeLayoutEngine(store.data,
            scope: settings.scope, cardSize: cardSize)
        .layout(focus, rtl: rtl);
    _layout = layout;
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      _viewport = constraints.biggest;
      final key = '$focus|${layout.size}';
      if (_centeredOn != key) {
        final first = _centeredOn == null;
        _centeredOn = key;
        WidgetsBinding.instance
            .addPostFrameCallback(
                (_) => mounted ? recenter(animate: !first, fit: first) : null);
      }
      return InteractiveViewer(
        transformationController: _controller,
        constrained: false,
        minScale: 0.15,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.all(800),
        child: RepaintBoundary(
          key: widget.captureKey,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: layout.size.width,
            height: layout.size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EdgePainter(layout, colors),
                  ),
                ),
                for (final e in layout.positions.entries)
                  Positioned(
                    key: ValueKey(e.key),
                    left: e.value.dx,
                    top: e.value.dy,
                    width: cardSize.width,
                    height: cardSize.height,
                    child: PersonCard(
                      person: store.data[e.key]!,
                      isFocus: e.key == focus,
                      onTap: () => widget.onPersonTap(e.key),
                      onDoubleTap: () => widget.onPersonDoubleTap(e.key),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _EdgePainter extends CustomPainter {
  final TreeLayout layout;
  final ColorScheme colors;
  _EdgePainter(this.layout, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = colors.outline
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final spouse = Paint()
      ..color = colors.tertiary
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final special = Paint()
      ..color = colors.secondary
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (final e in layout.spouseEdges) {
      final ra = layout.rectOf(e.a), rb = layout.rectOf(e.b);
      final left = ra.left < rb.left ? ra : rb;
      final right = ra.left < rb.left ? rb : ra;
      final y = left.center.dy;
      final p1 = Offset(left.right, y), p2 = Offset(right.left, y);
      if (e.status == UnionStatus.married) {
        canvas.drawLine(p1, p2, spouse);
        canvas.drawLine(p1.translate(0, 5), p2.translate(0, 5), spouse);
      } else {
        _dashed(canvas, p1, p2, spouse);
      }
    }

    for (final e in layout.familyEdges) {
      final child = layout.rectOf(e.child);
      final parents = e.parents.map(layout.rectOf).toList();
      Offset anchor;
      if (parents.length >= 2) {
        // Midpoint of the couple's marriage line.
        final xs = parents.map((r) => r.center.dx).toList()..sort();
        anchor = Offset((xs.first + xs.last) / 2, parents.first.center.dy + 2.5);
      } else {
        anchor = parents.first.bottomCenter;
      }
      final parentBottom = parents.first.bottom;
      final midY = parentBottom + (child.top - parentBottom) / 2;
      final path = Path()
        ..moveTo(anchor.dx, anchor.dy)
        ..lineTo(anchor.dx, midY)
        ..lineTo(child.center.dx, midY)
        ..lineTo(child.center.dx, child.top);
      if (e.kind == ParentKind.biological) {
        canvas.drawPath(path, line);
      } else {
        // Dashed for adoptive / milk links.
        final pts = [
          anchor,
          Offset(anchor.dx, midY),
          Offset(child.center.dx, midY),
          child.topCenter,
        ];
        for (var i = 0; i < pts.length - 1; i++) {
          _dashed(canvas, pts[i], pts[i + 1], special);
        }
      }
    }
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint p) {
    const dash = 6.0, gap = 4.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final end = (d + dash).clamp(0, total).toDouble();
      c.drawLine(a + dir * d, a + dir * end, p);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) =>
      old.layout != layout || old.colors != colors;
}
