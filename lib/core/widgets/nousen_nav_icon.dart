import 'package:flutter/material.dart';

/// Custom rounded line icons for Nousen.
///
/// Renders a hand‑drawn outline glyph via [CustomPaint].  When the requested
/// [icon] has no dedicated painter the widget falls back to a standard
/// Material [Icon] so there is never an empty box.
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
    final resolvedColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    if (!_NousenIconPainter._supported.contains(icon)) {
      return Icon(icon, color: resolvedColor, size: size);
    }
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _NousenIconPainter(icon: icon, color: resolvedColor),
      ),
    );
  }
}

class _NousenIconPainter extends CustomPainter {
  const _NousenIconPainter({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  // Registry of icons that have a custom painter.
  static final Set<IconData> _supported = <IconData>{
    Icons.home_rounded,
    Icons.calendar_today_rounded,
    Icons.calendar_month_rounded,
    Icons.insights_rounded,
    Icons.person_rounded,
    Icons.person_outline_rounded,
    Icons.notifications_active_outlined,
    Icons.vibration_rounded,
    Icons.smart_toy_outlined,
    Icons.language_rounded,
    Icons.feedback_outlined,
    Icons.info_outline_rounded,
    Icons.developer_mode_rounded,
    Icons.badge_outlined,
    Icons.event_note_rounded,
    Icons.work_outline_rounded,
    Icons.school_outlined,
    Icons.beach_access_rounded,
    Icons.auto_awesome_motion_rounded,
    Icons.tune_rounded,
    Icons.schedule_rounded,
    Icons.close_rounded,
    Icons.check_rounded,
    Icons.chevron_right_rounded,
    Icons.chevron_left_rounded,
    // ── Additional glyphs ──
    Icons.add,
    Icons.add_rounded,
    Icons.add_photo_alternate_outlined,
    Icons.arrow_forward_rounded,
    Icons.auto_awesome_rounded,
    Icons.bar_chart_rounded,
    Icons.bolt_rounded,
    Icons.broken_image_rounded,
    Icons.camera_alt_rounded,
    Icons.check_circle_rounded,
    Icons.compare_arrows_rounded,
    Icons.date_range_rounded,
    Icons.description_outlined,
    Icons.done_all_rounded,
    Icons.event_available_rounded,
    Icons.expand_less_rounded,
    Icons.expand_more_rounded,
    Icons.face_rounded,
    Icons.filter_list_rounded,
    Icons.lightbulb_rounded,
    Icons.local_fire_department_rounded,
    Icons.more_horiz_rounded,
    Icons.notifications_rounded,
    Icons.photo_camera_outlined,
    Icons.photo_library_outlined,
    Icons.radio_button_unchecked_rounded,
    Icons.sentiment_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_satisfied_alt_rounded,
    Icons.sentiment_very_satisfied_rounded,
    Icons.star_rounded,
    Icons.sticky_note_2_rounded,
    Icons.trending_up_rounded,
    Icons.warning_amber_rounded,
    Icons.wb_sunny_rounded,
    // ── Batch 3 ──
    Icons.access_time_rounded,
    Icons.assignment_rounded,
    Icons.celebration_rounded,
    Icons.check,
    Icons.fast_forward,
    Icons.grid_view_rounded,
    Icons.local_fire_department,
    Icons.open_in_new_rounded,
    Icons.smart_toy_rounded,
    Icons.trending_down_rounded,
    Icons.undo_rounded,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / 24;
    canvas..save()..scale(scale);

    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _dispatch(canvas, line, fill);
    canvas.restore();
  }

  void _dispatch(Canvas c, Paint line, Paint fill) {
    if (icon == Icons.home_rounded) {
      _drawHome(c, line);
    } else if (icon == Icons.calendar_today_rounded ||
        icon == Icons.calendar_month_rounded) {
      _drawCalendar(c, line, fill,
          showDates: icon == Icons.calendar_month_rounded);
    } else if (icon == Icons.insights_rounded) {
      _drawInsights(c, line);
    } else if (icon == Icons.person_rounded ||
        icon == Icons.person_outline_rounded) {
      _drawPerson(c, line);
    } else if (icon == Icons.notifications_active_outlined) {
      _drawBell(c, line, fill);
    } else if (icon == Icons.vibration_rounded) {
      _drawVibration(c, line);
    } else if (icon == Icons.smart_toy_outlined) {
      _drawRobot(c, line, fill);
    } else if (icon == Icons.language_rounded) {
      _drawGlobe(c, line);
    } else if (icon == Icons.feedback_outlined) {
      _drawFeedback(c, line, fill);
    } else if (icon == Icons.info_outline_rounded) {
      _drawInfo(c, line, fill);
    } else if (icon == Icons.developer_mode_rounded) {
      _drawDevMode(c, line);
    } else if (icon == Icons.badge_outlined) {
      _drawBadge(c, line, fill);
    } else if (icon == Icons.event_note_rounded) {
      _drawEventNote(c, line, fill);
    } else if (icon == Icons.work_outline_rounded) {
      _drawBriefcase(c, line);
    } else if (icon == Icons.school_outlined) {
      _drawSchool(c, line);
    } else if (icon == Icons.beach_access_rounded) {
      _drawUmbrella(c, line);
    } else if (icon == Icons.auto_awesome_motion_rounded) {
      _drawMotion(c, line);
    } else if (icon == Icons.tune_rounded) {
      _drawTune(c, line, fill);
    } else if (icon == Icons.schedule_rounded) {
      _drawClock(c, line);
    } else if (icon == Icons.close_rounded) {
      _drawClose(c, line);
    } else if (icon == Icons.check_rounded) {
      _drawCheck(c, line);
    } else if (icon == Icons.chevron_right_rounded) {
      _drawChevronRight(c, line);
    } else if (icon == Icons.chevron_left_rounded) {
      _drawChevronLeft(c, line);
    } else if (icon == Icons.add || icon == Icons.add_rounded) {
      _drawAdd(c, line);
    } else if (icon == Icons.add_photo_alternate_outlined) {
      _drawAddPhoto(c, line);
    } else if (icon == Icons.arrow_forward_rounded) {
      _drawArrowForward(c, line);
    } else if (icon == Icons.auto_awesome_rounded) {
      _drawSparkle(c, line);
    } else if (icon == Icons.bar_chart_rounded) {
      _drawBarChart(c, line);
    } else if (icon == Icons.bolt_rounded) {
      _drawBolt(c, line);
    } else if (icon == Icons.broken_image_rounded) {
      _drawBrokenImage(c, line);
    } else if (icon == Icons.camera_alt_rounded) {
      _drawCamera(c, line, fill);
    } else if (icon == Icons.check_circle_rounded) {
      _drawCheckCircle(c, line);
    } else if (icon == Icons.compare_arrows_rounded) {
      _drawCompareArrows(c, line);
    } else if (icon == Icons.date_range_rounded) {
      _drawCalendar(c, line, fill, showDates: true);
    } else if (icon == Icons.description_outlined) {
      _drawDescription(c, line);
    } else if (icon == Icons.done_all_rounded) {
      _drawDoneAll(c, line);
    } else if (icon == Icons.event_available_rounded) {
      _drawEventAvailable(c, line);
    } else if (icon == Icons.expand_less_rounded) {
      _drawExpandLess(c, line);
    } else if (icon == Icons.expand_more_rounded) {
      _drawExpandMore(c, line);
    } else if (icon == Icons.face_rounded) {
      _drawFace(c, line, fill);
    } else if (icon == Icons.filter_list_rounded) {
      _drawFilterList(c, line);
    } else if (icon == Icons.lightbulb_rounded) {
      _drawLightbulb(c, line);
    } else if (icon == Icons.local_fire_department_rounded) {
      _drawFire(c, line);
    } else if (icon == Icons.more_horiz_rounded) {
      _drawMoreHoriz(c, fill);
    } else if (icon == Icons.notifications_rounded) {
      _drawBell(c, line, fill);
    } else if (icon == Icons.photo_camera_outlined) {
      _drawCamera(c, line, fill);
    } else if (icon == Icons.photo_library_outlined) {
      _drawPhotoLibrary(c, line);
    } else if (icon == Icons.radio_button_unchecked_rounded) {
      _drawRadioUnchecked(c, line);
    } else if (icon == Icons.sentiment_very_satisfied_rounded) {
      _drawSmiley(c, line, fill, mood: 4);
    } else if (icon == Icons.sentiment_satisfied_alt_rounded) {
      _drawSmiley(c, line, fill, mood: 3);
    } else if (icon == Icons.sentiment_neutral_rounded) {
      _drawSmiley(c, line, fill, mood: 2);
    } else if (icon == Icons.sentiment_dissatisfied_rounded) {
      _drawSmiley(c, line, fill, mood: 1);
    } else if (icon == Icons.star_rounded) {
      _drawStar(c, line);
    } else if (icon == Icons.sticky_note_2_rounded) {
      _drawStickyNote(c, line);
    } else if (icon == Icons.trending_up_rounded) {
      _drawTrendingUp(c, line);
    } else if (icon == Icons.warning_amber_rounded) {
      _drawWarning(c, line);
    } else if (icon == Icons.wb_sunny_rounded) {
      _drawSun(c, line);
    } else if (icon == Icons.access_time_rounded) {
      _drawClock(c, line);
    } else if (icon == Icons.assignment_rounded) {
      _drawAssignment(c, line);
    } else if (icon == Icons.celebration_rounded) {
      _drawCelebration(c, line);
    } else if (icon == Icons.check) {
      _drawCheck(c, line);
    } else if (icon == Icons.fast_forward) {
      _drawFastForward(c, line);
    } else if (icon == Icons.grid_view_rounded) {
      _drawGridView(c, line);
    } else if (icon == Icons.local_fire_department) {
      _drawFire(c, line);
    } else if (icon == Icons.open_in_new_rounded) {
      _drawOpenInNew(c, line);
    } else if (icon == Icons.smart_toy_rounded) {
      _drawRobot(c, line, fill);
    } else if (icon == Icons.trending_down_rounded) {
      _drawTrendingDown(c, line);
    } else if (icon == Icons.undo_rounded) {
      _drawUndo(c, line);
    }
  }

  // ── Navbar ────────────────────────────────────────────────

  void _drawHome(Canvas c, Paint p) {
    c.drawPath(
        Path()
          ..moveTo(3.5, 10.5)
          ..lineTo(12, 4)
          ..lineTo(20.5, 10.5),
        p);
    c.drawPath(
        Path()
          ..moveTo(5.5, 9.5)
          ..lineTo(5.5, 20)
          ..quadraticBezierTo(5.5, 20.5, 6, 20.5)
          ..lineTo(18, 20.5)
          ..quadraticBezierTo(18.5, 20.5, 18.5, 20)
          ..lineTo(18.5, 9.5),
        p);
    c..drawLine(const Offset(10, 20), const Offset(10, 15), p)
      ..drawLine(const Offset(14, 20), const Offset(14, 15), p);
  }

  void _drawCalendar(Canvas c, Paint p, Paint f, {required bool showDates}) {
    c..drawRRect(RRect.fromRectAndRadius(
          const Rect.fromLTRB(4, 5.5, 20, 20.5), const Radius.circular(3)), p)
      ..drawLine(const Offset(4.5, 10), const Offset(19.5, 10), p)
      ..drawLine(const Offset(9, 3.5), const Offset(9, 7), p)
      ..drawLine(const Offset(15, 3.5), const Offset(15, 7), p);
    if (showDates) {
      for (final double y in const <double>[14, 17]) {
        for (final double x in const <double>[9, 12, 15]) {
          if (y == 17 && x == 15) continue;
          c.drawCircle(Offset(x, y), 0.85, f);
        }
      }
    } else {
      c.drawRRect(RRect.fromRectAndRadius(
          const Rect.fromLTRB(8, 12.5, 16, 18), const Radius.circular(2)), f);
    }
  }

  void _drawInsights(Canvas c, Paint p) {
    c..drawLine(const Offset(4, 20), const Offset(20, 20), p)
      ..drawLine(const Offset(7, 19.5), const Offset(7, 14), p)
      ..drawLine(const Offset(12, 19.5), const Offset(12, 10), p)
      ..drawLine(const Offset(17, 19.5), const Offset(17, 6), p);
    c.drawPath(
        Path()
          ..moveTo(5, 11)
          ..lineTo(10, 8)
          ..lineTo(14, 10)
          ..lineTo(19, 4.5),
        p);
    c..drawLine(const Offset(16.5, 4.5), const Offset(19, 4.5), p)
      ..drawLine(const Offset(19, 4.5), const Offset(19, 7), p);
  }

  void _drawPerson(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 8), 3.5, p);
    c.drawPath(
        Path()
          ..moveTo(5.5, 20)
          ..cubicTo(6.5, 16.7, 8.7, 15, 12, 15)
          ..cubicTo(15.3, 15, 17.5, 16.7, 18.5, 20),
        p);
  }

  // ── Settings icons ────────────────────────────────────────

  void _drawBell(Canvas c, Paint p, Paint f) {
    // Bell body
    c.drawPath(
        Path()
          ..moveTo(6, 14)
          ..cubicTo(6, 9, 8, 5.5, 12, 5.5)
          ..cubicTo(16, 5.5, 18, 9, 18, 14)
          ..lineTo(19.5, 17)
          ..lineTo(4.5, 17)
          ..close(),
        p);
    // Clapper
    c.drawPath(
        Path()
          ..moveTo(10, 17.5)
          ..cubicTo(10, 19.5, 14, 19.5, 14, 17.5),
        p);
    // Top nub
    c.drawCircle(const Offset(12, 4.5), 1, f);
    // Sound waves
    c..drawLine(const Offset(3.5, 8), const Offset(2, 6.5), p)
      ..drawLine(const Offset(20.5, 8), const Offset(22, 6.5), p);
  }

  void _drawVibration(Canvas c, Paint p) {
    // Phone body
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(9, 4, 15, 20), const Radius.circular(2)), p);
    // Vibration lines left
    c..drawLine(const Offset(6.5, 8), const Offset(6.5, 16), p)
      ..drawLine(const Offset(4, 10), const Offset(4, 14), p);
    // Vibration lines right
    c..drawLine(const Offset(17.5, 8), const Offset(17.5, 16), p)
      ..drawLine(const Offset(20, 10), const Offset(20, 14), p);
  }

  void _drawRobot(Canvas c, Paint p, Paint f) {
    // Head
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(5, 7, 19, 17), const Radius.circular(3)), p);
    // Antenna
    c.drawLine(const Offset(12, 7), const Offset(12, 4.5), p);
    c.drawCircle(const Offset(12, 3.5), 1, p);
    // Eyes
    c..drawCircle(const Offset(9, 12), 1.2, f)
      ..drawCircle(const Offset(15, 12), 1.2, f);
    // Mouth
    c.drawLine(const Offset(9.5, 14.5), const Offset(14.5, 14.5), p);
    // Ears
    c..drawLine(const Offset(3.5, 10), const Offset(3.5, 14), p)
      ..drawLine(const Offset(20.5, 10), const Offset(20.5, 14), p);
  }

  void _drawGlobe(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 8, p);
    // Horizontal lines
    c..drawLine(const Offset(4, 12), const Offset(20, 12), p)
      ..drawLine(const Offset(5.5, 8), const Offset(18.5, 8), p)
      ..drawLine(const Offset(5.5, 16), const Offset(18.5, 16), p);
    // Vertical meridian
    c.drawPath(
        Path()
          ..moveTo(12, 4)
          ..cubicTo(8.5, 7, 8.5, 17, 12, 20),
        p);
    c.drawPath(
        Path()
          ..moveTo(12, 4)
          ..cubicTo(15.5, 7, 15.5, 17, 12, 20),
        p);
  }

  void _drawFeedback(Canvas c, Paint p, Paint f) {
    // Chat bubble
    c.drawPath(
        Path()
          ..moveTo(4, 5)
          ..lineTo(20, 5)
          ..quadraticBezierTo(21, 5, 21, 6)
          ..lineTo(21, 15)
          ..quadraticBezierTo(21, 16, 20, 16)
          ..lineTo(8, 16)
          ..lineTo(5, 19.5)
          ..lineTo(5, 16)
          ..lineTo(4, 16)
          ..quadraticBezierTo(3, 16, 3, 15)
          ..lineTo(3, 6)
          ..quadraticBezierTo(3, 5, 4, 5)
          ..close(),
        p);
    // Dots
    for (final double x in const <double>[9, 12, 15]) {
      c.drawCircle(Offset(x, 10.5), 1, f);
    }
  }

  void _drawInfo(Canvas c, Paint p, Paint f) {
    c.drawCircle(const Offset(12, 12), 8, p);
    c.drawCircle(const Offset(12, 8), 1.1, f);
    c..drawLine(const Offset(12, 11), const Offset(12, 17), p)
      ..drawLine(const Offset(10, 17), const Offset(14, 17), p);
  }

  void _drawDevMode(Canvas c, Paint p) {
    // Phone outline
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(6, 3, 18, 21), const Radius.circular(2.5)), p);
    // Code brackets < >
    c.drawPath(
        Path()
          ..moveTo(11, 9)
          ..lineTo(8.5, 12)
          ..lineTo(11, 15),
        p);
    c.drawPath(
        Path()
          ..moveTo(13, 9)
          ..lineTo(15.5, 12)
          ..lineTo(13, 15),
        p);
  }

  void _drawBadge(Canvas c, Paint p, Paint f) {
    // Badge card
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(3.5, 5, 20.5, 19), const Radius.circular(2.5)), p);
    // Avatar circle
    c.drawCircle(const Offset(8, 10.5), 2.2, p);
    // Text lines
    c..drawLine(const Offset(12.5, 9), const Offset(18, 9), p)
      ..drawLine(const Offset(12.5, 12), const Offset(17, 12), p);
    // Bottom line
    c.drawLine(const Offset(6, 16), const Offset(18, 16), p);
  }

  void _drawEventNote(Canvas c, Paint p, Paint f) {
    // Note card
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(4, 4, 20, 20), const Radius.circular(2.5)), p);
    // Lines
    c..drawLine(const Offset(7, 9), const Offset(17, 9), p)
      ..drawLine(const Offset(7, 12.5), const Offset(17, 12.5), p)
      ..drawLine(const Offset(7, 16), const Offset(13, 16), p);
  }

  void _drawBriefcase(Canvas c, Paint p) {
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(3, 8, 21, 19.5), const Radius.circular(2.5)), p);
    // Handle
    c.drawPath(
        Path()
          ..moveTo(8.5, 8)
          ..lineTo(8.5, 6)
          ..quadraticBezierTo(8.5, 5, 9.5, 5)
          ..lineTo(14.5, 5)
          ..quadraticBezierTo(15.5, 5, 15.5, 6)
          ..lineTo(15.5, 8),
        p);
    // Middle line
    c.drawLine(const Offset(3, 13), const Offset(21, 13), p);
  }

  void _drawSchool(Canvas c, Paint p) {
    // Cap top
    c.drawPath(
        Path()
          ..moveTo(2.5, 10)
          ..lineTo(12, 5.5)
          ..lineTo(21.5, 10)
          ..lineTo(12, 14.5)
          ..close(),
        p);
    // Tassel
    c.drawPath(
        Path()
          ..moveTo(7, 12)
          ..lineTo(7, 17)
          ..quadraticBezierTo(7, 18.5, 12, 18.5)
          ..quadraticBezierTo(17, 18.5, 17, 17)
          ..lineTo(17, 12),
        p);
    // Pole
    c.drawLine(const Offset(20, 10), const Offset(20, 17.5), p);
  }

  void _drawUmbrella(Canvas c, Paint p) {
    // Canopy
    c.drawPath(
        Path()
          ..moveTo(3.5, 13)
          ..cubicTo(3.5, 6, 20.5, 6, 20.5, 13),
        p);
    // Scallops
    c.drawPath(
        Path()
          ..moveTo(3.5, 13)
          ..cubicTo(5, 11, 7, 11, 8.5, 13)
          ..cubicTo(10, 11, 14, 11, 15.5, 13)
          ..cubicTo(17, 11, 19, 11, 20.5, 13),
        p);
    // Stick
    c.drawLine(const Offset(12, 6), const Offset(12, 19), p);
    // Hook
    c.drawPath(
        Path()
          ..moveTo(12, 19)
          ..cubicTo(12, 20.5, 10, 20.5, 10, 19),
        p);
  }

  void _drawMotion(Canvas c, Paint p) {
    // Stacked rectangles (motion layers)
    for (int i = 0; i < 3; i++) {
      final double dx = i * 3.0;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(5 + dx, 5, 15 + dx, 19),
          const Radius.circular(2),
        ),
        p,
      );
    }
  }

  void _drawTune(Canvas c, Paint p, Paint f) {
    // Three horizontal lines with dots
    for (final (double y, double kx)
        in const <(double, double)>[(8, 8), (12, 15), (16, 10)]) {
      c.drawLine(Offset(4, y), Offset(20, y), p);
      c.drawCircle(Offset(kx, y), 2.2, f);
      // White center for outline look
      c.drawCircle(
          Offset(kx, y),
          1.2,
          Paint()
            ..color = const Color(0xFFFFFFFF)
            ..style = PaintingStyle.fill);
    }
  }

  void _drawClock(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 8, p);
    // Hour hand
    c.drawLine(const Offset(12, 12), const Offset(12, 7.5), p);
    // Minute hand
    c.drawLine(const Offset(12, 12), const Offset(16, 12), p);
    // Center dot
    c.drawCircle(const Offset(12, 12), 1, Paint()..color = color);
  }

  // ── Utility icons ─────────────────────────────────────────

  void _drawClose(Canvas c, Paint p) {
    c..drawLine(const Offset(7, 7), const Offset(17, 17), p)
      ..drawLine(const Offset(17, 7), const Offset(7, 17), p);
  }

  void _drawCheck(Canvas c, Paint p) {
    c.drawPath(
        Path()
          ..moveTo(5, 12.5)
          ..lineTo(10, 17.5)
          ..lineTo(19, 7),
        p);
  }

  void _drawChevronRight(Canvas c, Paint p) {
    c.drawPath(
        Path()
          ..moveTo(9, 5)
          ..lineTo(16, 12)
          ..lineTo(9, 19),
        p);
  }

  void _drawChevronLeft(Canvas c, Paint p) {
    c.drawPath(
        Path()
          ..moveTo(15, 5)
          ..lineTo(8, 12)
          ..lineTo(15, 19),
        p);
  }

  // ── Additional glyphs ─────────────────────────────────────

  void _drawAdd(Canvas c, Paint p) {
    c..drawLine(const Offset(12, 5), const Offset(12, 19), p)
      ..drawLine(const Offset(5, 12), const Offset(19, 12), p);
  }

  void _drawAddPhoto(Canvas c, Paint p) {
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(3, 5, 21, 20), const Radius.circular(2)), p);
    // Mountain
    c.drawPath(Path()..moveTo(5, 18)..lineTo(9, 13)..lineTo(12, 16)..lineTo(15, 12)..lineTo(19, 18), p);
    // Plus
    c..drawLine(const Offset(17, 3), const Offset(17, 9), p)
      ..drawLine(const Offset(14, 6), const Offset(20, 6), p);
  }

  void _drawArrowForward(Canvas c, Paint p) {
    c.drawLine(const Offset(4, 12), const Offset(19, 12), p);
    c.drawPath(Path()..moveTo(14, 7)..lineTo(19, 12)..lineTo(14, 17), p);
  }

  void _drawSparkle(Canvas c, Paint p) {
    // Four-pointed star
    c.drawPath(Path()
      ..moveTo(12, 3)..lineTo(13.5, 9)..lineTo(20, 12)..lineTo(13.5, 15)
      ..lineTo(12, 21)..lineTo(10.5, 15)..lineTo(4, 12)..lineTo(10.5, 9)..close(), p);
    // Small sparkle
    c.drawCircle(const Offset(18, 5.5), 0.8, p);
  }

  void _drawBarChart(Canvas c, Paint p) {
    c..drawLine(const Offset(6, 20), const Offset(6, 14), p)
      ..drawLine(const Offset(10, 20), const Offset(10, 8), p)
      ..drawLine(const Offset(14, 20), const Offset(14, 11), p)
      ..drawLine(const Offset(18, 20), const Offset(18, 5), p);
  }

  void _drawBolt(Canvas c, Paint p) {
    c.drawPath(Path()
      ..moveTo(13.5, 3)..lineTo(8, 13)..lineTo(12, 13)..lineTo(10.5, 21)
      ..lineTo(16, 11)..lineTo(12, 11)..close(), p);
  }

  void _drawBrokenImage(Canvas c, Paint p) {
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(3, 4, 21, 20), const Radius.circular(2)), p);
    c.drawPath(Path()..moveTo(3, 14)..lineTo(8, 10)..lineTo(13, 14)..lineTo(16, 11)..lineTo(21, 16), p);
  }

  void _drawCamera(Canvas c, Paint p, Paint f) {
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(3, 7, 21, 19), const Radius.circular(2.5)), p);
    c.drawPath(Path()..moveTo(8, 7)..lineTo(9.5, 4.5)..lineTo(14.5, 4.5)..lineTo(16, 7), p);
    c.drawCircle(const Offset(12, 13), 3, p);
  }

  void _drawCheckCircle(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 8, p);
    c.drawPath(Path()..moveTo(7.5, 12)..lineTo(10.5, 15.5)..lineTo(16.5, 8.5), p);
  }

  void _drawCompareArrows(Canvas c, Paint p) {
    // Right arrow
    c.drawLine(const Offset(4, 8), const Offset(18, 8), p);
    c.drawPath(Path()..moveTo(14, 5)..lineTo(18, 8)..lineTo(14, 11), p);
    // Left arrow
    c.drawLine(const Offset(20, 16), const Offset(6, 16), p);
    c.drawPath(Path()..moveTo(10, 13)..lineTo(6, 16)..lineTo(10, 19), p);
  }

  void _drawDescription(Canvas c, Paint p) {
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(4, 3, 20, 21), const Radius.circular(2)), p);
    c..drawLine(const Offset(7, 8), const Offset(17, 8), p)
      ..drawLine(const Offset(7, 12), const Offset(17, 12), p)
      ..drawLine(const Offset(7, 16), const Offset(13, 16), p);
  }

  void _drawDoneAll(Canvas c, Paint p) {
    // Back check
    c.drawPath(Path()..moveTo(2, 12)..lineTo(7, 17)..lineTo(18, 6), p);
    // Front check
    c.drawPath(Path()..moveTo(6, 12)..lineTo(11, 17)..lineTo(22, 6), p);
  }

  void _drawEventAvailable(Canvas c, Paint p) {
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(4, 5.5, 20, 20.5), const Radius.circular(3)), p);
    c..drawLine(const Offset(4.5, 10), const Offset(19.5, 10), p)
      ..drawLine(const Offset(9, 3.5), const Offset(9, 7), p)
      ..drawLine(const Offset(15, 3.5), const Offset(15, 7), p);
    c.drawPath(Path()..moveTo(9, 14.5)..lineTo(11, 17)..lineTo(15.5, 13), p);
  }

  void _drawExpandLess(Canvas c, Paint p) {
    c.drawPath(Path()..moveTo(7, 15)..lineTo(12, 9)..lineTo(17, 15), p);
  }

  void _drawExpandMore(Canvas c, Paint p) {
    c.drawPath(Path()..moveTo(7, 9)..lineTo(12, 15)..lineTo(17, 9), p);
  }

  void _drawFace(Canvas c, Paint p, Paint f) {
    c.drawCircle(const Offset(12, 12), 8, p);
    c..drawCircle(const Offset(9, 10.5), 1.1, f)
      ..drawCircle(const Offset(15, 10.5), 1.1, f);
    c.drawPath(Path()..moveTo(8.5, 15)..cubicTo(9.5, 17, 14.5, 17, 15.5, 15), p);
  }

  void _drawFilterList(Canvas c, Paint p) {
    c..drawLine(const Offset(4, 7), const Offset(20, 7), p)
      ..drawLine(const Offset(7, 12), const Offset(17, 12), p)
      ..drawLine(const Offset(10, 17), const Offset(14, 17), p);
  }

  void _drawLightbulb(Canvas c, Paint p) {
    c.drawPath(Path()
      ..moveTo(9, 19)..lineTo(9, 16)
      ..cubicTo(6, 14.5, 5, 11, 6, 8)
      ..cubicTo(7, 5, 10, 3.5, 12, 3.5)
      ..cubicTo(14, 3.5, 17, 5, 18, 8)
      ..cubicTo(19, 11, 18, 14.5, 15, 16)
      ..lineTo(15, 19)..close(), p);
    c..drawLine(const Offset(9.5, 17), const Offset(14.5, 17), p)
      ..drawLine(const Offset(10, 21), const Offset(14, 21), p);
  }

  void _drawFire(Canvas c, Paint p) {
    c.drawPath(Path()
      ..moveTo(12, 3)
      ..cubicTo(12, 7, 17, 9, 17, 14)
      ..cubicTo(17, 17, 14.5, 20, 12, 20)
      ..cubicTo(9.5, 20, 7, 17, 7, 14)
      ..cubicTo(7, 10, 10, 8, 12, 3), p);
    c.drawPath(Path()
      ..moveTo(12, 12)
      ..cubicTo(13.5, 13, 14, 14.5, 13, 16)
      ..cubicTo(12.5, 17, 11.5, 17, 11, 16)
      ..cubicTo(10, 14.5, 10.5, 13, 12, 12), p);
  }

  void _drawMoreHoriz(Canvas c, Paint f) {
    for (final double x in const <double>[7, 12, 17]) {
      c.drawCircle(Offset(x, 12), 1.5, f);
    }
  }

  void _drawPhotoLibrary(Canvas c, Paint p) {
    // Back card
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(5, 3, 21, 17), const Radius.circular(2)), p);
    // Front card
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(3, 7, 19, 21), const Radius.circular(2)), p);
    // Mountain
    c.drawPath(Path()..moveTo(5, 18)..lineTo(8, 14)..lineTo(11, 16)..lineTo(14, 12)..lineTo(17, 18), p);
  }

  void _drawRadioUnchecked(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 7.5, p);
  }

  void _drawSmiley(Canvas c, Paint p, Paint f, {required int mood}) {
    c.drawCircle(const Offset(12, 12), 8, p);
    c..drawCircle(const Offset(9, 10.5), 1.1, f)
      ..drawCircle(const Offset(15, 10.5), 1.1, f);
    if (mood == 4) {
      c.drawPath(Path()..moveTo(7.5, 14)..cubicTo(8.5, 17.5, 15.5, 17.5, 16.5, 14), p);
    } else if (mood == 3) {
      c.drawPath(Path()..moveTo(8.5, 15)..cubicTo(9.5, 16.5, 14.5, 16.5, 15.5, 15), p);
    } else if (mood == 2) {
      c.drawLine(const Offset(9, 15.5), const Offset(15, 15.5), p);
    } else {
      c.drawPath(Path()..moveTo(8.5, 16.5)..cubicTo(9.5, 14.5, 14.5, 14.5, 15.5, 16.5), p);
    }
  }

  void _drawStar(Canvas c, Paint p) {
    c.drawPath(Path()
      ..moveTo(12, 3.5)..lineTo(14, 9)..lineTo(20, 9.5)..lineTo(15.5, 13.5)
      ..lineTo(17, 19.5)..lineTo(12, 16.5)..lineTo(7, 19.5)..lineTo(8.5, 13.5)
      ..lineTo(4, 9.5)..lineTo(10, 9)..close(), p);
  }

  void _drawStickyNote(Canvas c, Paint p) {
    c.drawPath(Path()
      ..moveTo(4, 4)..lineTo(20, 4)
      ..quadraticBezierTo(20.5, 4, 20.5, 4.5)
      ..lineTo(20.5, 15)..lineTo(15, 20.5)
      ..lineTo(4.5, 20.5)
      ..quadraticBezierTo(4, 20.5, 4, 20)
      ..close(), p);
    c.drawPath(Path()..moveTo(15, 20.5)..lineTo(15, 16)..quadraticBezierTo(15, 15, 16, 15)..lineTo(20.5, 15), p);
    c..drawLine(const Offset(7, 9), const Offset(17, 9), p)
      ..drawLine(const Offset(7, 13), const Offset(13, 13), p);
  }

  void _drawTrendingUp(Canvas c, Paint p) {
    c.drawPath(Path()..moveTo(4, 17)..lineTo(9, 11)..lineTo(13, 14)..lineTo(20, 7), p);
    c..drawLine(const Offset(16, 7), const Offset(20, 7), p)
      ..drawLine(const Offset(20, 7), const Offset(20, 11), p);
  }

  void _drawWarning(Canvas c, Paint p) {
    c.drawPath(Path()
      ..moveTo(12, 3.5)..lineTo(21, 19.5)..lineTo(3, 19.5)..close(), p);
    c.drawLine(const Offset(12, 10), const Offset(12, 14.5), p);
    c.drawCircle(const Offset(12, 17), 0.9, Paint()..color = color);
  }

  void _drawSun(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 4.5, p);
    const List<Offset> rays = <Offset>[
      Offset(12, 3), Offset(12, 4.5),
      Offset(12, 19.5), Offset(12, 21),
      Offset(3, 12), Offset(4.5, 12),
      Offset(19.5, 12), Offset(21, 12),
      Offset(5.7, 5.7), Offset(7, 7),
      Offset(17, 17), Offset(18.3, 18.3),
      Offset(18.3, 5.7), Offset(17, 7),
      Offset(7, 17), Offset(5.7, 18.3),
    ];
    for (int i = 0; i < rays.length; i += 2) {
      c.drawLine(rays[i], rays[i + 1], p);
    }
  }

  // ── Batch 3 painters ──────────────────────────────────────

  void _drawAssignment(Canvas c, Paint p) {
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(4, 3, 20, 21), const Radius.circular(2)), p);
    // Clipboard top
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(9, 2, 15, 5), const Radius.circular(1)), p);
    c..drawLine(const Offset(7, 9), const Offset(17, 9), p)
      ..drawLine(const Offset(7, 13), const Offset(17, 13), p)
      ..drawLine(const Offset(7, 17), const Offset(13, 17), p);
  }

  void _drawCelebration(Canvas c, Paint p) {
    // Party popper cone
    c.drawPath(Path()..moveTo(4, 20)..lineTo(9, 11)..lineTo(13, 16)..close(), p);
    // Confetti
    c..drawLine(const Offset(12, 4), const Offset(13, 7), p)
      ..drawLine(const Offset(17, 5), const Offset(16, 8), p)
      ..drawLine(const Offset(19, 10), const Offset(17, 12), p);
    c..drawCircle(const Offset(15, 3.5), 0.9, p)
      ..drawCircle(const Offset(20, 7), 0.9, p);
  }

  void _drawFastForward(Canvas c, Paint p) {
    c.drawPath(Path()..moveTo(5, 6)..lineTo(12, 12)..lineTo(5, 18), p);
    c.drawPath(Path()..moveTo(13, 6)..lineTo(20, 12)..lineTo(13, 18), p);
  }

  void _drawGridView(Canvas c, Paint p) {
    c..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(4, 4, 11, 11), const Radius.circular(1.5)), p)
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(13, 4, 20, 11), const Radius.circular(1.5)), p)
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(4, 13, 11, 20), const Radius.circular(1.5)), p)
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(13, 13, 20, 20), const Radius.circular(1.5)), p);
  }

  void _drawOpenInNew(Canvas c, Paint p) {
    c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(4, 6, 18, 20), const Radius.circular(2)), p);
    c..drawLine(const Offset(14, 4), const Offset(20, 4), p)
      ..drawLine(const Offset(20, 4), const Offset(20, 10), p)
      ..drawLine(const Offset(20, 4), const Offset(11, 13), p);
  }

  void _drawTrendingDown(Canvas c, Paint p) {
    c.drawPath(Path()..moveTo(4, 7)..lineTo(9, 13)..lineTo(13, 10)..lineTo(20, 17), p);
    c..drawLine(const Offset(16, 17), const Offset(20, 17), p)
      ..drawLine(const Offset(20, 17), const Offset(20, 13), p);
  }

  void _drawUndo(Canvas c, Paint p) {
    c.drawPath(Path()
      ..moveTo(7, 8)..lineTo(4, 12)..lineTo(7, 16), p);
    c.drawPath(Path()
      ..moveTo(4, 12)..lineTo(14, 12)
      ..cubicTo(19, 12, 20, 15, 20, 17)
      ..cubicTo(20, 19, 18, 20, 16, 20), p);
  }

  @override
  bool shouldRepaint(_NousenIconPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}
