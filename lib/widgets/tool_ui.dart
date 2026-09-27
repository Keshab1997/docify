import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/pick_bytes.dart';
import '../theme/app_theme.dart';

Future<Uint8List?> pickPhoto(BuildContext context) async {
  final src = await pickSourceSheet(context);
  if (src == null) return null;
  return PickBytes.image(src);
}

void showJobSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

Future<ImageSource?> pickSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose a photo',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.photoResizeCard,
                child: Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primaryButton,
                ),
              ),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.imageToPdfCard,
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: AppColors.successChip,
                ),
              ),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );
}

class HintBanner extends StatelessWidget {
  const HintBanner(
    this.text, {
    super.key,
    this.color = AppColors.photoResizeCard,
  });
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, height: 1.35)),
    );
  }
}

class ImagePickBox extends StatelessWidget {
  const ImagePickBox({
    super.key,
    required this.bytes,
    required this.onTap,
    this.height = 200,
    this.empty = 'Tap to pick a photo',
  });

  final Uint8List? bytes;
  final VoidCallback onTap;
  final double height;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 40,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      empty,
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  ],
                )
              : Image.memory(bytes!, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class PrimaryJobButton extends StatelessWidget {
  const PrimaryJobButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class KbChips extends StatelessWidget {
  const KbChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final kb in options)
          ChoiceChip(
            label: Text('${kb}KB'),
            selected: selected == kb,
            onSelected: (_) => onSelect(kb),
          ),
      ],
    );
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.child,
    required this.label,
    required this.onShare,
  });

  final Widget child;
  final String label;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Soft.card,
      ),
      child: Column(
        children: [
          child,
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share'),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
