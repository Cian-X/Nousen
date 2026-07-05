import 'package:flutter/material.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/utils/activity_icon_utils.dart';

class ActivityStickerBadge extends StatelessWidget {
  const ActivityStickerBadge({
    super.key,
    required this.iconKey,
    this.size = 28,
    this.accent,
    this.selected = false,
  });

  final String? iconKey;
  final double size;
  final Color? accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tone = accent ?? theme.colorScheme.primary;
    final String normalized = normalizeActivityIconKey(iconKey);
    final IconData icon = resolveActivityIcon(iconKey);
    final int hash = normalized.codeUnits.fold<int>(
      0,
      (int sum, int unit) => (sum * 31 + unit) & 0x7fffffff,
    );
    final double tilt = ((hash % 7) - 3) * 0.014;

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      scale: selected ? 1.06 : 1,
      child: Transform.rotate(
        angle: tilt,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: selected ? 0.24 : 0.14),
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(
              color: tone.withValues(alpha: selected ? 0.82 : 0.52),
              width: selected ? 1.8 : 1.3,
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: size * 0.1,
                top: size * 0.08,
                child: Icon(
                  Icons.star_rounded,
                  size: size * 0.18,
                  color: tone.withValues(alpha: selected ? 0.95 : 0.75),
                ),
              ),
              Center(
                child: Icon(icon, size: size * 0.54, color: tone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
