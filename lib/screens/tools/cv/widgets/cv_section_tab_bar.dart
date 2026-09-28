import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// One entry in the section tab bar.
class CvTabItem {
  final String label;
  final IconData icon;

  /// Shows a green tick once the section has enough content.
  final bool done;

  const CvTabItem({
    required this.label,
    required this.icon,
    this.done = false,
  });
}

/// Horizontally scrolling tab bar for the CV sections.
///
/// Deliberately not a Material [TabBar]: the CV builder switches between the
/// form and the preview, and keeping the pages in an [IndexedStack] means every
/// text field keeps its state when you move between tabs.
class CvSectionTabBar extends StatelessWidget {
  final List<CvTabItem> items;
  final int index;
  final ValueChanged<int> onSelected;

  const CvSectionTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final selected = i == index;
          return InkWell(
            onTap: () => onSelected(i),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.titleBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.titleBlue : Colors.grey.shade300,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.titleBlue.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 15,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  if (item.done) ...[
                    const SizedBox(width: 5),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: selected ? Colors.white : const Color(0xFF16A34A),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
