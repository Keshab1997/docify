import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/drive/auto_sync.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../tools/tool_registry.dart';
import '../widgets/ad_banner.dart';
import '../widgets/update_dialog.dart';
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

  // Delayed opt-in auto-backup attempt; kept so dispose() can cancel it
  // (no pending timers for a screen that no longer exists).
  Timer? _autoSyncTimer;

  // Play Store update check, shaped like the auto-backup timer above: a few
  // seconds after the first frame, so launch, onboarding and the first ad
  // never compete with it — and nothing here talks to Play before that.
  Timer? _updateTimer;

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
    _autoSyncTimer = Timer(const Duration(seconds: 4), AutoSync.maybeRun);
    // Play already knows whether this install is out of date; asking early
    // enough that the user can update in the same session, late enough that
    // the dialog never lands on top of the first screen.
    _updateTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) unawaited(showUpdatePromptIfAny(context));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backups also top up when the app returns to the foreground;
    // AutoSync debounces this (15 min) so resume-flapping is free.
    if (state == AppLifecycleState.resumed) {
      AutoSync.maybeRun();
      // A flexible update keeps downloading while the app is backgrounded;
      // returning to the foreground is when a finished one can be installed.
      // A missing update never prompts from here — that is launch's job.
      unawaited(showUpdatePromptIfAny(context, onResume: true));
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _updateTimer?.cancel();
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
        DocumentsScreen(
          key: _docsKey,
          active: _index == 2,
          onBrowseTools: () => _openTab(1),
        ),
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

  /// Back steps out before it leaves: an open Documents folder closes first,
  /// any other tab returns to Home, and only Home lets the app close.
  void _onBack() {
    if (_docsKey.currentState?.closeOpenFolder() ?? false) return;
    _navTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        // Only Home lets Back close the app; other tabs go Home first.
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: FadeTransition(
          opacity: _fadeCurve,
          child: IndexedStack(index: _index, children: _screens),
        ),
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
