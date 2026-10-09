import '../../../data/models/wedding_member_model.dart';
import '../../../imports/core_imports.dart';
import '../../../imports/packages_imports.dart';

enum _MemberAction { changeRole, makeOwner, remove }

/// A collaborator row with a role badge. Each non-null callback adds an item
/// to the overflow menu; with none the row is read-only (non-owner viewers,
/// and the owner's own row).
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    this.onChangeRole,
    this.onMakeOwner,
    this.onRemove,
  });

  final WeddingMember member;
  final VoidCallback? onChangeRole;
  final VoidCallback? onMakeOwner;
  final VoidCallback? onRemove;

  bool get hasActions =>
      onChangeRole != null || onMakeOwner != null || onRemove != null;

  PopupMenuItem<_MemberAction> _item(
          _MemberAction value, IconData icon, String label, Color onSurface,
          {Color? color}) =>
      PopupMenuItem(
        value: value,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color ?? onSurface)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isOwner = member.role.isOwner;
    final titleColor = isOwner ? cs.onPrimaryContainer : cs.onSurface;
    final subtitleColor = isOwner
        ? cs.onPrimaryContainer.withValues(alpha: 0.78)
        : cs.onSurfaceVariant;

    return AppCard(
      margin: EdgeInsets.only(bottom: 8.h),
      color: isOwner ? cs.primaryContainer : null,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: CircleAvatar(
          radius: 20.r,
          backgroundColor: isOwner ? cs.primary : cs.primaryContainer,
          foregroundColor: isOwner ? cs.onPrimary : cs.onPrimaryContainer,
          child: Text(member.avatarInitial),
        ),
        title: Text(
          member.label,
          style: context.textTheme.titleMedium?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '@${member.username}',
          style: context.textTheme.bodyMedium?.copyWith(color: subtitleColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isOwner
                    ? cs.primary.withValues(alpha: 0.14)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'share.role_${member.role.name}'.tr(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: isOwner ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hasActions)
              PopupMenuButton<_MemberAction>(
                tooltip: 'share.member_actions'.tr(),
                onSelected: (action) => switch (action) {
                  _MemberAction.changeRole => onChangeRole!(),
                  _MemberAction.makeOwner => onMakeOwner!(),
                  _MemberAction.remove => onRemove!(),
                },
                itemBuilder: (context) => [
                  if (onChangeRole != null)
                    _item(
                        _MemberAction.changeRole,
                        Icons.manage_accounts_outlined,
                        'share.change_role'.tr(),
                        cs.onSurface),
                  if (onMakeOwner != null)
                    _item(
                        _MemberAction.makeOwner,
                        Icons.workspace_premium_outlined,
                        'share.make_owner'.tr(),
                        cs.onSurface),
                  if (onRemove != null)
                    _item(_MemberAction.remove, Icons.person_remove_outlined,
                        'share.remove_confirm'.tr(), cs.onSurface,
                        color: cs.error),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
