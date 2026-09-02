import '../../../imports/core_imports.dart';
import '../../../imports/packages_imports.dart';
import '../providers/activity_log_provider.dart';

class ActivityItemTile extends StatelessWidget {
  const ActivityItemTile({
    super.key,
    required this.item,
    this.showDivider = true,
  });

  final ActivityItem item;
  final bool showDivider;

  (IconData, Color, Color) _visuals(BuildContext context) {
    final cs = context.colors;
    final ac = context.appColors;

    switch (item.type) {
      case ActivityItemType.confirmed:
        return (
          Icons.check_rounded,
          ac.success,
          ac.success.withValues(alpha: 0.12),
        );
      case ActivityItemType.added:
        return (
          Icons.add_rounded,
          cs.primary,
          cs.primary.withValues(alpha: 0.12),
        );
      case ActivityItemType.reminder:
        return (
          Icons.mail_outline_rounded,
          ac.warning,
          ac.warning.withValues(alpha: 0.12),
        );
      case ActivityItemType.declined:
        return (
          Icons.close_rounded,
          cs.error,
          cs.error.withValues(alpha: 0.12),
        );
      case ActivityItemType.collaboratorJoined:
        return (
          Icons.people_outline_rounded,
          cs.secondary,
          cs.secondary.withValues(alpha: 0.12),
        );
      case ActivityItemType.updated:
        return (
          Icons.edit_outlined,
          cs.primary,
          cs.primary.withValues(alpha: 0.12),
        );
      case ActivityItemType.exported:
        return (
          Icons.download_rounded,
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor, bgColor) = _visuals(context);
    final tt = context.textTheme;
    final cs = context.colors;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    size: 18.sp,
                    color: iconColor,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.formattedText(),
                      style: tt.bodyMedium?.copyWith(
                        fontSize: 13.5.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.formattedWhen(),
                      style: tt.labelSmall?.copyWith(
                        fontSize: 11.5.sp,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
