import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:zawaj_app/src/core/i18n/locale_keys.g.dart';
import '../../data/repositories/stats_repository.dart';
import '../../shared/widgets/widgets.dart';
import 'providers/analytics_provider.dart';
import 'widgets/broadcast_sheet.dart';
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
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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

            if (!provider.isEmpty && !provider.isLoading)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => provider.openBroadcastConfirm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8A598),
                      foregroundColor: const Color(0xFF2A1A1A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          size: 20,
                          color: Color(0xFF2A1A1A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          LocaleKeys.analytics_send_reminders.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (provider.broadcastState != BroadcastState.idle)
              BroadcastSheet(
                state: provider.broadcastState,
                pendingCount: provider.pendingCount,
                sentCount: provider.lastSentCount,
                onConfirm: provider.sendReminders,
                onCancel: provider.cancelBroadcast,
                onDismiss: provider.dismissBroadcastResult,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            LocaleKeys.analytics_title.tr(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'serif',
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Icon(
              Icons.filter_list,
              size: 20,
              color: Colors.white,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: LocaleKeys.analytics_total_guests.tr(),
                  value: '${provider.totalGuests}',
                  color: const Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: LocaleKeys.analytics_pending_responses.tr(),
                  value: '${provider.pendingCount}',
                  color: const Color(0xFFE8A598),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.analytics_rsvp_breakdown.tr(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'serif',
                      ),
                    ),
                    Text(
                      LocaleKeys.analytics_guests_count.tr(
                        namedArgs: {'count': '${provider.totalGuests}'},
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
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
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.analytics_rsvp_timeline.tr(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
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
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
