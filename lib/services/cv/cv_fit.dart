import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Fits a CV design to exactly one full page, whatever the amount of text.
///
/// Every template draws a single A4 page. With fixed font sizes a short CV
/// left a wide empty band in the middle of the page (the declaration sits at
/// the bottom), and a long one silently lost its last lines, because the
/// `pdf` package clips whatever does not fit.
///
/// Instead, each page now picks one scale for everything on it - text, gaps
/// and photo alike - so that the content fills the page: a short CV grows, a
/// long one shrinks. The scale is found by laying the page out a few times
/// (layout only, nothing is drawn) and keeping the largest one at which no
/// column overflows. Any room still left is shared between the gaps between
/// sections, so the page reads as evenly filled rather than having one hole.
///
/// How a template uses it:
///
/// * [page] wraps everything the page draws, and picks the scale.
/// * [column] replaces a `pw.Column` whose content flows down the page. Its
///   footer (declaration and signature) stays at the bottom.
/// * [scaled] scales a block that sizes itself, such as a coloured banner.
/// * [gap] is the space between two sections, which may grow.
class CvFit {
  const CvFit._();

  /// Scale used for a very long CV. Any smaller and body text drops below
  /// about 7.5 pt, which stops being comfortable to read on paper; a CV that
  /// still does not fit is cut off, and [CvFitResult.cutOff] says so.
  static const double minScale = 0.8;

  /// Scale used for a short CV: body text tops out around 12 pt, the size a
  /// printed CV normally uses.
  static const double maxScale = 1.3;

  /// A section gap grows by at most this many times its own height, so a
  /// very short CV spreads out a little instead of scattering its sections
  /// down the page. Room beyond that sits above the footer.
  static const double gapGrowth = 2;

  static final Expando<CvFitResult> _results = Expando<CvFitResult>();

  /// How the page of [document] was fitted, or null when it used no [page].
  /// Only known once the document has been laid out, i.e. after `save()`.
  static CvFitResult? resultOf(PdfDocument document) => _results[document];

  /// The root of a page. [build] is called once for every scale tried, so it
  /// must return a fresh widget tree each time.
  static pw.Widget page(pw.Widget Function() build) => _CvPage(build);

  /// Fills the height it is given: [body] from the top and [footer] at the
  /// bottom, with spare room shared between the [gap]s in [body].
  static pw.Widget column({
    required List<pw.Widget> body,
    List<pw.Widget> footer = const [],
  }) {
    return _CvColumn(body, footer);
  }

  /// Scales [child] along with the rest of the page, at its natural height.
  static pw.Widget scaled({required pw.Widget child}) {
    return _CvColumn([child], const []);
  }

  /// The space between two sections of a [column].
  static pw.Widget gap(double height) => _CvGap(height);
}

/// What [CvFit.page] settled on for one page.
class CvFitResult {
  const CvFitResult({required this.scale, required this.cutOff});

  /// Factor every size on the page was multiplied by: above 1 for a short
  /// CV, below 1 for a long one.
  final double scale;

  /// True when the content did not fit even at [CvFit.minScale], so the end
  /// of a column is missing from the page.
  final bool cutOff;
}

/// The scale a page is being laid out at, handed down to every column on it
/// through the layout context.
class _CvScale extends pw.Inherited {
  _CvScale(this.factor, {this.probe = false});

  final double factor;

  /// True while [CvFit.page] is only trying this scale out: columns then
  /// measure their content but skip building it.
  final bool probe;

  /// Set by any column whose content is taller than the room it was given.
  bool overflowed = false;
}

class _CvPage extends pw.SingleChildWidget {
  _CvPage(this.build);

  final pw.Widget Function() build;

  _CvScale? _scale;

  pw.Widget? _content;

  @override
  pw.Widget? get child => _content;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    bool fits(double factor) {
      final probe = _CvScale(factor, probe: true);
      build().layout(
        context.inheritFrom(probe),
        constraints,
        parentUsesSize: true,
      );
      return !probe.overflowed;
    }

    // Most CVs are short and fit at the largest scale on the first try.
    // Otherwise bisect: six rounds pin the scale down to under 1%, which is
    // finer than the eye can tell apart on paper.
    var best = CvFit.minScale;
    if (fits(CvFit.maxScale)) {
      best = CvFit.maxScale;
    } else if (fits(CvFit.minScale)) {
      var low = CvFit.minScale;
      var high = CvFit.maxScale;
      for (var i = 0; i < 6; i++) {
        final mid = (low + high) / 2;
        if (fits(mid)) {
          low = mid;
        } else {
          high = mid;
        }
      }
      best = low;
    }

    final scale = _CvScale(best);
    _scale = scale;
    _content = build();
    super.layout(
      context.inheritFrom(scale),
      constraints,
      parentUsesSize: parentUsesSize,
    );
    final result = CvFitResult(scale: best, cutOff: scale.overflowed);
    CvFit._results[context.document] = result;
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    paintChild(context.inheritFrom(_scale!));
  }
}

class _CvColumn extends pw.SingleChildWidget {
  _CvColumn(this.body, this.footer);

  final List<pw.Widget> body;

  final List<pw.Widget> footer;

  pw.Widget? _content;

  @override
  pw.Widget? get child => _content;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    _content = _build(context, constraints);
    super.layout(context, constraints, parentUsesSize: parentUsesSize);
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    paintChild(context);
  }

  pw.Widget _build(pw.Context context, pw.BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) {
      // Nothing to scale against: behave like the plain column it replaced.
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [...body, ...footer],
      );
    }
    final scale = context.dependsOn<_CvScale>();
    final factor = scale?.factor ?? 1.0;
    final width = constraints.maxWidth;
    final inner = width / factor;
    final bodyHeight = _measure(context, body, inner);
    final footerHeight = _measure(context, footer, inner);
    final natural = bodyHeight + footerHeight;

    // A column beside a sidebar or under a banner has a height to fill; a
    // banner itself has none, and simply takes its natural height.
    final bounded = constraints.hasBoundedHeight;
    final height = bounded ? constraints.maxHeight : natural * factor;
    if (natural * factor > height + 0.5) scale?.overflowed = true;
    if (scale != null && scale.probe) {
      // While the page is still searching for its scale only the size counts.
      return pw.SizedBox(width: width, height: height);
    }

    // The content is laid out in a box 1/factor the size of this one and then
    // drawn scaled up by factor, so text, gaps and photo all grow alike. A
    // transform does not clip, so a border on the edge is still drawn whole.
    final virtualHeight = height / factor;
    final room = math.max(0.0, virtualHeight - natural);
    return pw.SizedBox(
      width: width,
      height: height,
      child: pw.OverflowBox(
        alignment: pw.Alignment.topLeft,
        minWidth: inner,
        maxWidth: inner,
        minHeight: virtualHeight,
        maxHeight: virtualHeight,
        child: pw.Transform.scale(
          scale: factor,
          alignment: pw.Alignment.topLeft,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: _arrange(room),
          ),
        ),
      ),
    );
  }

  double _measure(pw.Context context, List<pw.Widget> widgets, double width) {
    if (widgets.isEmpty) return 0;
    final column = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
    column.layout(
      context,
      pw.BoxConstraints(maxWidth: width),
      parentUsesSize: true,
    );
    return column.box!.height;
  }

  /// The children to draw: [body] with every gap widened by an equal share
  /// of [room] (up to [CvFit.gapGrowth] times its height), then [footer],
  /// pushed to the bottom by whatever room is left over.
  List<pw.Widget> _arrange(double room) {
    final gaps = body.whereType<_CvGap>().length;
    final slots = gaps + (footer.isEmpty ? 0 : 1);
    final share = slots == 0 ? 0.0 : room / slots;
    return [
      for (final widget in body) _grow(widget, share),
      if (footer.isNotEmpty) ...[pw.Spacer(), ...footer],
    ];
  }

  pw.Widget _grow(pw.Widget widget, double share) {
    if (widget is! _CvGap) return widget;
    final extra = math.min(share, widget.height * CvFit.gapGrowth);
    return pw.SizedBox(height: widget.height + extra);
  }
}

/// Space between two sections: drawn at [height], and widened by
/// [CvFit.column] when the page has room to spare.
class _CvGap extends pw.StatelessWidget {
  _CvGap(this.height);

  final double height;

  @override
  pw.Widget build(pw.Context context) => pw.SizedBox(height: height);
}
