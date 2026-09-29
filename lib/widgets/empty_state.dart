import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app's one empty state: an illustration, a headline, a line of
/// context, and an optional button that takes the user somewhere useful.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.image,
    this.icon,
    this.ctaLabel,
    this.onCta,
  });

  final String title;
  final String? message;
  final String? image;
  final IconData? icon;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              Image.asset(image!, width: 120, height: 96, fit: BoxFit.contain)
            else if (icon != null)
              Icon(icon, size: 64, color: AppColors.mutedText),
            const SizedBox(height: Space.lg),
            Text(title, textAlign: TextAlign.center, style: AppText.title),
            if (message != null) ...[
              const SizedBox(height: Space.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(height: 1.4),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: Space.xl),
              FilledButton.icon(
                onPressed: onCta,
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
