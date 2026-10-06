import '../../../data/models/user_model.dart';
import '../../../imports/core_imports.dart';
import '../../../imports/packages_imports.dart';
import '../../../utils/phone.dart';

/// Bottom sheet to edit the display name and phone. Save stays disabled until
/// something changed and both fields are valid. [onSave] receives the trimmed
/// name and the raw phone input; returning true closes the sheet.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.user, required this.onSave});

  final AppUser user;
  final Future<bool> Function(String displayName, String phone) onSave;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  static const _nameMax = 80;

  late final _name = TextEditingController(text: widget.user.displayName);
  late final _phone = TextEditingController(
      text: widget.user.phone == null ? '' : formatPhone(widget.user.phone!));
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String get _nameValue => _name.text.trim();
  String? get _phoneValue => AppPhoneField.valueOf(_phone.text);

  bool get _isDirty =>
      _nameValue != widget.user.displayName ||
      _phoneValue != (widget.user.phone ?? '');

  bool get _isValid =>
      _nameValue.isNotEmpty &&
      _nameValue.length <= _nameMax &&
      _phoneValue != null;

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'auth.display_name_required'.tr();
    if (v.length > _nameMax) return 'settings.display_name_too_long'.tr();
    return null;
  }

  Future<void> _save() async {
    context.hideKeyboard();
    setState(() => _saving = true);
    final ok = await widget.onSave(_nameValue, _phone.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  Future<void> _onPopInvoked(bool didPop, Object? _) async {
    if (didPop || _saving) return;
    final navigator = Navigator.of(context);
    if (await confirmDiscardChanges(context)) navigator.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final canSave = _isDirty && _isValid && !_saving;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _onPopInvoked,
      child: Container(
        decoration:
            BoxDecoration(color: cs.surface, borderRadius: AppBorders.bottomSheet),
        padding: EdgeInsets.only(
          left: AppSpacing.lg.w,
          right: AppSpacing.lg.w,
          top: AppSpacing.md.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg.h,
        ),
        child: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: () => setState(() {}),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('settings.edit_profile'.tr(),
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: AppSpacing.lg.h),
              AppTextField(
                controller: _name,
                enabled: !_saving,
                label: 'auth.display_name'.tr(),
                prefixIcon: const Icon(Icons.person_outline_rounded),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: _validateName,
              ),
              SizedBox(height: AppSpacing.md.h),
              AppPhoneField(
                controller: _phone,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: AppSpacing.xs.h),
              Text('settings.phone_helper'.tr(),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              SizedBox(height: AppSpacing.lg.h),
              AppButton(
                label: 'actions.save'.tr(),
                isFullWidth: true,
                isLoading: _saving,
                onPressed: canSave ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
