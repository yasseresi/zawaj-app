import '../../../data/models/join_request_model.dart';
import '../../../imports/core_imports.dart';
import '../../../imports/packages_imports.dart';
import '../../../utils/relative_time.dart';

/// A pending request to join through an invite link: who asks, for which role,
/// and the owner's Approve / Decline actions (disabled while [deciding]).
class JoinRequestTile extends StatelessWidget {
  const JoinRequestTile({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onDecline,
    this.deciding = false,
  });

  final JoinRequest request;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final bool deciding;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final createdAt = request.createdAt;
    final age = createdAt == null ? null : relativeTime(createdAt.toLocal());
    return AppCard(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: cs.secondaryContainer,
              foregroundColor: cs.onSecondaryContainer,
              child: Text(request.avatarInitial),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.label,
                      style: tt.titleMedium?.copyWith(
                          color: cs.onSurface, fontWeight: FontWeight.w700)),
                  Text(
                    'share.join_request_subtitle'.tr(namedArgs: {
                      // First-strong isolate keeps the Latin "@name" intact
                      // inside right-to-left text.
                      'username': '\u2068${request.username}\u2069',
                      'role': 'share.role_${request.role.name}'.tr(),
                    }),
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (age != null)
                    Text(age.key.tr(namedArgs: age.args),
                        style:
                            tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
          SizedBox(height: 10.h),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: deciding ? null : onDecline,
                style: OutlinedButton.styleFrom(foregroundColor: cs.error),
                child: Text('share.decline'.tr()),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: FilledButton(
                onPressed: deciding ? null : onApprove,
                child: Text('share.approve'.tr()),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
