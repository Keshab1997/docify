import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryButton, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.description, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('JobDoc - Photo, PDF & CV', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Package: com.keshabstudios.jobdoc', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                    Text('Version 1.0.0', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _tile(Icons.privacy_tip_rounded, 'Privacy Policy', 'Documents stay on device. AdMob only.', () {}),
          _tile(Icons.info_rounded, 'About', 'Built for job & exam forms. Not official.', () {}),
          _tile(Icons.email_rounded, 'Contact', 'keshab@example.com', () {}),
          _tile(Icons.ad_units_rounded, 'Ads', 'Contains ads: Yes. No paid features.', () {}),
          _tile(Icons.security_rounded, 'Data Safety', 'Photos not collected. AdMob collects Device IDs, App interactions.', () {}),
          const SizedBox(height: 20),
          const Text('JobDoc does not upload your documents to a server. Photos, signatures, PDFs and CV text stay on your phone. Ads via Google AdMob.', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.photoResizeCard, borderRadius: BorderRadius.circular(12)),
            child: const Text('No login, no cloud backup, no SMS/contact/location permission. Uses Android Photo Picker + Camera only when needed. INTERNET only for ads.', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryButton),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
        onTap: onTap,
      ),
    );
  }
}
