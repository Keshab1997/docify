import 'package:flutter/material.dart';

/// AdMob has no web SDK, so keep the same 50px slot to preserve layout.
class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: 50);
}
