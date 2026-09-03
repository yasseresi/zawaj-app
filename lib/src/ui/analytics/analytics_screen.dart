import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:zawaj_app/src/core/i18n/locale_keys.g.dart';
import '../../data/repositories/stats_repository.dart';
import '../../extensions/context_extension.dart';
import '../../shared/widgets/widgets.dart';
import 'providers/analytics_provider.dart';
import 'widgets/donut_chart_widget.dart';
import 'widgets/timeline_chart_widget.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({
    super.key,
    required this.weddingId,
    this.repository,
  });

  final String weddingId;
  final StatsRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AnalyticsProvider>(
      create: (_) => AnalyticsProvider(
        weddingId: weddingId,
        repository: repository,
      )..load(),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: provider.isLoading
                  ? _buildLoadingState()
                  : provider.isEmpty
                      ? AppEmptyState(
                          icon: Icons.bar_chart_rounded,
                          title: LocaleKeys.analytics_empty_title.tr(),
                          subtitle: LocaleKeys.analytics_empty_subtitle.tr(),
                        )
                      : _buildBody(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Only when pushed on top of the shell (e.g. a per-wedding view); the
    // Dashboard tab root can't pop, so it shows no back control.
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (canPop)
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: cs.onSurface,
                ),
              ),
            )
          else
            const SizedBox(width: 40, height: 40),
          Text(
            LocaleKeys.analytics_title.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              fontFamily: 'serif',
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(
              Icons.filter_list,
              size: 20,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCardLoading()),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCardLoading()),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardLoading() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AnalyticsProvider provider) {
    final cs = Theme.of(context).colorScheme;
    final ac = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: LocaleKeys.analytics_total_guests.tr(),
                  value: '${provider.totalGuests}',
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: LocaleKeys.analytics_pending_responses.tr(),
                  value: '${provider.pendingCount}',
                  color: ac.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.analytics_rsvp_breakdown.tr(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                        fontFamily: 'serif',
                      ),
                    ),
                    Text(
                      LocaleKeys.analytics_guests_count.tr(
                        namedArgs: {'count': '${provider.totalGuests}'},
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                DonutChartWidget(
                  confirmed: provider.confirmedCount,
                  declined: provider.declinedCount,
                  pending: provider.pendingCount,
                  total: provider.totalGuests,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.analytics_rsvp_timeline.tr(),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 16),
                TimelineChartWidget(
                  data: provider.timelineData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'serif',
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
