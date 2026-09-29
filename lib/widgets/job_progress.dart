import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// How long each part of the staged flow runs. Tuned in Photo Resize; kept
/// here so every tool moves at the same speed.
const Duration _spinDuration = Duration(milliseconds: 2200);
const Duration _scanDuration = Duration(milliseconds: 1400);
const Duration _saveDuration = Duration(milliseconds: 1600);
const Duration _doneDuration = Duration(milliseconds: 700);

/// The phases a Docify tool moves through while it works.
enum JobStage { reading, working, saving, done }

/// Full-screen staged progress view for a tool.
///
/// Generalised from Photo Resize's `ResizeShow`, which every other tool now
/// reuses: a slowly rotating ring, a medallion holding the file being worked
/// on, a scan line while the tool reads, a morph into the save badge and a
/// success pop with a check when the file is written. Callers pass their own
/// title, subtitle and step names, so Merge, Compress, Scan and the rest stop
/// flashing a bare spinner and start telling the user what is happening.
class JobProgressOverlay extends StatefulWidget {
  const JobProgressOverlay({
    super.key,
    required this.stage,
    required this.title,
    this.subtitle,
    this.doneSubtitle,
    this.photo,
    this.medallionIcon = Icons.insert_drive_file_rounded,
    this.saveIcon = Icons.check_rounded,
    this.steps = const <String>[],
  });

  final JobStage stage;

  /// Headline, e.g. 'Merging PDFs'.
  final String title;

  /// One line under the headline while the tool works.
  final String? subtitle;

  /// Replaces [subtitle] once [stage] is [JobStage.done].
  final String? doneSubtitle;

  /// Thumbnail shown inside the medallion; an icon is used when null.
  final Uint8List? photo;

  final IconData medallionIcon;

  /// Icon on the blue save badge that the medallion morphs into.
  final IconData saveIcon;

  /// Optional footer steps, e.g. `['Read', 'Merge', 'Save']`.
  final List<String> steps;

  @override
  State<JobProgressOverlay> createState() => _JobProgressOverlayState();
}

class _JobProgressOverlayState extends State<JobProgressOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _scan;
  late final AnimationController _save;
  late final AnimationController _done;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: _spinDuration)..repeat();
    _scan = AnimationController(vsync: this, duration: _scanDuration)..repeat();
    _save = AnimationController(vsync: this, duration: _saveDuration);
    _done = AnimationController(vsync: this, duration: _doneDuration);
    if (widget.stage == JobStage.saving) _save.forward();
    if (widget.stage == JobStage.done) {
      _save.value = 1;
      _done.forward();
    }
  }

  @override
  void didUpdateWidget(JobProgressOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stage == JobStage.saving && oldWidget.stage != JobStage.saving) {
      _save.forward(from: 0);
    }
    if (widget.stage == JobStage.done && oldWidget.stage != JobStage.done) {
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
    final saved = widget.stage == JobStage.done;
    final subtitle =
        saved ? (widget.doneSubtitle ?? widget.subtitle) : widget.subtitle;
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
                      builder: (context, _) => saved ? _success() : _working(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (widget.steps.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _steps(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _working() {
    final saving = widget.stage == JobStage.saving;
    final drop = Curves.easeInOut.transform(_save.value);
    final medallionScale = saving ? 1 - (drop * 0.72) : 1.0;
    final medallionDy = saving ? drop * 86 : 0.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(220, 220),
          painter: _RingPainter(_spin.value, saving ? 1 - drop : 1),
        ),
        Transform.translate(
          offset: Offset(0, medallionDy),
          child: Transform.scale(scale: medallionScale, child: _medallion()),
        ),
        Positioned(
          bottom: 8,
          child: Opacity(
            opacity: saving ? drop : 0,
            child: _saveBadge(1 + (drop * 0.08)),
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
        _saveBadge(1),
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

  Widget _medallion() {
    final photo = widget.photo;
    return Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x66E8C872)),
        boxShadow: const [BoxShadow(color: Color(0x66E8C872), blurRadius: 24)],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo == null)
              ColoredBox(
                color: const Color(0xFF1A2B4A),
                child: Icon(
                  widget.medallionIcon,
                  color: const Color(0xFFE8C872),
                  size: 48,
                ),
              )
            else
              Image.memory(photo, fit: BoxFit.cover),
            if (widget.stage != JobStage.saving)
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

  Widget _saveBadge(double scale) {
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
        child: Icon(widget.saveIcon, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _steps() {
    final active = switch (widget.stage) {
      JobStage.reading => 0,
      JobStage.working => 1,
      JobStage.saving => 2,
      JobStage.done => widget.steps.length,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _step(widget.steps[i], done: active > i, on: active == i),
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
