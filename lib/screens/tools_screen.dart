import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../tools/tool_registry.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/pressable.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key, this.group, this.link = 0, this.onGroup});

  /// The group pre-selected by a Home category card deep link.
  final ToolGroup? group;

  /// Bumped by the shell on every deep link; the filter applies whenever
  /// it changes, so tapping the same category twice still re-filters.
  final int link;

  /// Reports chip taps back to the shell so the state stays in one place.
  final ValueChanged<ToolGroup?>? onGroup;

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  ToolGroup? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.group;
  }

  @override
  void didUpdateWidget(covariant ToolsScreen old) {
    super.didUpdateWidget(old);
    if (old.link != widget.link) _selected = widget.group;
  }

  void _pick(ToolGroup? group) {
    setState(() => _selected = group);
    widget.onGroup?.call(group);
  }

  @override
  Widget build(BuildContext context) {
    final group = _selected;
    final tools =
        group == null ? ToolRegistry.all : ToolRegistry.inGroup(group);
    return Scaffold(
      appBar: AppBar(title: const Text('All tools')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(Space.lg, 2, Space.lg, 6),
              children: [
                _filterChip(null, 'All'),
                for (final g in ToolGroup.values) _filterChip(g, g.label),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.lg,
                28,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: tools.length,
              itemBuilder: (context, i) {
                final t = tools[i];
                void open() => t.open(context);
                // Reveal the grid in a short stagger, tick on press, and
                // expose one clean node to TalkBack instead of the four
                // texts inside the card. The key makes a filter change
                // re-reveal the new set instead of reusing old cards.
                return AnimatedReveal(
                  key: ValueKey(t.id),
                  index: i,
                  child: Pressable(
                    child: Semantics(
                      button: true,
                      label: '${t.title}. ${t.subtitle}',
                      onTap: open,
                      child: ExcludeSemantics(
                        child: _ToolCard(tool: t, onOpen: open),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(ToolGroup? group, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: Space.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: _selected == group,
        onSelected: (_) => _pick(group),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.onOpen});

  final ToolSpec tool;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.sheet),
        boxShadow: Soft.card,
      ),
      child: Material(
        color: tool.tint,
        borderRadius: BorderRadius.circular(Radii.sheet),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.sheet),
          onTap: onOpen,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, tool.tint],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.md, 10, Space.md, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        tool.art,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    tool.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tool.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
