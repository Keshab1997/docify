import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/requirement_check.dart';
import '../theme/app_theme.dart';
import 'animated_reveal.dart';

/// Shows the exam-form pass/fail list for a finished file, so a size or format
/// mismatch is visible here instead of being discovered by the portal.
///
/// This card is the app's whole point, so it reacts: a light haptic and a short
/// green breathe when everything passes, a heavy haptic and a shake when
/// something does not. The animation runs once per check, and never when the
/// device asks for reduced motion.
class RequirementCheckCard extends StatefulWidget {
  const RequirementCheckCard({super.key, required this.check});

  final RequirementCheck check;

  @override
  State<RequirementCheckCard> createState() => _RequirementCheckCardState();
}

class _RequirementCheckCardState extends State<RequirementCheckCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _react;

  @override
  void initState() {
    super.initState();
    _react = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void didUpdateWidget(RequirementCheckCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.check != widget.check) _run();
  }

  @override
  void dispose() {
    _react.dispose();
    super.dispose();
  }

  void _run() {
    if (!mounted || MediaQuery.of(context).disableAnimations) return;
    _react.forward(from: 0);
    if (widget.check.allPassed) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final check = widget.check;
    final ok = check.allPassed;
    final accent = ok ? AppColors.successChip : AppColors.pdfBadge;

    return AnimatedBuilder(
      animation: _react,
      builder: (context, child) {
        final t = _react.value;
        // Fail: a quick side-to-side shake that settles. Pass: a soft breathe.
        final dx = ok ? 0.0 : math.sin(t * math.pi * 6) * 6 * (1 - t);
        final breathe = ok ? 1 + 0.012 * math.sin(t * math.pi) : 1.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(scale: breathe, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(Radii.field),
          border: Border.all(color: accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _react,
                  builder: (context, icon) {
                    // The verdict icon pops in, so the answer is noticed.
                    final pop = Curves.easeOutBack.transform(
                      (_react.value * 1.6).clamp(0, 1),
                    );
                    return Transform.scale(scale: 0.7 + 0.3 * pop, child: icon);
                  },
                  child: Icon(
                    ok ? Icons.verified_rounded : Icons.error_outline_rounded,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    check.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < check.items.length; i++)
              AnimatedReveal(
                index: i,
                duration: const Duration(milliseconds: 260),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        check.items[i].passed
                            ? Icons.check_rounded
                            : Icons.priority_high_rounded,
                        size: 15,
                        color: check.items[i].passed
                            ? AppColors.successChip
                            : AppColors.pdfBadge,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${check.items[i].label}: ${check.items[i].detail}',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              check.summary,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
