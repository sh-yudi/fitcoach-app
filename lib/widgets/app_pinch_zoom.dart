import 'package:flutter/material.dart';

/// Pinch-to-zoom wrapper for a screen's BODY content.
///
/// Wrap the `body:` of a [Scaffold] so that the screen's AppBar (header) and
/// the shell's bottom NavigationBar (footer) stay fixed at their 100% position
/// while the content in between zooms in on the pinch focal point (1.0×–3.0×,
/// never below 100%). Single-finger gestures (scrolling, tabs, taps) pass
/// straight through because the scale recognizer only claims the arena once
/// two pointers exceed the scale slop — the same mechanism [InteractiveViewer]
/// relies on.
class AppPinchZoom extends StatefulWidget {
  final Widget child;
  const AppPinchZoom({super.key, required this.child});

  @override
  State<AppPinchZoom> createState() => _AppPinchZoomState();
}

class _AppPinchZoomState extends State<AppPinchZoom> {
  static const double _minScale = 1.0;
  static const double _maxScale = 3.0;

  double _scale = 1.0;
  double _startScale = 1.0;
  Offset _translation = Offset.zero;
  Offset _startTranslation = Offset.zero;
  Offset _startFocal = Offset.zero;
  Size _size = Size.zero;

  bool get _zoomed => _scale > 1.001;

  void _onScaleStart(ScaleStartDetails details) {
    _startScale = _scale;
    _startTranslation = _translation;
    _startFocal = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final newScale = (_startScale * details.scale).clamp(_minScale, _maxScale);
    final ratio = newScale / _startScale;
    final focal = details.localFocalPoint;
    final tx = focal.dx - ((_startFocal.dx - _startTranslation.dx) * ratio);
    final ty = focal.dy - ((_startFocal.dy - _startTranslation.dy) * ratio);
    final s = newScale;
    // Keep the scaled content covering the whole body so no background shows.
    final clX = tx.clamp(
      (s - 1) * (focal.dx - _size.width),
      (s - 1) * focal.dx,
    );
    final clY = ty.clamp(
      (s - 1) * (focal.dy - _size.height),
      (s - 1) * focal.dy,
    );
    setState(() {
      _scale = newScale;
      _translation = Offset(clX, clY);
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_scale <= 1.0) {
      setState(() => _translation = Offset.zero);
    }
  }

  void _reset() {
    setState(() {
      _scale = 1.0;
      _translation = Offset.zero;
      _startScale = 1.0;
      _startTranslation = Offset.zero;
      _startFocal = Offset.zero;
    });
  }

  Matrix4 _transform() {
    final m = Matrix4.identity()
      ..translateByDouble(_translation.dx, _translation.dy, 0, 1)
      ..scaleByDouble(_scale, _scale, 1, 1)
      ..translateByDouble(-_startFocal.dx, -_startFocal.dy, 0, 1);
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: bg,
                  child: Transform(
                    transform: _transform(),
                    alignment: Alignment.topLeft,
                    child: widget.child,
                  ),
                ),
                if (_zoomed)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Material(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _reset,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.zoom_out_map,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${(_scale * 100).round()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
