import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'home_screen.dart';
import 'tools_screen.dart';
import 'documents_screen.dart';
import 'profile_screen.dart';
import '../widgets/ad_banner.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  final _docsKey = GlobalKey<DocumentsScreenState>();
  late final List<Widget> _screens;
  late final AnimationController _fade;
  late final Animation<double> _fadeCurve;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onOpenTab: _openTab),
      const ToolsScreen(),
      DocumentsScreen(key: _docsKey),
      const ProfileScreen(),
    ];
    // Starts at 1 so the first frame is fully visible; every tab change runs it
    // from 0 again to fade the new tab in.
    _fade = AnimationController(vsync: this, duration: Motion.short, value: 1);
    _fadeCurve = CurvedAnimation(parent: _fade, curve: Motion.enter);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _openTab(int i) {
    final changed = i != _index;
    setState(() => _index = i);
    if (i == 2) {
      _docsKey.currentState?.reload();
    }
    if (changed) {
      HapticFeedback.selectionClick();
      _fade.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeCurve,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Radii.shell),
              boxShadow: Soft.card,
            ),
            child: Row(
              children: [
                _item(0, Icons.home_rounded, 'Home'),
                _item(1, Icons.grid_view_rounded, 'Tools'),
                _item(2, Icons.folder_rounded, 'Documents'),
                _item(3, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(int index, IconData icon, String label) {
    final selected = _index == index;
    final color = selected ? AppColors.primaryButton : AppColors.mutedText;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openTab(index),
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.short),
          curve: Motion.enter,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.photoResizeCard : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.nav),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.1 : 1,
                duration: Motion.of(context, Motion.short),
                curve: Motion.pop,
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: Motion.of(context, Motion.short),
                curve: Motion.enter,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
