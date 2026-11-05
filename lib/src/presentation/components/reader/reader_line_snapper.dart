import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Computes a scroll offset for a page turn that lands on a text-line
/// boundary, so no line is repeated, skipped or half cut after the turn.
///
/// Returns null when no text lines are found (the caller should fall back to
/// a plain proportional scroll).
double? snapTurnTarget({
  required BuildContext scrollContext,
  required ScrollPosition position,
  required bool forward,
  required EdgeInsets insets,
}) {
  final scrollBox = scrollContext.findRenderObject();
  if (scrollBox is! RenderBox || !scrollBox.attached) return null;

  // Line [top, bottom] ranges in viewport coordinates (0 = viewport top).
  final lines = <_Line>[];
  void visit(RenderObject object) {
    if (object is RenderParagraph && object.attached && object.hasSize) {
      final length = object.text.toPlainText().length;
      final boxes = length == 0
          ? const <TextBox>[]
          : object.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: length),
            );
      if (boxes.isNotEmpty) {
        final origin = object.localToGlobal(
          Offset.zero,
          ancestor: scrollBox,
        );
        // Merge per-run boxes into one [top, bottom] range per visual line.
        final seen = <int>{};
        for (final b in boxes) {
          if (b.bottom - b.top < 1) continue;
          if (seen.add(b.top.round())) {
            lines.add(_Line(origin.dy + b.top, origin.dy + b.bottom));
          }
        }
      }
    }
    object.visitChildren(visit);
  }

  scrollBox.visitChildren(visit);
  if (lines.isEmpty) return null;
  lines.sort((a, b) => a.top.compareTo(b.top));

  const eps = 0.75;
  final windowTop = insets.top;
  final windowBottom = position.viewportDimension - insets.bottom;
  final visibleHeight = windowBottom - windowTop;
  if (visibleHeight <= 0) return null;

  double? delta; // how far content moves (positive = scroll forward)
  if (forward) {
    // First line not fully inside the window becomes the first visible line.
    for (final l in lines) {
      if (l.bottom > windowBottom + eps && l.top > windowTop + eps) {
        delta = l.top - windowTop;
        break;
      }
    }
  } else {
    // First fully visible line must become the last line of the previous page.
    double? firstFull;
    for (final l in lines) {
      if (l.top >= windowTop - eps) {
        firstFull = l.top;
        break;
      }
    }
    if (firstFull == null) return null;
    final desiredTop = firstFull - visibleHeight; // viewport coords
    // Smallest line top at or after desiredTop, so no line is cut at the top.
    for (final l in lines) {
      if (l.top >= desiredTop - eps) {
        // Move content so that line l sits at windowTop.
        delta = l.top - windowTop;
        break;
      }
    }
    // Lines above the viewport are only measurable if built; if the page
    // start isn't built we have no data, so let the caller fall back.
    if (delta == null || delta >= 0) return null;
  }
  if (delta == null || delta == 0) return null;
  return (position.pixels + delta).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
}

class _Line {
  const _Line(this.top, this.bottom);
  final double top;
  final double bottom;
}
