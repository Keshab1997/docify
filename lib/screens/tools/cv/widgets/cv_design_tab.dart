import 'package:flutter/material.dart';

import '../../../../models/cv_template_info.dart';
import '../../../../theme/app_theme.dart';
import 'cv_template_thumbnail.dart';

/// Grid of every design. Tapping a card opens it full screen; the small button
/// underneath selects a design without leaving the grid.
class CvDesignTab extends StatelessWidget {
  final int selectedId;
  final ValueChanged<int> onSelect;

  /// Opens the full screen preview for a design.
  final ValueChanged<CvTemplateInfo> onPreview;

  const CvDesignTab({
    super.key,
    required this.selectedId,
    required this.onSelect,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: kCvTemplates.length,
      itemBuilder: (context, i) {
        final t = kCvTemplates[i];
        final isSelected = t.id == selectedId;
        return _DesignCard(
          template: t,
          isSelected: isSelected,
          onPreview: () => onPreview(t),
          onSelect: () => onSelect(t.id),
        );
      },
    );
  }
}

class _DesignCard extends StatelessWidget {
  final CvTemplateInfo template;
  final bool isSelected;
  final VoidCallback onPreview;
  final VoidCallback onSelect;

  const _DesignCard({
    required this.template,
    required this.isSelected,
    required this.onPreview,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPreview,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? template.accentColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? template.accentColor.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 78,
                          height: 100,
                          child: CvTemplateThumbnail(
                            template: template,
                            isSelected: isSelected,
                            enlarged: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
              child: Text(
                template.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? template.primaryColor : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: Text(
                template.badge,
                style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                child: isSelected
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: template.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: template.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'In use',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: template.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: AppColors.titleBlue,
                        ),
                        onPressed: onSelect,
                        child: const Text(
                          'Use',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
