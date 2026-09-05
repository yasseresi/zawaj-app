import 'package:flutter/material.dart';

import 'package:zawaj_app/src/core/i18n/locale_keys.g.dart';
import '../../../extensions/context_extension.dart';
import 'package:easy_localization/easy_localization.dart';

/// Shows the live size of the list and the expected attendance volume.
class GuestCapacityChartWidget extends StatelessWidget {
  const GuestCapacityChartWidget({
    super.key,
    required this.totalGuests,
    required this.totalPeople,
    required this.confirmedSeats,
  });

  final int totalGuests;
  final int totalPeople;
  final int confirmedSeats;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final maxValue = [totalGuests, totalPeople, confirmedSeats]
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 1000000)
        .toInt();

    return Column(
      children: [
        _MetricBar(
          label: LocaleKeys.analytics_registered_guests.tr(),
          value: totalGuests,
          maxValue: maxValue,
          color: cs.primary,
        ),
        const SizedBox(height: 14),
        _MetricBar(
          label: LocaleKeys.analytics_people_expected.tr(),
          value: totalPeople,
          maxValue: maxValue,
          color: cs.secondary,
        ),
        const SizedBox(height: 14),
        _MetricBar(
          label: LocaleKeys.analytics_confirmed_seats.tr(),
          value: confirmedSeats,
          maxValue: maxValue,
          color: context.appColors.success,
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: context.textTheme.bodyMedium),
            Text('$value',
                style: context.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value / maxValue,
            minHeight: 10,
            color: color,
            backgroundColor: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}
