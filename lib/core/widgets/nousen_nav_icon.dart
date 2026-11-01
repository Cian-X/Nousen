import 'package:flutter/material.dart';

/// Standard Material icon adapter for Nousen.
///
/// Directly renders Flutter's standard Material Icons.
class NousenNavIcon extends StatelessWidget {
  const NousenNavIcon(
    this.icon, {
    super.key,
    this.color,
    this.size = 24,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor =
        color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return Icon(icon, color: resolvedColor, size: size);
  }
}
