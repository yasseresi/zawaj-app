import '../../../data/models/wedding_model.dart';
import '../../../imports/core_imports.dart';
import '../../../imports/packages_imports.dart';

/// Pick a collaborator role, each with what it allows. Used to change a
/// member's role and to approve a join request (where [roles] is limited to
/// what the invite link grants). Pops the chosen [WeddingRole], or null when
/// dismissed.
class RolePickerSheet extends StatelessWidget {
  const RolePickerSheet({
    super.key,
    required this.title,
    required this.selected,
    this.roles = const [WeddingRole.editor, WeddingRole.viewer],
  });

  final String title;
  final WeddingRole selected;
  final List<WeddingRole> roles;

  static const _descriptions = {
    WeddingRole.editor: 'share.role_editor_desc',
    WeddingRole.viewer: 'share.role_viewer_desc',
  };

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Material(
      color: cs.surface,
      borderRadius: AppBorders.bottomSheet,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
        child: ListTileTheme(
          textColor: cs.onSurface,
          // Plain rows rather than radios: a radio ignores taps on the option
          // that's already checked, but here every row is a choice to confirm
          // (e.g. approving at the requested role).
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                child: Text(
                  title,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              for (final role in roles)
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: role == selected,
                  child: ListTile(
                    key: ValueKey('role-${role.name}'),
                    selected: role == selected,
                    selectedColor: cs.primary,
                    // Decorative: the Semantics wrapper already announces
                    // the checked state.
                    leading: ExcludeSemantics(
                      child: Icon(role == selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                    ),
                    title: Text('share.role_${role.name}'.tr()),
                    subtitle: Text((_descriptions[role] ?? '').tr(),
                        style:
                            tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    onTap: () => Navigator.of(context).pop(role),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
