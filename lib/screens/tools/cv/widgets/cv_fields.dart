import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Labelled text field used across the CV form.
class CvInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  /// Fired on every keystroke so the completeness header can update.
  final ValueChanged<String>? onChanged;

  const CvInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.grey.shade700),
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.titleBlue,
              width: 1.6,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Header strip shown at the top of every section tab.
class CvSectionHeader extends StatelessWidget {
  final String heading;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final bool done;

  const CvSectionHeader({
    super.key,
    required this.heading,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        heading,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (done) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single one-tap chip that drops canned wording into a field.
class CvHelperChip extends StatelessWidget {
  final String label;
  final String text;
  final TextEditingController target;
  final VoidCallback onChanged;

  const CvHelperChip({
    super.key,
    required this.label,
    required this.text,
    required this.target,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        '+ $label',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      onPressed: () {
        target.text = text;
        onChanged();
      },
    );
  }
}

/// Toggleable suggestions that append to (or remove from) a comma separated
/// field such as skills or languages.
class CvQuickChips extends StatelessWidget {
  final String title;
  final List<String> items;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const CvQuickChips({
    super.key,
    required this.title,
    required this.items,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 2),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: items.map((s) {
            final already = controller.text.toLowerCase().contains(
                  s.toLowerCase(),
                );
            return FilterChip(
              label: Text(
                already ? '✓ $s' : '+ $s',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: already ? Colors.white : Colors.grey.shade800,
                ),
              ),
              selected: already,
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: AppColors.titleBlue,
              side: BorderSide(
                color: already ? AppColors.titleBlue : Colors.grey.shade300,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onSelected: (_) {
                final curr = controller.text.trim();
                if (!already) {
                  controller.text = curr.isEmpty ? s : '$curr, $s';
                } else {
                  final parts = curr
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.toLowerCase() != s.toLowerCase())
                      .toList();
                  controller.text = parts.join(', ');
                }
                onChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
