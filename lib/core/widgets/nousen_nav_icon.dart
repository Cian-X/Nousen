import 'package:flutter/material.dart';

/// Custom rounded line icons used by the Nousen bottom navigation.
///
/// The icon color and size remain controlled by the existing navigation state.
class NousenNavIcon extends StatelessWidget {
  const NousenNavIcon(
    this.icon, {
    super.key,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _NousenNavIconPainter(icon: icon, color: color),
        isComplex: true,
      ),
    );
  }
}

class _NousenNavIconPainter extends CustomPainter {
  const _NousenNavIconPainter({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / 24;
    canvas
      ..save()
      ..scale(scale)
      ..translate(0, 0);

    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (icon == Icons.home_rounded) {
      _drawHome(canvas, line);
    } else if (icon == Icons.calendar_today_rounded ||
        icon == Icons.calendar_month_rounded) {
      _drawCalendar(canvas, line, fill, showDates: icon == Icons.calendar_month_rounded);
    } else if (icon == Icons.insights_rounded) {
      _drawInsights(canvas, line);
    } else if (icon == Icons.person_rounded) {
      _drawPerson(canvas, line);
    }
    canvas.restore();
  }

  void _drawHome(Canvas canvas, Paint paint) {
    final Path roof = Path()
      ..moveTo(3.5, 10.5)
      ..lineTo(12, 4)
      ..lineTo(20.5, 10.5);
    canvas.drawPath(roof, paint);
    final Path body = Path()
      ..moveTo(5.5, 9.5)
      ..lineTo(5.5, 20)
      ..quadraticBezierTo(5.5, 20.5, 6, 20.5)
      ..lineTo(18, 20.5)
      ..quadraticBezierTo(18.5, 20.5, 18.5, 20)
      ..lineTo(18.5, 9.5);
    canvas.drawPath(body, paint);
    canvas.drawLine(const Offset(10, 20), const Offset(10, 15), paint);
    canvas.drawLine(const Offset(14, 20), const Offset(14, 15), paint);
  }

  void _drawCalendar(Canvas canvas, Paint paint, Paint fill, {required bool showDates}) {
    final RRect frame = RRect.fromRectAndRadius(
      const Rect.fromLTRB(4, 5.5, 20, 20.5),
      const Radius.circular(3),
    );
    canvas
      ..drawRRect(frame, paint)
      ..drawLine(const Offset(4.5, 10), const Offset(19.5, 10), paint)
      ..drawLine(const Offset(9, 3.5), const Offset(9, 7), paint)
      ..drawLine(const Offset(15, 3.5), const Offset(15, 7), paint);
    if (showDates) {
      for (final double y in const <double>[14, 17]) {
        for (final double x in const <double>[9, 12, 15]) {
          if (y == 17 && x == 15) continue;
          canvas.drawCircle(Offset(x, y), 0.85, fill);
        }
      }
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(8, 12.5, 16, 18),
          const Radius.circular(2),
        ),
        fill,
      );
    }
  }

  void _drawInsights(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(4, 20), const Offset(20, 20), paint);
    canvas.drawLine(const Offset(7, 19.5), const Offset(7, 14), paint);
    canvas.drawLine(const Offset(12, 19.5), const Offset(12, 10), paint);
    canvas.drawLine(const Offset(17, 19.5), const Offset(17, 6), paint);
    final Path trend = Path()
      ..moveTo(5, 11)
      ..lineTo(10, 8)
      ..lineTo(14, 10)
      ..lineTo(19, 4.5);
    canvas.drawPath(trend, paint);
    canvas
      ..drawLine(const Offset(16.5, 4.5), const Offset(19, 4.5), paint)
      ..drawLine(const Offset(19, 4.5), const Offset(19, 7), paint);
  }

  void _drawPerson(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(12, 8), 3.5, paint);
    final Path shoulders = Path()
      ..moveTo(5.5, 20)
      ..cubicTo(6.5, 16.7, 8.7, 15, 12, 15)
      ..cubicTo(15.3, 15, 17.5, 16.7, 18.5, 20);
    canvas.drawPath(shoulders, paint);
  }

  @override
  bool shouldRepaint(_NousenNavIconPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}
