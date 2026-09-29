import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_links.dart';
import '../services/app_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/sync_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF4FF), Color(0xFFF8FBFF)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Docify',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Text(
                        'Photo, PDF & CV',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.titleBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Read from the package, never hand-typed: the screen
                      // used to say 1.1.1 while pubspec said 1.1.2.
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snap) {
                          final v = snap.data?.version;
                          return Text(
                            v == null
                                ? 'on this phone'
                                : 'Version $v  ·  on this phone',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _AccountCard(),
          const SizedBox(height: 16),
          _tile(
            context,
            Icons.privacy_tip_rounded,
            AppColors.photoResizeCard,
            AppColors.primaryButton,
            'Privacy',
            'On this phone. Drive only if you choose.',
            'Photos, signatures, PDFs and CV text are processed on the device. By default nothing leaves the phone. Optional sync (sign-in) uploads only your own documents to a Docify folder in your Google Drive — your account, your storage; there is no Docify server. Ads use Google AdMob, which may use a device id and approximate location from the IP address.',
          ),
          _tile(
            context,
            Icons.info_rounded,
            AppColors.imageToPdfCard,
            AppColors.successChip,
            'About',
            'A preparation tool, not an official app.',
            'Docify helps you size a photo, a signature and a PDF for job and exam forms. It does not submit forms, and it is not an app of any exam board or government.',
            footer: const _WebVersionLink(),
          ),
          _tile(
            context,
            Icons.ad_units_rounded,
            AppColors.jobFormStart,
            const Color(0xFFEA580C),
            'Ads',
            'Contains ads. No paid features.',
            'The app shows a banner from Google AdMob. There are no in-app purchases.',
          ),
          _tile(
            context,
            Icons.security_rounded,
            AppColors.mergePdfCard,
            const Color(0xFF7C3AED),
            'Data safety',
            'No broad storage or location permission.',
            'The app uses the photo picker and the camera only when you scan. Internet is for ads and, if you enable it, optional Drive sync of your own files. It does not ask for contacts, SMS, microphone or location.',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Radii.card),
              boxShadow: Soft.card,
            ),
            child: const Text(
              'Files you make are saved in the app folder. Share them yourself if you want to send a copy.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    Color bg,
    Color fg,
    String title,
    String sub,
    String body, {
    Widget? footer,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: fg, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          subtitle: Text(
            sub,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.mutedText,
          ),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (ctx) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.bodyText,
                      ),
                    ),
                    if (footer != null) ...[const SizedBox(height: 16), footer],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Sign-in / account row. Guest mode (no account) stays fully supported:
/// everything local works, and sign-in is optional by design.
class _AccountCard extends ConsumerStatefulWidget {
  const _AccountCard();

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AppAuth.signIn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not sign in: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AppAuth.signOut();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Soft.card,
      ),
      child: user == null ? _guest() : _signedIn(user),
    );
  }

  Widget _signedIn(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(user.photoURL, user.displayName ?? user.email),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? user.email ?? 'Signed in',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email ?? 'Google account',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showSyncSheet(context),
                icon: const Icon(Icons.cloud_sync_rounded, size: 19),
                label: const Text('Sync with Drive'),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: _busy ? null : _signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _guest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFEEF4FF),
              child: Icon(
                Icons.cloud_upload_rounded,
                color: AppColors.titleBlue,
                size: 22,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Back up to your Google Drive',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Optional. Everything keeps working without an account.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            // firebaseReady gates the tap: the repo ships without
            // google-services.json, and guest mode must stay first-class.
            onPressed: AppAuth.firebaseReady && !_busy ? _signIn : null,
            icon: const Icon(Icons.account_circle_rounded, size: 20),
            label: Text(
              !AppAuth.firebaseReady
                  ? 'Sign-in not enabled on this build'
                  : _busy
                      ? 'Signing in…'
                      : 'Sign in with Google',
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(String? photoUrl, String? fallback) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.photoResizeCard,
        foregroundImage: NetworkImage(photoUrl),
        child: const Icon(Icons.person_rounded, color: AppColors.titleBlue),
      );
    }
    final initial = (fallback != null && fallback.isNotEmpty)
        ? fallback.characters.first.toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.photoResizeCard,
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.titleBlue,
        ),
      ),
    );
  }
}

class _WebVersionLink extends StatelessWidget {
  const _WebVersionLink();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.imageToPdfCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                Icons.public_rounded,
                size: 20,
                color: AppColors.successChip,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open the web version',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bodyText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      docifyWebPreviewUrl,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(Uri.parse(docifyWebPreviewUrl));
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open a browser.')),
      );
    }
  }
}
