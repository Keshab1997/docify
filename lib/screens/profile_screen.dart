import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JobDoc',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Photo, PDF & CV',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.titleBlue,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Version 1.0.0  ·  on this phone',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _tile(
            context,
            Icons.privacy_tip_rounded,
            AppColors.photoResizeCard,
            AppColors.primaryButton,
            'Privacy',
            'Documents stay on this phone.',
            'Photos, signatures, PDFs and CV text are processed on the device. JobDoc does not upload them. Ads use Google AdMob, which may use a device id and approximate location from the IP address.',
          ),
          _tile(
            context,
            Icons.info_rounded,
            AppColors.imageToPdfCard,
            AppColors.successChip,
            'About',
            'A preparation tool, not an official app.',
            'JobDoc helps you size a photo, a signature and a PDF for job and exam forms. It does not submit forms, and it is not an app of any exam board or government.',
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
            'The app uses the photo picker and the camera only when you scan. Internet is for ads. It does not ask for contacts, SMS, microphone or location.',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
    String body,
  ) {
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
