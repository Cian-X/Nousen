import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double screenPadding = xl;
  static const double sectionGap = md;
  static const double componentGap = xs;
  static const double minorGap = xs;

  static const double cardPadding = 14;
  static const double heroCardPadding = cardPadding;
}

class AppRadius {
  const AppRadius._();

  static const double unified = 16;
  static const double card = unified;
  static const double button = unified;
  static const double small = unified;
  static const double pill = unified;
  static const double fab = unified;
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft(Color _) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> heroHome(Color _) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> fab(Color _, {bool active = false}) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: active ? 0.16 : 0.12),
        blurRadius: active ? 16 : 12,
        offset: const Offset(0, 6),
      ),
    ];
  }
}
