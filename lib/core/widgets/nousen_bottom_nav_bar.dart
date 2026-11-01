import 'package:flutter/material.dart';
import 'package:nousen/core/widgets/nousen_nav_icon.dart';

/// Defines a single tab in the Nousen bottom navigation bar.
class NousenNavTab {
  const NousenNavTab({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
}

/// Shared bottom navigation bar used across all pages.
class NousenBottomNavBar extends StatelessWidget {
  const NousenBottomNavBar({
    super.key,
    required this.tabs,
    this.onCenterActionTap,
    this.centerActionIcon = Icons.add_rounded,
    this.centerActionTooltip,
  });

  final List<NousenNavTab> tabs;
  final VoidCallback? onCenterActionTap;
  final IconData centerActionIcon;
  final String? centerActionTooltip;

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final VoidCallback? onCenterTap = onCenterActionTap;

    final Widget content;
    if (onCenterTap != null && tabs.length >= 2) {
      final int mid = tabs.length ~/ 2;
      final List<NousenNavTab> leftTabs = tabs.sublist(0, mid);
      final List<NousenNavTab> rightTabs = tabs.sublist(mid);

      content = Row(
        children: <Widget>[
          for (final NousenNavTab tab in leftTabs)
            Expanded(child: Center(child: _buildItem(tab))),
          _buildCenterAction(context, onCenterTap),
          for (final NousenNavTab tab in rightTabs)
            Expanded(child: Center(child: _buildItem(tab))),
        ],
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map(_buildItem).toList(),
      );
    }

    return Container(
      height: 64 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildCenterAction(BuildContext context, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: centerActionTooltip ?? 'Tambah',
      child: Tooltip(
        message: centerActionTooltip ?? 'Tambah',
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3B7BD6),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF3B7BD6).withValues(alpha: 0.38),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: Icon(
                  centerActionIcon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(NousenNavTab tab) {
    return Builder(
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        final Color color = tab.isSelected
            ? const Color(0xFF3B7BD6)
            : const Color(0xFF64748B);
        return InkWell(
          onTap: tab.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                NousenNavIcon(tab.icon, color: color, size: tab.isSelected ? 24 : 22),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: tab.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tab.isSelected ? const Color(0xFF3B7BD6) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
