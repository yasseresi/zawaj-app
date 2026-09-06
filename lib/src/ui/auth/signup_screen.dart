import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/ui/auth/providers/auth_provider.dart';
import 'package:zawaj_app/src/ui/auth/widgets/auth_header.dart';
import 'package:zawaj_app/src/ui/auth/widgets/recovery_code_dialog.dart';

/// Register: username (≥3, no spaces) + display name + password (≥8). On success
/// the one-time recovery code is revealed via a mandatory dialog BEFORE the
/// session is promoted (the router then redirects home).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      username: _username.text.trim(),
      displayName: _displayName.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    if (!ok) {
      showToast(context,
          message: auth.errorMessage ?? 'errors.server'.tr(), status: 'error');
      return;
    }
    // Reveal the one-time recovery code, then promote the session.
    await showAppDialog<bool>(
      dismissible: false,
      child: RecoveryCodeDialog(code: auth.pendingRecoveryCode ?? ''),
    );
    auth.confirmPending();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((AuthProvider p) => p.isLoading);
    final cs = context.colors;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const AuthHeader(),
                  SizedBox(height: AppSpacing.lg.h),
                  Text('auth.signup_title'.tr(),
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: AppSpacing.xs.h),
                  Text('auth.signup_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  SizedBox(height: AppSpacing.xl.h),
                  AppTextField(
                    controller: _displayName,
                    enabled: !isLoading,
                    label: 'auth.display_name'.tr(),
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    validator: (v) => AppUtils.isBlank(v)
                        ? 'auth.display_name_required'.tr()
                        : null,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppTextField(
                    controller: _username,
                    enabled: !isLoading,
                    label: 'auth.username'.tr(),
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (v) => AppInputValidation.usernameError(v)?.tr(),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppTextField(
                    controller: _password,
                    enabled: !isLoading,
                    label: 'auth.password'.tr(),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => AppInputValidation.passwordError(v)?.tr(),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppTextField(
                    controller: _confirm,
                    enabled: !isLoading,
                    label: 'auth.confirm_password'.tr(),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (v) {
                      if (AppUtils.isBlank(v)) {
                        return 'auth.confirm_password_required'.tr();
                      }
                      if (v != _password.text) {
                        return 'auth.passwords_do_not_match'.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  AppButton(
                    label: 'auth.signup_button'.tr(),
                    isLoading: isLoading,
                    isFullWidth: true,
                    onPressed: isLoading ? null : _submit,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  TextButton(
                    onPressed: isLoading ? null : () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        text: 'auth.have_account'.tr(),
                        style:
                            tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        children: [
                          TextSpan(
                            text: ' ${'auth.sign_in'.tr()}',
                            style: tt.bodyMedium?.copyWith(
                                color: cs.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
