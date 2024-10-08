import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Because the flutter's [DoubleTapGestureRecognizer] will block the [TapGestureRecognizer]
/// for a while. So we need to implement our own GestureDetector.
@immutable
class SelectionGestureDetector extends StatefulWidget {
  const SelectionGestureDetector({
    super.key,
    this.child,
    this.onTapDown,
    this.onDoubleTapDown,
    this.onTripleTapDown,
    this.onSecondaryTapDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.enablePanImmediate = true,
  });

  @override
  State<SelectionGestureDetector> createState() =>
      SelectionGestureDetectorState();

  final Widget? child;

  final bool enablePanImmediate;

  final GestureTapDownCallback? onTapDown;
  final GestureTapDownCallback? onDoubleTapDown;
  final GestureTapDownCallback? onTripleTapDown;
  final GestureTapDownCallback? onSecondaryTapDown;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
}

class SelectionGestureDetectorState extends State<SelectionGestureDetector> {
  bool _isDoubleTap = false;
  Timer? _doubleTapTimer;
  int _tripleTabCount = 0;
  Timer? _tripleTabTimer;

  final kTripleTapTimeout = const Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        if (widget.enablePanImmediate)
          ImmediateMultiDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                  ImmediateMultiDragGestureRecognizer>(
            () => ImmediateMultiDragGestureRecognizer(),
            (recognizer) {
              recognizer.onStart = (offset) {
                return _ImmediateDrag(
                  offset: offset,
                  onStart: widget.onPanStart,
                  onUpdate: widget.onPanUpdate,
                  onEnd: widget.onPanEnd,
                );
              };
            },
          ),
        if (!widget.enablePanImmediate)
          PanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(
              supportedDevices: {
                // https://docs.flutter.dev/release/breaking-changes/trackpad-gestures#for-gesture-interactions-not-suitable-for-trackpad-usage
                // Exclude PointerDeviceKind.trackpad.
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.stylus,
                PointerDeviceKind.invertedStylus,
              },
            ),
            (recognizer) {
              recognizer
                // ..onStart = widget.onPanStart
                ..onUpdate = widget.onPanUpdate
                ..onEnd = widget.onPanEnd;
            },
          ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (recognizer) {
            recognizer.onTapDown = _tapDownDelegate;
            recognizer.onSecondaryTapDown = widget.onSecondaryTapDown;
          },
        ),
      },
      child: widget.child,
    );
  }

  void _tapDownDelegate(TapDownDetails tapDownDetails) {
    if (_tripleTabCount == 2) {
      _tripleTabCount = 0;
      _tripleTabTimer?.cancel();
      _tripleTabTimer = null;
      if (widget.onTripleTapDown != null) {
        widget.onTripleTapDown!(tapDownDetails);
      }
    } else if (_isDoubleTap) {
      _isDoubleTap = false;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = null;
      if (widget.onDoubleTapDown != null) {
        widget.onDoubleTapDown!(tapDownDetails);
      }
      _tripleTabCount++;
    } else {
      if (widget.onTapDown != null) {
        widget.onTapDown!(tapDownDetails);
      }

      _isDoubleTap = true;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(kDoubleTapTimeout, () {
        _isDoubleTap = false;
        _doubleTapTimer = null;
      });

      _tripleTabCount = 1;
      _tripleTabTimer?.cancel();
      _tripleTabTimer = Timer(kTripleTapTimeout, () {
        _tripleTabCount = 0;
        _tripleTabTimer = null;
      });
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _tripleTabTimer?.cancel();
    super.dispose();
  }
}

// Custom pan gesture recognizer to trigger immediately
// The callbacks in  _ImmediateDrag will be called immediately
class _ImmediateDrag extends Drag {
  _ImmediateDrag({
    required this.offset,
    this.onStart,
    this.onUpdate,
    this.onEnd,
  }) {
    onStart?.call(DragStartDetails(globalPosition: offset));
  }

  final Offset offset;

  final GestureDragStartCallback? onStart;
  final GestureDragUpdateCallback? onUpdate;
  final GestureDragEndCallback? onEnd;

  @override
  void update(DragUpdateDetails details) {
    onUpdate?.call(details);
  }

  @override
  void end(DragEndDetails details) {
    onEnd?.call(details);
  }
}
