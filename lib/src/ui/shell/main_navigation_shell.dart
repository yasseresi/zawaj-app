import 'dart:ui';

import 'package:zawaj_app/src/core/i18n/locale_keys.g.dart';

import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../activity/activity_log_screen.dart';
import '../analytics/analytics_screen.dart';
import '../weddings/providers/weddings_provider.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WeddingsProvider>(
      create: (_) => WeddingsProvider()..load(),
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: _ZawajBottomNav(
          currentIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

class DashboardTabPage extends StatelessWidget {
  const DashboardTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeddingsProvider>();
    return _buildWeddingScopedTab(
      context: context,
      provider: provider,
      icon: Icons.insights_rounded,
      titleKey: LocaleKeys.nav_analytics,
      builder: (weddingId) => AnalyticsScreen(
        key: ValueKey(weddingId),
        weddingId: weddingId,
      ),
    );
  }
}

class ActivityTabPage extends StatelessWidget {
  const ActivityTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeddingsProvider>();
    return _buildWeddingScopedTab(
      context: context,
      provider: provider,
      icon: Icons.history_rounded,
      titleKey: LocaleKeys.nav_activity,
      builder: (weddingId) => ActivityLogScreen(
        key: ValueKey(weddingId),
        weddingId: weddingId,
      ),
    );
  }
}

Widget _buildWeddingScopedTab({
  required BuildContext context,
  required WeddingsProvider provider,
  required IconData icon,
  required String titleKey,
  required Widget Function(String weddingId) builder,
}) {
  switch (provider.status) {
    case AppStatus.initial:
    case AppStatus.loading:
      return Scaffold(body: AppLoading(message: 'weddings.loading'.tr()));
    case AppStatus.failure:
      return Scaffold(
        body: AppErrorWidget(
          title: 'weddings.error_title'.tr(),
          message: provider.errorMessage,
          onRetry: () => context.read<WeddingsProvider>().load(),
        ),
      );
    case AppStatus.success:
      if (provider.weddings.isEmpty) {
        return _NoWeddingYet(icon: icon, titleKey: titleKey);
      }
      return builder(provider.weddings.first.id);
  }
}

class _NoWeddingYet extends StatelessWidget {
  const _NoWeddingYet({required this.icon, required this.titleKey});

  final IconData icon;
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: titleKey.tr()),
      body: SafeArea(
        child: AppEmptyState(
          icon: icon,
          title: LocaleKeys.nav_no_wedding_title.tr(),
          subtitle: LocaleKeys.nav_no_wedding_subtitle.tr(),
        ),
      ),
    );
  }
}

enum _ZawajDest {
  lists(LocaleKeys.nav_lists, Icons.list_alt_rounded),
  analytics(LocaleKeys.nav_analytics, Icons.insights_rounded),
  activity(LocaleKeys.nav_activity, Icons.history_rounded),
  settings(LocaleKeys.nav_settings, Icons.settings_outlined);

  const _ZawajDest(this.labelKey, this.icon);

  final String labelKey;
  final IconData icon;
}

class _ZawajBottomNav extends StatelessWidget {
  const _ZawajBottomNav({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isDark = context.isDarkMode;
    final activeColor = isDark ? cs.secondary : cs.primary;
    final inactiveColor = cs.onSurfaceVariant.withValues(alpha: 0.6);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xF216213E)
                : cs.surface.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64.h,
              child: Row(
                children: List.generate(_ZawajDest.values.length, (index) {
                  final dest = _ZawajDest.values[index];
                  final selected = index == currentIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onDestinationSelected(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            dest.icon,
                            size: 24.r,
                            color: selected ? activeColor : inactiveColor,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            dest.labelKey.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                              color: selected ? activeColor : inactiveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
