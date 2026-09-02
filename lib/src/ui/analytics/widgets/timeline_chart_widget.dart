import 'package:flutter/material.dart';

class TimelineChartWidget extends StatelessWidget {
  const TimelineChartWidget({
    super.key,
    this.data = const [12, 28, 45, 68, 92, 118, 142],
    this.labels = const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'],
    this.lineColor = const Color(0xFFE8A598),
    this.dotColor = const Color(0xFFD4AF37),
    this.bgColor = const Color(0xFF16213E),
  });

  final List<int> data;
  final List<String> labels;
  final Color lineColor;
  final Color dotColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 140);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _TimelinePainter(
              data: data,
              lineColor: lineColor,
              dotColor: dotColor,
              bgColor: bgColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            labels.length.clamp(0, data.length),
            (index) => Text(
              labels[index],
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.data,
    required this.lineColor,
    required this.dotColor,
    required this.bgColor,
  });

  final List<int> data;
  final Color lineColor;
  final Color dotColor;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxVal = (data.reduce((a, b) => a > b ? a : b) * 1.2).clamp(10.0, 1000.0);
    final w = size.width;
    final h = size.height;
    final stepX = w / (data.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = h - (data[i] / maxVal) * h;
      points.add(Offset(x, y.clamp(0.0, h)));
    }

    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final areaPath = Path.from(linePath);
    areaPath.lineTo(w, h);
    areaPath.lineTo(0, h);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.4),
          lineColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(areaPath, areaPaint);

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, strokePaint);

    for (final p in points) {
      final outerPaint = Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 4.5, outerPaint);

      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.bgColor != bgColor;
  }
}
