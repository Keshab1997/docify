import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../theme/motion.dart';

/// The first Flutter frame mirrors Android's native vector splash while only
/// the local onboarding flag is read. It never owns navigation or a timer:
/// ready data interrupts the entrance immediately, even before it completes.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key});

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: Motion.medium,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _intro.value = 1;
    } else if (!_started) {
      _started = true;
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  double _portion(double begin, double end) => Curves.fastOutSlowIn.transform(
        ((_intro.value - begin) / (end - begin)).clamp(0.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FF),
      body: Center(
        child: Semantics(
          label: '$kAppShortName is opening',
          child: ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox.square(
                dimension: 288,
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, _) {
                    final title = _portion(1 / 6, 7 / 9);
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LaunchMarkPainter(
                              pop: _portion(0, 5 / 6),
                              check: _portion(1 / 6, 5 / 6),
                              sparkle: _portion(0, 1),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 195,
                          height: 32,
                          child: Transform.translate(
                            offset: Offset(0, 6 * (1 - title)),
                            child: Opacity(
                              opacity: 0.35 + 0.65 * title,
                              child: const Text(
                                kAppShortName,
                                textAlign: TextAlign.center,
                                // A decorative wordmark, like its native vector.
                                // Its accessible label is on the outer Semantics.
                                textScaler: TextScaler.noScaling,
                                // Local system type: no font fetch on the
                                // critical launch path, even when offline.
                                style: TextStyle(
                                  inherit: false,
                                  fontFamily: 'sans-serif',
                                  fontSize: 26,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  color: Color(0xFF172554),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Same document/check/sparkle geometry as res/drawable/splash_mark.xml.
/// Painted vectors stay crisp without decoding a large splash bitmap or GIF.
class _LaunchMarkPainter extends CustomPainter {
  final double pop;
  final double check;
  final double sparkle;

  const _LaunchMarkPainter({
    required this.pop,
    required this.check,
    required this.sparkle,
  });

  static final Path _paper = Path()
    ..moveTo(106, 66)
    ..lineTo(153, 66)
    ..quadraticBezierTo(158, 66, 161.5, 69.5)
    ..lineTo(181.5, 89.5)
    ..quadraticBezierTo(185, 93, 185, 98)
    ..lineTo(185, 163)
    ..quadraticBezierTo(185, 177, 171, 177)
    ..lineTo(106, 177)
    ..quadraticBezierTo(92, 177, 92, 163)
    ..lineTo(92, 80)
    ..quadraticBezierTo(92, 66, 106, 66)
    ..close();

  static final Path _fold = Path()
    ..moveTo(154, 66)
    ..lineTo(154, 88)
    ..quadraticBezierTo(154, 99, 165, 99)
    ..lineTo(185, 99)
    ..quadraticBezierTo(185, 94, 181, 90)
    ..lineTo(162, 71)
    ..quadraticBezierTo(158, 67, 154, 66)
    ..close();

  static final Path _star = Path()
    ..moveTo(198, 69)
    ..quadraticBezierTo(200, 69, 201, 72)
    ..lineTo(203, 77)
    ..quadraticBezierTo(204, 79, 207, 80)
    ..lineTo(211, 82)
    ..quadraticBezierTo(213, 83, 211, 84)
    ..lineTo(205, 87)
    ..quadraticBezierTo(203, 88, 202, 90)
    ..lineTo(200, 95)
    ..quadraticBezierTo(199, 98, 197, 95)
    ..lineTo(194, 89)
    ..quadraticBezierTo(193, 87, 191, 86)
    ..lineTo(186, 84)
    ..quadraticBezierTo(183, 83, 186, 81)
    ..lineTo(192, 78)
    ..quadraticBezierTo(194, 77, 195, 74)
    ..lineTo(197, 70)
    ..quadraticBezierTo(197.5, 69, 198, 69)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 288, size.height / 288);
    canvas.translate(144, 124);
    canvas.scale(0.9 + 0.1 * pop);
    canvas.translate(-144, -124);
    canvas.drawCircle(
      const Offset(144, 127),
      72,
      Paint()..color = const Color(0xFFE0EBFF),
    );
    canvas.save();
    canvas.translate(3, 4);
    canvas.drawPath(_paper, Paint()..color = const Color(0xFFCDDEF7));
    canvas.restore();
    canvas.drawPath(
      _paper,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFF)],
        ).createShader(const Rect.fromLTRB(92, 66, 185, 177)),
    );
    canvas.drawPath(_fold, Paint()..color = const Color(0xFFE4ECF9));
    final ink = Paint()
      ..color = const Color(0xFF3A63D9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(108, 112), const Offset(158, 112), ink);
    canvas.drawLine(const Offset(108, 129), const Offset(146, 129), ink);
    canvas.drawLine(const Offset(108, 146), const Offset(132, 146), ink);
    canvas.drawCircle(
      const Offset(179, 160),
      29,
      Paint()..color = const Color(0xFFCDDEF7),
    );
    canvas.drawCircle(
      const Offset(178, 156),
      28,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5382F4), Color(0xFF2554D9)],
        ).createShader(const Rect.fromLTRB(150, 128, 206, 184)),
    );
    final tick = Path()
      ..moveTo(164, 156)
      ..lineTo(174, 166)
      ..lineTo(192, 146);
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in tick.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * check), white);
    }
    canvas.save();
    canvas.translate(198, 82);
    canvas.rotate(-15 * math.pi / 180 * (1 - sparkle));
    canvas.translate(-198, -82);
    canvas.drawPath(
      _star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD46B), Color(0xFFF6B62E)],
        ).createShader(const Rect.fromLTRB(184, 69, 213, 98)),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LaunchMarkPainter oldDelegate) =>
      oldDelegate.pop != pop ||
      oldDelegate.check != check ||
      oldDelegate.sparkle != sparkle;
}
