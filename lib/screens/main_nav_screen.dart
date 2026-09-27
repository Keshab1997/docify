import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  void _openTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onOpenTab: _openTab),
      const ToolsScreen(),
      const DocumentsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
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
    return Expanded(
      child: GestureDetector(
        onTap: () => _openTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.photoResizeCard : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.primaryButton : AppColors.mutedText,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color:
                      selected ? AppColors.primaryButton : AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
