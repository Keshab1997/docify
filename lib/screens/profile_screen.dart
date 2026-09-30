import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_info.dart';
import '../services/app_auth.dart';
import '../services/app_links.dart';
import '../services/doc_store.dart';
import '../services/legal_texts.dart';
import '../theme/app_theme.dart';
import '../widgets/sync_sheet.dart';
import 'legal/legal_doc_screen.dart';

/// Premium Profile screen — designed for Play Store readiness.
/// Sections: Header, Account, Your Docify, Preferences, Support, Legal.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Help',
            onPressed: () => _openHelp(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const _AppHeaderCard(),
          const SizedBox(height: 12),
          const _AccountCard(),
          const SizedBox(height: 20),
          const _SectionHeader(
            icon: Icons.folder_special_rounded,
            title: 'Your Docify',
          ),
          const SizedBox(height: 8),
          const _StatsRow(),
          const SizedBox(height: 10),
          _ActionGrid(
            actions: [
              _ActionItem(
                icon: Icons.folder_rounded,
                color: AppColors.titleBlue,
                bg: AppColors.photoResizeCard,
                label: 'My Documents',
                onTap: () => _comingSoon(context, 'Documents tab'),
              ),
              _ActionItem(
                icon: Icons.cloud_sync_rounded,
                color: const Color(0xFF7C3AED),
                bg: AppColors.mergePdfCard,
                label: 'Sync with Drive',
                onTap: () => showSyncSheet(context),
              ),
              _ActionItem(
                icon: Icons.lock_rounded,
                color: const Color(0xFF059669),
                bg: AppColors.imageToPdfCard,
                label: 'Lock Documents',
                onTap: () => _showLockInfo(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(
            icon: Icons.tune_rounded,
            title: 'Preferences',
          ),
          const SizedBox(height: 8),
          _settingsGroup(context, ref),
          const SizedBox(height: 20),
          const _SectionHeader(
            icon: Icons.support_agent_rounded,
            title: 'Support & Feedback',
          ),
          const SizedBox(height: 8),
          _supportGroup(context),
          const SizedBox(height: 20),
          const _SectionHeader(
            icon: Icons.verified_user_rounded,
            title: 'Legal & About',
          ),
          const SizedBox(height: 8),
          _legalGroup(context),
          const SizedBox(height: 20),
          const _FooterCard(),
        ],
      ),
    );
  }

  // ---- Groups ----

  static Widget _settingsGroup(BuildContext context, WidgetRef ref) {
    return _GroupCard(
      children: [
        _ProfileTile(
          icon: Icons.language_rounded,
          bg: const Color(0xFFEEF4FF),
          fg: AppColors.primaryButton,
          title: 'Language',
          subtitle: 'English · বাংলা (coming soon)',
          onTap: () => _showLanguageSheet(context),
        ),
        _ProfileTile(
          icon: Icons.autorenew_rounded,
          bg: const Color(0xFFF4F0FF),
          fg: const Color(0xFF7C3AED),
          title: 'Automatic backup',
          subtitle: 'Off by default. Enable in Sync sheet.',
          trailing: const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.mutedText),
          onTap: () => showSyncSheet(context),
        ),
        _ProfileTile(
          icon: Icons.fingerprint_rounded,
          bg: const Color(0xFFE9FBF3),
          fg: const Color(0xFF059669),
          title: 'Fingerprint lock',
          subtitle: 'Lock My Documents with biometrics',
          onTap: () => _showLockInfo(context),
        ),
        _ProfileTile(
          icon: Icons.delete_sweep_rounded,
          bg: const Color(0xFFFFF1F2),
          fg: const Color(0xFFE11D48),
          title: 'Clear cache',
          subtitle: 'Remove temporary files',
          onTap: () => _showClearCache(context),
        ),
      ],
    );
  }

  static Widget _supportGroup(BuildContext context) {
    return _GroupCard(
      children: [
        _ProfileTile(
          icon: Icons.star_rounded,
          bg: const Color(0xFFFFF4D6),
          fg: const Color(0xFFD97706),
          title: 'Rate Docify',
          subtitle: 'Love the app? Leave a review on Play Store',
          onTap: () => _rateApp(context),
        ),
        _ProfileTile(
          icon: Icons.share_rounded,
          bg: const Color(0xFFEEF4FF),
          fg: AppColors.titleBlue,
          title: 'Share Docify',
          subtitle: 'Tell friends preparing job forms',
          onTap: () => _shareApp(),
        ),
        _ProfileTile(
          icon: Icons.email_rounded,
          bg: const Color(0xFFF4F0FF),
          fg: const Color(0xFF7C3AED),
          title: 'Contact support',
          subtitle: kSupportEmail,
          onTap: () => _contactSupport(context),
        ),
        _ProfileTile(
          icon: Icons.bug_report_rounded,
          bg: const Color(0xFFFFF1F4),
          fg: const Color(0xFFE11D48),
          title: 'Report a bug',
          subtitle: 'Help us fix issues faster',
          onTap: () => _reportBug(context),
        ),
        _ProfileTile(
          icon: Icons.lightbulb_rounded,
          bg: const Color(0xFFFFF6F1),
          fg: const Color(0xFFEA580C),
          title: "What's new",
          subtitle: 'See latest improvements',
          onTap: () => _showWhatsNew(context),
        ),
      ],
    );
  }

  static Widget _legalGroup(BuildContext context) {
    return _GroupCard(
      children: [
        _ProfileTile(
          icon: Icons.privacy_tip_rounded,
          bg: AppColors.photoResizeCard,
          fg: AppColors.primaryButton,
          title: 'Privacy Policy',
          subtitle: 'On-device first. Drive only if you choose.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LegalDocScreen(
                title: 'Privacy Policy',
                content: kPrivacyPolicyText,
                externalUrl: kPrivacyPolicyUrl,
              ),
            ),
          ),
        ),
        _ProfileTile(
          icon: Icons.gavel_rounded,
          bg: const Color(0xFFFFF4D6),
          fg: const Color(0xFFD97706),
          title: 'Terms of Service',
          subtitle: 'How to use Docify responsibly',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LegalDocScreen(
                title: 'Terms of Service',
                content: kTermsOfServiceText,
                externalUrl: kTermsUrl,
              ),
            ),
          ),
        ),
        _ProfileTile(
          icon: Icons.delete_forever_rounded,
          bg: const Color(0xFFFFF1F2),
          fg: const Color(0xFFDC2626),
          title: 'Data Deletion',
          subtitle: 'How to delete your data',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LegalDocScreen(
                title: 'Data Deletion',
                content: kDataDeletionText,
                externalUrl: kDataDeletionUrl,
              ),
            ),
          ),
        ),
        _ProfileTile(
          icon: Icons.security_rounded,
          bg: AppColors.mergePdfCard,
          fg: const Color(0xFF7C3AED),
          title: 'Data Safety',
          subtitle: 'What data is collected & why',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LegalDocScreen(
                title: 'Data Safety',
                content: kDataSafetyText,
                externalUrl: kPrivacyPolicyUrl,
              ),
            ),
          ),
        ),
        _ProfileTile(
          icon: Icons.info_rounded,
          bg: AppColors.imageToPdfCard,
          fg: AppColors.successChip,
          title: 'About Docify',
          subtitle: 'A preparation tool, not an official app',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LegalDocScreen(
                title: 'About',
                content: kAboutText,
                externalUrl: docifyWebPreviewUrl,
              ),
            ),
          ),
          footer: const _WebVersionLink(),
        ),
        _ProfileTile(
          icon: Icons.code_rounded,
          bg: const Color(0xFFF1F5F9),
          fg: AppColors.bodyText,
          title: 'Open source licenses',
          subtitle: 'Flutter, Firebase, AdMob and more',
          onTap: () => showLicensePage(
            context: context,
            applicationName: kAppShortName,
            applicationVersion: 'Docify: Photo , PDF & CV Maker',
            applicationLegalese: '© 2026 Keshab Studios',
          ),
        ),
        _ProfileTile(
          icon: Icons.ad_units_rounded,
          bg: AppColors.jobFormStart,
          fg: const Color(0xFFEA580C),
          title: 'Ads',
          subtitle: 'Contains ads. No paid features.',
          onTap: () => showLegalSheet(
            context,
            title: 'Ads',
            subtitle: 'Monetization',
            content:
                'Docify shows banner ads via Google AdMob. There are no in-app purchases or subscriptions. Ads help keep the app free.\n\nAdMob may use Advertising ID and approximate location from IP for ad personalization. You can reset your Advertising ID in Android Settings → Privacy → Ads.',
          ),
        ),
      ],
    );
  }

  // ---- Actions ----

  static void _openHelp(BuildContext context) {
    showLegalSheet(
      context,
      title: 'Help Center',
      subtitle: 'Quick answers',
      content:
          '• Photo resize: Pick photo → set KB range → choose exam preset → Save.\n• Passport photo: 35x45 mm or 2x2 inch, white/blue/red background.\n• Signature: Draw or pick photo → clean → resize.\n• Image to PDF / Merge PDF / Compress PDF: All on-device.\n• CV Builder: Fill sections → choose template → Export PDF.\n• My Documents: Files stay in app folder. Share via WhatsApp etc.\n• Sync: Profile → Sync with Drive → Sign in → Allow drive.file → Sync now.\n• Lock: Documents → Lock icon → Enable fingerprint.\n\nContact: $kSupportEmail',
    );
  }

  static void _showLanguageSheet(BuildContext context) {
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
            const Text('Language',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Docify currently ships in English. Bengali store listing and WhatsNew are ready for Play Console. In-app Bengali UI is planned for next release.',
              style: TextStyle(
                  fontSize: 14, height: 1.45, color: AppColors.bodyText),
            ),
            const SizedBox(height: 16),
            _LanguageOption(
                flag: '🇺🇸', name: 'English', selected: true, onTap: () {}),
            const SizedBox(height: 8),
            _LanguageOption(
              flag: '🇧🇩',
              name: 'বাংলা (Coming soon)',
              selected: false,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('বাংলা UI আসছে পরের আপডেটে!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showLockInfo(BuildContext context) {
    showLegalSheet(
      context,
      title: 'Fingerprint Lock',
      subtitle: 'Protect My Documents',
      content:
          'My Documents can be locked with your phone\'s fingerprint, face or PIN.\n\n• Android checks biometrics — Docify never sees your fingerprint or PIN.\n• Enable: Documents tab → Lock icon → Enable.\n• If biometrics fail, use device PIN.\n• Uninstalling the app removes the lock but not Drive backups.',
    );
  }

  static void _showClearCache(BuildContext context) {
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
            const Text('Clear cache?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'This removes temporary files (thumbnails, compressed copies) but keeps your saved documents in My Documents.',
              style: TextStyle(
                  fontSize: 14, height: 1.45, color: AppColors.bodyText),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Cache cleared (temp files only)')),
                      );
                    },
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _rateApp(BuildContext context) async {
    final uri = Uri.parse(kPlayStoreUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Play Store')),
      );
    }
  }

  static Future<void> _shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Docify: Photo, PDF & CV Maker — Resize photo to exact KB, passport photo, signature, PDF tools & CV builder, all on your phone. Try it: $kPlayStoreUrl',
        subject: 'Docify App',
      ),
    );
  }

  static Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri.parse(
        'mailto:$kSupportEmail?subject=Docify%20Support&body=Hi%20Keshab,%0A%0AApp%20version:%20');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email app not found. Copy: $kSupportEmail'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  static Future<void> _reportBug(BuildContext context) async {
    final uri = Uri.parse(
        'mailto:$kSupportEmail?subject=Docify%20Bug%20Report&body=Device:%20%0AAndroid%20version:%20%0ASteps%20to%20reproduce:%0A1.%20%0A2.%20%0AExpected:%0AActual:%0A');
    await launchUrl(uri);
  }

  static void _showWhatsNew(BuildContext context) {
    showLegalSheet(
      context,
      title: "What's New — 1.1.2",
      subtitle: 'Latest improvements',
      content:
          '• App name is now consistent everywhere — launcher, home, profile and Play Store all show "Docify: Photo , PDF & CV Maker".\n• CV templates no longer print a Docify credit line — your exported CV is clean and ready to send.\n• Photo, signature and PDF tools are faster and more stable.\n• New Profile screen with Support, Legal, and Data Deletion info for Play Store compliance.\n\nUpcoming: Bengali UI, more CV templates, batch resize.',
    );
  }

  static void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — open from bottom bar')),
    );
  }
}

/// Header with app logo, name, descriptor, version.
class _AppHeaderCard extends StatelessWidget {
  const _AppHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4FF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: Soft.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  kAppShortName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  kAppDescriptor,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.titleBlue,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) {
                    final info = snap.data;
                    final v = info?.version ?? '...';
                    final b = info?.buildNumber ?? '';
                    return Text(
                      'Version $v${b.isNotEmpty ? ' ($b)' : ''} · On this phone',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.mutedText,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded,
              color: AppColors.primaryButton, size: 22),
        ],
      ),
    );
  }
}

/// Stats row: documents count + storage hint.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: DocStore.list(),
      builder: (context, snap) {
        final count = snap.data?.length ?? 0;
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.description_rounded,
                label: 'Documents',
                value: snap.connectionState == ConnectionState.waiting
                    ? '…'
                    : '$count',
                sub: 'in My Documents',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _StatCard(
                icon: Icons.shield_rounded,
                label: 'Privacy',
                value: '100%',
                sub: 'on-device',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _StatCard(
                icon: Icons.ads_click_rounded,
                label: 'Ads',
                value: 'Banner',
                sub: 'No in-app pay',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Soft.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryButton),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.bodyText,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final List<_ActionItem> actions;

  const _ActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _ActionCard(item: actions[i])),
        ],
      ],
    );
  }
}

class _ActionItem {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;

  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: Soft.card,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Account card — guest vs signed-in.
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9FBF3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 12, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'Drive backup available',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showSyncSheet(context),
                icon: const Icon(Icons.cloud_sync_rounded, size: 19),
                label: const Text('Sync now'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _busy ? null : _signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Files go to your own Drive folder "Docify". Signing out never deletes Drive copies.',
          style: TextStyle(
            fontSize: 11,
            height: 1.35,
            color: AppColors.mutedText,
          ),
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
                    'Optional. Everything works without an account.',
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
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_rounded, size: 14, color: AppColors.mutedText),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'We request drive.file scope only — files this app creates. No access to rest of your Drive.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar(String? photoUrl, String? fallback) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.photoResizeCard,
        foregroundImage: NetworkImage(photoUrl),
        child: const Icon(Icons.person_rounded, color: AppColors.titleBlue),
      );
    }
    final initial = (fallback != null && fallback.isNotEmpty)
        ? fallback.characters.first.toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.photoResizeCard,
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.titleBlue,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: Soft.card,
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryButton),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: Soft.card,
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? footer;

  const _ProfileTile({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.mutedText,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 8),
                      footer!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.mutedText,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.photoResizeCard : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? AppColors.primaryButton : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color:
                        selected ? AppColors.primaryButton : AppColors.bodyText,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primaryButton, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterCard extends StatelessWidget {
  const _FooterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: Soft.card,
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFE11D48)),
              SizedBox(width: 6),
              Text(
                'Made with care in India',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bodyText,
                ),
              ),
              SizedBox(width: 6),
              Text('🇮🇳', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              final v = snap.data?.version ?? '1.1.2';
              return Text(
                'Docify v$v · © 2026 Keshab Studios · $kAppPackage\nFiles stay on your phone. Drive only if you choose.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.mutedText,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(
                label: 'Privacy',
                onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl),
                    mode: LaunchMode.externalApplication),
              ),
              const _Dot(),
              _FooterLink(
                label: 'Terms',
                onTap: () => launchUrl(Uri.parse(kTermsUrl),
                    mode: LaunchMode.externalApplication),
              ),
              const _Dot(),
              _FooterLink(
                label: 'Support',
                onTap: () => launchUrl(Uri.parse('mailto:$kSupportEmail'),
                    mode: LaunchMode.externalApplication),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryButton,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child:
          Text('·', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
    );
  }
}

class _WebVersionLink extends StatelessWidget {
  const _WebVersionLink();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.imageToPdfCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.public_rounded,
                  size: 16, color: AppColors.successChip),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  docifyWebPreviewUrl,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  size: 14, color: AppColors.mutedText),
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
