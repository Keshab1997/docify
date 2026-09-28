import 'package:flutter/material.dart';

/// Slim always-visible completeness bar shown above the section tabs.
class CvProgressHeader extends StatelessWidget {
  /// 0.0 - 1.0
  final double completeness;

  final VoidCallback onLoadSample;

  const CvProgressHeader({
    super.key,
    required this.completeness,
    required this.onLoadSample,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (completeness * 100).round();
    final color = pct > 70
        ? const Color(0xFF16A34A)
        : pct > 40
            ? const Color(0xFFF59E0B)
            : const Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: completeness,
                    strokeWidth: 4.5,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Completeness',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pct == 100
                        ? '✨ Amazing! Your CV is ready to preview.'
                        : pct > 70
                            ? 'Great progress — just a bit more!'
                            : 'Fill the tabs below to improve your CV',
                    style:
                        TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
              label: const Text('Sample', style: TextStyle(fontSize: 11)),
              onPressed: onLoadSample,
            ),
          ],
        ),
      ),
    );
  }
}
