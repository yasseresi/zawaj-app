import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../../data/repositories/guest_repository.dart';
import 'providers/activity_log_provider.dart';
import 'widgets/activity_item_tile.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({
    super.key,
    required this.weddingId,
    this.repository,
    this.initialGroups,
  });

  final String weddingId;
  final GuestRepository? repository;
  final List<ActivityGroup>? initialGroups;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActivityLogProvider>(
      create: (_) => ActivityLogProvider(
        weddingId: weddingId,
        repository: repository,
        initialGroups: initialGroups,
      )..load(),
      child: const _ActivityLogView(),
    );
  }
}

class _ActivityLogView extends StatelessWidget {
  const _ActivityLogView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityLogProvider>();

    return Scaffold(
      appBar: AppTopBar(
        title: 'activity.title'.tr(),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              size: 20.sp,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ActivityLogProvider provider) {
    if (provider.status.isFailure) {
      return AppErrorWidget(
        title: 'activity.error_title'.tr(),
        message: provider.errorMessage,
        onRetry: () => context.read<ActivityLogProvider>().load(),
      );
    }

    if (provider.isLoading) {
      return _buildSkeletonLoading();
    }

    if (provider.isEmpty) {
      return AppEmptyState(
        icon: Icons.history_rounded,
        title: 'activity.empty_title'.tr(),
        subtitle: 'activity.empty_subtitle'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ActivityLogProvider>().load(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.sm.h,
        ),
        itemCount: provider.groups.length,
        itemBuilder: (context, index) {
          final group = provider.groups[index];
          return _DayGroupWidget(group: group);
        },
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.sm.h,
        ),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 6.h,
                  ),
                  child: Container(
                    width: 80.w,
                    height: 12.h,
                    color: Colors.white,
                  ),
                ),
                AppCard(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: Column(
                    children: List.generate(
                      2,
                      (i) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Row(
                          children: [
                            Container(
                              width: 36.r,
                              height: 36.r,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 14.h,
                                    width: double.infinity,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 6.h),
                                  Container(
                                    height: 10.h,
                                    width: 60.w,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayGroupWidget extends StatelessWidget {
  const _DayGroupWidget({required this.group});

  final ActivityGroup group;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 4.w,
              right: 4.w,
              bottom: 10.h,
              top: 4.h,
            ),
            child: Text(
              group.titleKey.tr(),
              style: tt.labelSmall?.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++)
                  ActivityItemTile(
                    item: group.items[i],
                    showDivider: i < group.items.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
