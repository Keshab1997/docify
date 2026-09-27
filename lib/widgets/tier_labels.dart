import 'package:flutter/material.dart';

/// Gold Premium and dark Advanced marks used on Photo Resize.
class PremiumAdvancedLabels extends StatelessWidget {
  const PremiumAdvancedLabels({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _TierPill(
          'Premium',
          icon: Icons.workspace_premium_rounded,
          background: Color(0xFFE8C872),
          foreground: Color(0xFF3F2E08),
        ),
        _TierPill(
          'Advanced',
          icon: Icons.auto_awesome_rounded,
          background: Color(0xFF1D4ED8),
          foreground: Color(0xFFFFFFFF),
        ),
      ],
    );
  }
}

class _TierPill extends StatelessWidget {
  const _TierPill(
    this.label, {
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
