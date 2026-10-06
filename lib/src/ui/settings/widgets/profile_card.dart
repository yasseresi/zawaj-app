import '../../../data/models/user_model.dart';
import '../../../imports/core_imports.dart';
import '../../../imports/packages_imports.dart';
import '../../../utils/phone.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.user,
  });

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isDark = context.isDarkMode;

    final displayName = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName
        : 'سارة المنصور';
    final email = (user?.email?.isNotEmpty ?? false)
        ? user!.email!
        : (user?.username.isNotEmpty ?? false)
            ? '@${user!.username}'
            : 'sarah@example.com';
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim().substring(0, 1)
        : 'س';
    final isPremium = user?.isPremium ?? true;

    final gradientColors = isDark
        ? [
            cs.surfaceContainerHigh,
            cs.surfaceContainerHighest,
          ]
        : [
            const Color(0xFFFDF6F0),
            const Color(0xFFF7E8E4),
          ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: AppBorders.card,
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 64.w,
            height: 64.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.7),
                  cs.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25),
                  blurRadius: 14.r,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimary,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  email,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 13.sp,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (user?.phone != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    formatPhone(user!.phone!),
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 13.sp,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                if (isPremium) ...[
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14.r,
                        color: cs.secondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'settings.premium_member'.tr(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: cs.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
