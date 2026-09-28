import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../models/saved_doc.dart';
import '../../../../services/image_bytes.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/tool_ui.dart';
import '../../crop_image_screen.dart';

/// Profile photo row: preview, pick, crop, resize and clear.
///
/// A photo straight off a phone camera is several megabytes and used to be
/// embedded byte for byte, which turned a 7 KB CV into a 5 MB one — awkward to
/// attach to a job application. Everything picked here is cropped to the
/// 35x45 mm passport frame the form expects and then scaled down to a few
/// hundred pixels, which is already more than the printed size needs.
class CvPhotoPicker extends StatelessWidget {
  final Uint8List? photo;

  /// Called with the picked bytes, or null when the photo is removed.
  final ValueChanged<Uint8List?> onPhoto;

  const CvPhotoPicker({super.key, required this.photo, required this.onPhoto});

  /// Printed at 35x45 mm, so 700 px across is roughly 500 dpi: far more than
  /// any exam form needs, and it keeps the whole PDF well under 200 KB.
  static const int _targetWidth = 700;
  static const int _targetKB = 120;
  static const double _passportAspect = 35 / 45;

  Future<void> _pick(BuildContext context) async {
    final raw = await pickPhoto(context);
    if (raw == null || !context.mounted) return;

    final cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => CropBytesPage(
          image: raw,
          lockedAspect: _passportAspect,
          title: 'Crop photo',
        ),
      ),
    );
    if (cropped == null || !context.mounted) return;

    try {
      final small = await ImageBytes.resizeToKb(
        bytes: cropped,
        targetKB: _targetKB,
        targetWidth: _targetWidth,
      );
      onPhoto(small);
    } catch (e) {
      // Never drop the photo the user already has because a resize failed.
      if (!context.mounted) return;
      showJobSnack(context, 'Could not prepare that photo: $e');
    }
  }

  Future<void> _recrop(BuildContext context) async {
    final current = photo;
    if (current == null) return;
    final cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => CropBytesPage(
          image: current,
          lockedAspect: _passportAspect,
          title: 'Crop photo',
        ),
      ),
    );
    if (cropped == null || !context.mounted) return;
    try {
      final small = await ImageBytes.resizeToKb(
        bytes: cropped,
        targetKB: _targetKB,
        targetWidth: _targetWidth,
      );
      onPhoto(small);
    } catch (e) {
      if (!context.mounted) return;
      showJobSnack(context, 'Could not prepare that photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 64,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                  image: hasPhoto
                      ? DecorationImage(
                          image: MemoryImage(photo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: hasPhoto
                    ? null
                    : Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
              ),
              if (hasPhoto)
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
                  hasPhoto
                      ? '35 × 45 mm · ${kbLabel(photo!.length)}'
                      : 'Passport size, white background recommended',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                        hasPhoto
                            ? Icons.swap_horiz_rounded
                            : Icons.photo_library_rounded,
                        size: 16,
                      ),
                      label: Text(
                        hasPhoto ? 'Change' : 'Upload',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pick(context),
                    ),
                    if (hasPhoto)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: Colors.grey.shade800,
                        ),
                        icon: const Icon(Icons.crop_rounded, size: 16),
                        label: const Text(
                          'Crop',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _recrop(context),
                      ),
                  ],
                ),
                if (!hasPhoto) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Optional. You can crop it after picking.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
