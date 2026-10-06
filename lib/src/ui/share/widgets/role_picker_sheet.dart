import '../../../data/models/wedding_member_model.dart';
import '../../../data/models/wedding_model.dart';
import '../../../imports/core_imports.dart';
import '../../../imports/packages_imports.dart';

/// Pick a collaborator role (editor / viewer), each with what it allows.
/// Pops the chosen [WeddingRole], or null when dismissed.
class RolePickerSheet extends StatelessWidget {
  const RolePickerSheet({super.key, required this.member});

  final WeddingMember member;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final options = [
      (WeddingRole.editor, 'share.role_editor_desc'.tr()),
      (WeddingRole.viewer, 'share.role_viewer_desc'.tr()),
    ];

    return Material(
      color: cs.surface,
      borderRadius: AppBorders.bottomSheet,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
        child: RadioGroup<WeddingRole>(
          groupValue: member.role,
          onChanged: (role) => Navigator.of(context).pop(role),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                child: Text(
                  'share.change_role_title'.tr(namedArgs: {'name': member.label}),
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              for (final (role, description) in options)
                RadioListTile<WeddingRole>(
                  value: role,
                  title: Text('share.role_${role.name}'.tr()),
                  subtitle: Text(description,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
