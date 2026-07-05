import 'package:flutter/material.dart';
import 'package:liburan_create/core/theme/app_layout.dart';

class CartoonAppBarActionButton extends StatelessWidget {
  const CartoonAppBarActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.accent,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: AppSpacing.xs,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.button),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.pressed)) {
                return accent.withValues(alpha: 0.12);
              }
              return null;
            }),
            child: Ink(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.button),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    accent.withValues(alpha: 0.26),
                    accent.withValues(alpha: 0.14),
                  ],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: 0.42),
                  width: 1.15,
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 8,
                    top: 7,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ),
                  Center(child: Icon(icon, size: 19, color: accent)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CartoonMiniActionButton extends StatelessWidget {
  const CartoonMiniActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.accent,
    required this.onPressed,
    this.size = 30,
    this.iconSize = 16,
  });

  final String tooltip;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.small);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return accent.withValues(alpha: 0.14);
            }
            return null;
          }),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  accent.withValues(alpha: 0.24),
                  accent.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 6,
                  top: 5,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.66),
                    ),
                  ),
                ),
                Center(
                  child: Icon(icon, size: iconSize, color: accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
