import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'job_progress.dart';

enum ResizeStage { reading, resizing, saving, saved }

/// Photo Resize's staged view.
///
/// The visuals now live in [JobProgressOverlay] so that every tool shares them;
/// this wrapper keeps the stage names Photo Resize already uses and supplies
/// the copy that belongs to that one tool.
class ResizeShow extends StatelessWidget {
  const ResizeShow({
    super.key,
    required this.stage,
    required this.photo,
    this.savedKb,
  });

  final ResizeStage stage;
  final Uint8List? photo;
  final double? savedKb;

  @override
  Widget build(BuildContext context) {
    return JobProgressOverlay(
      stage: _jobStage,
      title: _title,
      subtitle: _subtitle,
      doneSubtitle: _doneSubtitle,
      photo: photo,
      medallionIcon: Icons.image_rounded,
      saveIcon: Icons.photo_library_rounded,
      steps: const ['Read', 'Resize', 'Save'],
    );
  }

  JobStage get _jobStage => switch (stage) {
        ResizeStage.reading => JobStage.reading,
        ResizeStage.resizing => JobStage.working,
        ResizeStage.saving => JobStage.saving,
        ResizeStage.saved => JobStage.done,
      };

  String get _title => switch (stage) {
        ResizeStage.reading => 'Reading photo',
        ResizeStage.resizing => 'Resizing',
        ResizeStage.saving => 'Saving to gallery',
        ResizeStage.saved => 'Saved to gallery',
      };

  String get _subtitle => switch (stage) {
        ResizeStage.reading => 'Preparing the photo on this phone.',
        ResizeStage.resizing => 'Matching the size and KB you chose.',
        ResizeStage.saving => 'Putting the finished photo in your gallery.',
        ResizeStage.saved => 'The photo is in your gallery.',
      };

  String get _doneSubtitle {
    final kb = savedKb;
    if (kb == null) return 'The photo is in your gallery.';
    return '${kb.toStringAsFixed(1)} KB is now in your gallery.';
  }
}
