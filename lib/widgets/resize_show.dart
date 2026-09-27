import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

enum ResizeStage { reading, resizing, saving, saved }

/// Full-screen processing and gallery-save animation for Photo Resize.
class ResizeShow extends StatefulWidget {
  const ResizeShow({
    super.key,
    required this.stage,
    required this.photo,
    this.savedKb,
  });

  final ResizeStage stage;
  final Uint8List? photo;
  final double? savedKb;

  @override
  State<ResizeShow> createState() => _ResizeShowState();
}

class _ResizeShowState extends State<ResizeShow> with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _scan;
  late final AnimationController _save;
  late final AnimationController _done;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _save = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _done = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.stage == ResizeStage.saving) _save.forward();
    if (widget.stage == ResizeStage.saved) {
      _save.value = 1;
      _done.forward();
    }
  }

  @override
  void didUpdateWidget(ResizeShow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stage == ResizeStage.saving &&
        oldWidget.stage != ResizeStage.saving) {
      _save.forward(from: 0);
    }
    if (widget.stage == ResizeStage.saved &&
        oldWidget.stage != ResizeStage.saved) {
      _done.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _scan.dispose();
    _save.dispose();
    _done.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.stage == ResizeStage.saved;
    return ColoredBox(
      color: const Color(0xF20B1220),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 280,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_spin, _scan, _save, _done]),
                      builder: (context, _) {
                        return saved ? _success() : _working();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _steps(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    switch (widget.stage) {
      case ResizeStage.reading:
        return 'Reading photo';
      case ResizeStage.resizing:
        return 'Resizing';
      case ResizeStage.saving:
        return 'Saving to gallery';
      case ResizeStage.saved:
        return 'Saved to gallery';
    }
  }

  String get _subtitle {
    switch (widget.stage) {
      case ResizeStage.reading:
        return 'Preparing the photo on this phone.';
      case ResizeStage.resizing:
        return 'Matching the size and KB you chose.';
      case ResizeStage.saving:
        return 'Putting the finished photo in your gallery.';
      case ResizeStage.saved:
        final kb = widget.savedKb;
        if (kb == null) return 'The photo is in your gallery.';
        return '${kb.toStringAsFixed(1)} KB is now in your gallery.';
    }
  }

  Widget _working() {
    final saving = widget.stage == ResizeStage.saving;
    final drop = Curves.easeInOut.transform(_save.value);
    final photoScale = saving ? 1 - (drop * 0.72) : 1.0;
    final photoDy = saving ? drop * 86 : 0.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(220, 220),
          painter: _RingPainter(_spin.value, saving ? 1 - drop : 1),
        ),
        Transform.translate(
          offset: Offset(0, photoDy),
          child: Transform.scale(
            scale: photoScale,
            child: _photoFrame(),
          ),
        ),
        Positioned(
          bottom: 8,
          child: Opacity(
            opacity: saving ? drop : 0,
            child: _galleryIcon(1 + (drop * 0.08)),
          ),
        ),
      ],
    );
  }

  Widget _success() {
    final t = Curves.easeOutBack.transform(_done.value.clamp(0, 1));
    return Stack(
      alignment: Alignment.center,
      children: [
        _galleryIcon(1),
        Opacity(
          opacity: _done.value,
          child: Transform.scale(
            scale: 0.7 + (0.3 * t),
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFE8C872),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF3F2E08),
                size: 52,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoFrame() {
    return Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x66E8C872)),
        boxShadow: const [
          BoxShadow(color: Color(0x66E8C872), blurRadius: 24),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.photo == null)
              const ColoredBox(
                color: Color(0xFF1A2B4A),
                child: Icon(
                  Icons.image_rounded,
                  color: Color(0xFFE8C872),
                  size: 48,
                ),
              )
            else
              Image.memory(widget.photo!, fit: BoxFit.cover),
            if (widget.stage != ResizeStage.saving)
              Positioned(
                left: 0,
                right: 0,
                top: 12 + (132 * _scan.value),
                child: Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00E8C872),
                        Color(0xFFE8C872),
                        Color(0x00E8C872),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _galleryIcon(double scale) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1D4ED8),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x881D4ED8), blurRadius: 18),
          ],
        ),
        child: const Icon(
          Icons.photo_library_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _steps() {
    const labels = ['Read', 'Resize', 'Save'];
    final active = switch (widget.stage) {
      ResizeStage.reading => 0,
      ResizeStage.resizing => 1,
      ResizeStage.saving => 2,
      ResizeStage.saved => 3,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _step(labels[i], done: active > i, on: active == i),
        ],
      ],
    );
  }

  Widget _step(String label, {required bool done, required bool on}) {
    final color =
        done || on ? const Color(0xFFE8C872) : const Color(0xFF64748B);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.circle,
          size: done ? 14 : 8,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.turn, this.opacity);

  final double turn;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x33E8C872).withValues(alpha: 0.2 * opacity),
    );
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: const [
          Color(0x00E8C872),
          Color(0xFFE8C872),
          Color(0xFF60A5FA),
          Color(0x00E8C872),
        ],
        transform: GradientRotation(turn * math.pi * 2),
      ).createShader(rect);
    canvas.drawArc(rect, turn * math.pi * 2, 2.2, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.turn != turn || oldDelegate.opacity != opacity;
  }
}
