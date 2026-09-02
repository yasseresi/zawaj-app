import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:zawaj_app/src/core/i18n/locale_keys.g.dart';
import '../../../extensions/context_extension.dart';

class DonutChartWidget extends StatelessWidget {
  const DonutChartWidget({
    super.key,
    required this.confirmed,
    required this.declined,
    required this.pending,
    required this.total,
    this.primaryColor,
    this.declinedColor,
    this.pendingColor,
    this.trackColor,
  });

  final int confirmed;
  final int declined;
  final int pending;
  final int total;
  // Optional overrides; default to the app's semantic RSVP colors (theme-aware).
  final Color? primaryColor;
  final Color? declinedColor;
  final Color? pendingColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = context.appColors;
    final confirmedC = primaryColor ?? ac.success;
    final declinedC = declinedColor ?? cs.error;
    final pendingC = pendingColor ?? ac.warning;
    final trackC = trackColor ?? cs.surfaceContainerHighest;

    final double pctVal = total > 0 ? (confirmed / total) * 100 : 0;
    final String pctStr = '${pctVal.toStringAsFixed(0)}%';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(160, 160),
                painter: _DonutPainter(
                  confirmed: confirmed,
                  declined: declined,
                  pending: pending,
                  total: total,
                  primaryColor: confirmedC,
                  declinedColor: declinedC,
                  pendingColor: pendingC,
                  trackColor: trackC,
                  strokeWidth: 22,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pctStr,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocaleKeys.analytics_confirmation_rate.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _LegendItem(
              color: confirmedC,
              label: LocaleKeys.analytics_confirmed.tr(),
              value: '$confirmed',
            ),
            _LegendItem(
              color: declinedC,
              label: LocaleKeys.analytics_declined.tr(),
              value: '$declined',
            ),
            _LegendItem(
              color: pendingC,
              label: LocaleKeys.analytics_pending.tr(),
              value: '$pending',
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.confirmed,
    required this.declined,
    required this.pending,
    required this.total,
    required this.primaryColor,
    required this.declinedColor,
    required this.pendingColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final int confirmed;
  final int declined;
  final int pending;
  final int total;
  final Color primaryColor;
  final Color declinedColor;
  final Color pendingColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0) return;

    double startAngle = -math.pi / 2;

    final confirmedSweep = (confirmed / total) * 2 * math.pi;
    if (confirmedSweep > 0) {
      final p = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        confirmedSweep,
        false,
        p,
      );
      startAngle += confirmedSweep;
    }

    final declinedSweep = (declined / total) * 2 * math.pi;
    if (declinedSweep > 0) {
      final p = Paint()
        ..color = declinedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        declinedSweep,
        false,
        p,
      );
      startAngle += declinedSweep;
    }

    final pendingSweep = (pending / total) * 2 * math.pi;
    if (pendingSweep > 0) {
      final p = Paint()
        ..color = pendingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        pendingSweep,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.confirmed != confirmed ||
        oldDelegate.declined != declined ||
        oldDelegate.pending != pending ||
        oldDelegate.total != total ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.declinedColor != declinedColor ||
        oldDelegate.pendingColor != pendingColor ||
        oldDelegate.trackColor != trackColor;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
