import '../../../imports/core_imports.dart';
import '../../../imports/packages_imports.dart';
import '../providers/pending_invites_provider.dart';

class InviteCard extends StatelessWidget {
  const InviteCard({
    super.key,
    required this.invite,
    this.isAcceptLoading = false,
    this.onAccept,
    this.onDecline,
  });

  final PendingInvite invite;
  final bool isAcceptLoading;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return AppCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      cs.secondaryContainer,
                      cs.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    invite.avatarInitial,
                    style: tt.titleMedium?.copyWith(
                      color: cs.onSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.event,
                      style: tt.titleMedium?.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'invites.from_sender'.tr(namedArgs: {'sender': invite.sender}),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12.5.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'invites.sent_date'.tr(namedArgs: {'date': invite.date}),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 11.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'invites.decline'.tr(),
                  variant: ButtonVariant.outline,
                  onPressed: isAcceptLoading ? null : onDecline,
                  height: ButtonSize.medium,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 1,
                child: AppButton(
                  label: 'invites.accept'.tr(),
                  variant: ButtonVariant.primary,
                  isLoading: isAcceptLoading,
                  onPressed: isAcceptLoading ? null : onAccept,
                  height: ButtonSize.medium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
