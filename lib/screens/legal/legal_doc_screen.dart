import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

/// Full-screen scrollable legal document viewer.
/// Used for Privacy Policy, Terms, Data Deletion, etc.
/// No markdown package needed — renders plain text with simple formatting.
class LegalDocScreen extends StatelessWidget {
  final String title;
  final String content;
  final String? externalUrl;

  const LegalDocScreen({
    super.key,
    required this.title,
    required this.content,
    this.externalUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (externalUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Open in browser',
              onPressed: () => _openUrl(context, externalUrl!),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (externalUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.photoResizeCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded,
                      size: 18, color: AppColors.primaryButton),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      externalUrl!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SelectableText(
            content.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.bodyText,
            ),
          ),
          const SizedBox(height: 24),
          if (externalUrl != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openUrl(context, externalUrl!),
                icon: const Icon(Icons.public_rounded, size: 18),
                label: const Text('Open official web version'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}

/// Bottom sheet version — quick peek without leaving Profile.
Future<void> showLegalSheet(
  BuildContext context, {
  required String title,
  required String content,
  String? externalUrl,
  String? subtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                content.trim(),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 20),
              if (externalUrl != null)
                FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse(externalUrl),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open web version'),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    },
  );
}
