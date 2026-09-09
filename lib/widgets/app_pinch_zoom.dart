import 'package:flutter/material.dart';

/// Pinch-to-zoom wrapper for a screen's BODY content.
///
/// Wrap the `body:` of a [Scaffold] so that the screen's AppBar (header) and
/// the shell's bottom NavigationBar (footer) stay fixed at their 100% position.
///
/// Zooming is CENTER-anchored (1.0×–3.0×, never below 100%): the content always
/// scales around the middle of the visible area, so it never drifts or slides
/// off screen and the whole view stays fully covered — no blank edges. It can
/// never be zoomed out below 100%. Tapping the floating zoom chip resets to
/// 100%. Single-finger gestures (scrolling, tabs, taps) pass straight through
/// because the scale recognizer only claims the arena once two pointers exceed
/// the scale slop — the same mechanism [InteractiveViewer] relies on.
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
  Size _size = Size.zero;

  bool get _zoomed => _scale > 1.001;

  void _onScaleStart(ScaleStartDetails details) {
    _startScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final newScale = (_startScale * details.scale).clamp(_minScale, _maxScale);
    if (newScale == _scale) return;
    setState(() => _scale = newScale);
  }

  void _reset() {
    setState(() => _scale = 1.0);
  }

  /// Center-anchored transform: `p' = p * scale + center * (1 - scale)`.
  ///
  /// The content's centre maps to the body's centre at every zoom level, and
  /// because it also fills the body, the scaled view always covers the whole
  /// visible area (no background / blank strips ever show).
  Matrix4 _transform() {
    final tx = _size.width / 2 * (1 - _scale);
    final ty = _size.height / 2 * (1 - _scale);
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(_scale, _scale, 1, 1);
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