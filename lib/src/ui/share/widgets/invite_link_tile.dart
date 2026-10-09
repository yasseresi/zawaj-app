import '../../../data/models/invite_link_model.dart';
import '../../../imports/core_imports.dart';
import '../../../imports/packages_imports.dart';

/// An active invite link: the role it grants, when it was created, and a
/// revoke action.
class InviteLinkTile extends StatelessWidget {
  const InviteLinkTile({super.key, required this.link, required this.onRevoke});

  final InviteLink link;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final created = link.createdAt;
    return AppCard(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(Icons.link, color: cs.primary),
        title: Text(
            'share.link_grants'
                .tr(namedArgs: {'role': 'share.role_${link.role}'.tr()}),
            style: TextStyle(color: cs.onSurface)),
        subtitle: created == null
            ? null
            : Text('share.link_created_on'
                .tr(namedArgs: {'date': created.toLocal().toIso8601DateOnly})),
        trailing: IconButton(
          icon: Icon(Icons.link_off, color: cs.error),
          tooltip: 'share.revoke_link'.tr(),
          onPressed: onRevoke,
        ),
      ),
    );
  }
}
