import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../../data/repositories/notification_repository.dart';
import 'providers/notifications_provider.dart';

/// The current user's notification feed (invites received, guest added, guest
/// status changed). Reachable from Settings → Notifications.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    this.repository,
    this.initialItems,
  });

  final NotificationRepository? repository;
  final List<AppNotification>? initialItems;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider(
        repository: repository,
        initialItems: initialItems,
      )..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppTopBar(
        title: 'notifications.title'.tr(),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  context.read<NotificationsProvider>().markAllRead(),
              child: Text('notifications.mark_all_read'.tr()),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationsProvider provider) {
    if (provider.status.isFailure) {
      return AppErrorWidget(
        title: 'notifications.error_title'.tr(),
        message: provider.errorMessage,
        onRetry: () => context.read<NotificationsProvider>().load(),
      );
    }

    if (provider.isLoading) {
      return _buildSkeletonLoading();
    }

    if (provider.isEmpty) {
      return AppEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'notifications.empty_title'.tr(),
        subtitle: 'notifications.empty_subtitle'.tr(),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: () => context.read<NotificationsProvider>().load(),
      child: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.md.w),
        itemCount: provider.items.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          final item = provider.items[index];
          return _NotificationTile(
            item: item,
            onTap: () => _handleTap(context, item),
          );
        },
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, AppNotification item) async {
    await context.read<NotificationsProvider>().markRead(item.id);
    if (!context.mounted) return;
    final weddingId = item.weddingId;
    if (weddingId != null && weddingId.isNotEmpty) {
      context.push('/weddings/$weddingId');
    }
  }

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.md.w),
        itemCount: 4,
        itemBuilder: (context, index) => AppCard(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16.h, width: 180.w, color: Colors.white),
              SizedBox(height: 8.h),
              Container(height: 12.h, width: 120.w, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final unread = !item.isRead;

    return AppCard(
      padding: EdgeInsets.all(14.r),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            margin: EdgeInsets.only(top: 6.h),
            decoration: BoxDecoration(
              color: unread ? cs.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (item.body.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    item.body,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 13.sp,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
