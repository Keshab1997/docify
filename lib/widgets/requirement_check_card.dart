import 'package:flutter/material.dart';

import '../models/requirement_check.dart';
import '../theme/app_theme.dart';

/// Shows the exam-form pass/fail list for a finished file, so a size or format
/// mismatch is visible here instead of being discovered by the portal.
class RequirementCheckCard extends StatelessWidget {
  const RequirementCheckCard({super.key, required this.check});

  final RequirementCheck check;

  @override
  Widget build(BuildContext context) {
    final ok = check.allPassed;
    final accent = ok ? AppColors.successChip : AppColors.pdfBadge;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.verified_rounded : Icons.error_outline_rounded,
                size: 18,
                color: accent,
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
          for (final item in check.items)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.passed
                        ? Icons.check_rounded
                        : Icons.priority_high_rounded,
                    size: 15,
                    color: item.passed
                        ? AppColors.successChip
                        : AppColors.pdfBadge,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.label}: ${item.detail}',
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
    );
  }
}
