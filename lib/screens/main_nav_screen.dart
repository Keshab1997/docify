import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/drive/auto_sync.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../tools/tool_registry.dart';
import '../widgets/ad_banner.dart';
import 'documents_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'tools_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _index = 0;
  final _docsKey = GlobalKey<DocumentsScreenState>();

  // Deep-link target for the Tools tab: Home's category cards set the
  // group and bump the link counter; the bottom bar never touches them,
  // so a chip filter survives tab switches.
  ToolGroup? _toolsGroup;
  int _toolsLink = 0;

  late final AnimationController _fade;
  late final Animation<double> _fadeCurve;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Starts at 1 so the first frame is fully visible; every tab change runs it
    // from 0 again to fade the new tab in.
    _fade = AnimationController(vsync: this, duration: Motion.short, value: 1);
    _fadeCurve = CurvedAnimation(parent: _fade, curve: Motion.enter);
    // Opt-in automatic backup: one silent attempt shortly after launch.
    // No-ops unless the user enabled it, is signed in and granted Drive —
    // it can never prompt (see AutoSync).
    Future<void>.delayed(const Duration(seconds: 4), AutoSync.maybeRun);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backups also top up when the app returns to the foreground;
    // AutoSync debounces this (15 min) so resume-flapping is free.
    if (state == AppLifecycleState.resumed) {
      AutoSync.maybeRun();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fade.dispose();
    super.dispose();
  }

  /// Rebuilt on every build so the Tools tab sees fresh deep-link state;
  /// IndexedStack keeps each screen's State alive by slot and type.
  List<Widget> get _screens => [
        HomeScreen(onOpenTab: _openTab),
        ToolsScreen(
          group: _toolsGroup,
          link: _toolsLink,
          onGroup: (g) => setState(() => _toolsGroup = g),
        ),
        DocumentsScreen(key: _docsKey, onBrowseTools: () => _openTab(1)),
        const ProfileScreen(),
      ];

  /// Bottom bar taps: switch the tab, keep whatever filter Tools had.
  void _navTo(int i) {
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

  /// Home deep links (category cards, "See all", empty-state CTA).
  void _openTab(int i, {ToolGroup? group}) {
    final changed = i != _index;
    setState(() {
      _index = i;
      if (i == 1) {
        _toolsGroup = group;
        _toolsLink++;
      }
    });
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
            margin: const EdgeInsets.fromLTRB(Space.lg, 4, Space.lg, Space.md),
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
    // Material + InkWell (not a bare GestureDetector) so the tab gets a
    // real ripple, and Semantics so TalkBack announces it as a button.
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        onTap: () => _navTo(index),
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.nav),
              onTap: () => _navTo(index),
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.short),
                curve: Motion.enter,
                padding: const EdgeInsets.symmetric(vertical: Space.sm),
                decoration: BoxDecoration(
                  color:
                      selected ? AppColors.photoResizeCard : Colors.transparent,
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
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: color,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
