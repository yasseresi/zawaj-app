import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../auth/providers/session_provider.dart';
import 'providers/settings_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    final settings = context.read<SettingsProvider>();
    final ok = await settings.changePassword(
      oldPassword: _currentPassword.text,
      newPassword: _newPassword.text,
    );
    if (!mounted) return;
    if (!ok) {
      showToast(context,
          message: settings.passwordErrorMessage ?? 'errors.server'.tr(),
          status: 'error');
      return;
    }
    await context.read<SessionProvider>().signOut();
  }

  String? _validateCurrentPassword(String? value) {
    if (AppUtils.isBlank(value)) return 'auth.password_required'.tr();
    return null;
  }

  String? _validateNewPassword(String? value) {
    return AppInputValidation.passwordError(value)?.tr();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select((SettingsProvider p) => p.isChangingPassword);
    final cs = context.colors;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppTopBar(title: 'settings.change_password'.tr()),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.lock_reset_rounded, size: 64.r, color: cs.primary),
                  SizedBox(height: AppSpacing.md.h),
                  Text('settings.change_password_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  SizedBox(height: AppSpacing.xl.h),
                  AppTextField(
                    controller: _currentPassword,
                    enabled: !isLoading,
                    label: 'auth.current_password'.tr(),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: _visibilityButton(),
                    validator: _validateCurrentPassword,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppTextField(
                    controller: _newPassword,
                    enabled: !isLoading,
                    label: 'auth.new_password'.tr(),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: _validateNewPassword,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppTextField(
                    controller: _confirmPassword,
                    enabled: !isLoading,
                    label: 'auth.confirm_password'.tr(),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (value) {
                      if (AppUtils.isBlank(value)) {
                        return 'auth.confirm_password_required'.tr();
                      }
                      if (value != _newPassword.text) {
                        return 'auth.passwords_do_not_match'.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  AppButton(
                    label: 'settings.change_password_button'.tr(),
                    isLoading: isLoading,
                    isFullWidth: true,
                    onPressed: isLoading ? null : _submit,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  Text('settings.change_password_reauth'.tr(),
                      textAlign: TextAlign.center,
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _visibilityButton() => IconButton(
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
}
