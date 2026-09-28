import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/tool_ui.dart';

/// Profile photo row: preview, pick/change button and a clear button.
class CvPhotoPicker extends StatelessWidget {
  final Uint8List? photo;

  /// Called with the picked bytes, or null when the photo is removed.
  final ValueChanged<Uint8List?> onPhoto;

  const CvPhotoPicker({super.key, required this.photo, required this.onPhoto});

  Future<void> _pick(BuildContext context) async {
    final b = await pickPhoto(context);
    if (b != null) onPhoto(b);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  image: photo == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(photo!),
                          fit: BoxFit.cover,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: photo == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Colors.grey.shade400,
                      )
                    : null,
              ),
              if (photo != null)
                InkWell(
                  onTap: () => onPhoto(null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
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
                  'Profile Photo',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  photo == null
                      ? 'Passport size, white background recommended'
                      : 'Tap Change to pick another photo',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.titleBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        photo == null
                            ? Icons.photo_library_rounded
                            : Icons.swap_horiz_rounded,
                        size: 16,
                      ),
                      label: Text(
                        photo == null ? 'Upload' : 'Change',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pick(context),
                    ),
                    if (photo == null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Optional',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
