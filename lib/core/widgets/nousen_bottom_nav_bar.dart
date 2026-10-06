import 'package:flutter/material.dart';
import 'package:liburan_create/core/widgets/nousen_nav_icon.dart';

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
///
/// Replaces the duplicate `_buildNavItem` in home_shell_page.dart and
/// `_AgendaNavItem` in schedule_agenda_page.dart.
class NousenBottomNavBar extends StatelessWidget {
  const NousenBottomNavBar({super.key, required this.tabs});

  final List<NousenNavTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map(_buildItem).toList(),
      ),
    );
  }

  Widget _buildItem(NousenNavTab tab) {
    return Builder(
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        final Color color = tab.isSelected
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF64748B);
        return InkWell(
          onTap: tab.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    color: tab.isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
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
