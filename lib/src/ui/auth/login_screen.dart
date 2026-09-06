import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/ui/auth/providers/auth_provider.dart';
import 'package:zawaj_app/src/ui/auth/widgets/auth_header.dart';

/// Username + password login. No email, no social — matches the backend auth
/// model. On success the session flips and the router redirects to home.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      username: _username.text.trim(),
      password: _password.text,
    );
    if (!ok && mounted) {
      showToast(context,
          message: auth.errorMessage ?? 'errors.server'.tr(), status: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((AuthProvider p) => p.isLoading);
    final cs = context.colors;
    final tt = context.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: AppSpacing.xxl.h),
                  const AuthHeader(),
                  SizedBox(height: AppSpacing.xl.h),
                  Text('auth.login_title'.tr(),
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: AppSpacing.xs.h),
                  Text('auth.login_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  SizedBox(height: AppSpacing.xl.h),
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => AppUtils.isBlank(v)
                        ? 'auth.password_required'.tr()
                        : null,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.push(AppRoutes.recover),
                      child: Text('auth.forgot_password'.tr(),
                          style: tt.bodySmall?.copyWith(color: cs.primary)),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppButton(
                    label: 'auth.login_button'.tr(),
                    isLoading: isLoading,
                    isFullWidth: true,
                    onPressed: isLoading ? null : _submit,
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  TextButton(
                    onPressed:
                        isLoading ? null : () => context.push(AppRoutes.signup),
                    child: RichText(
                      text: TextSpan(
                        text: 'auth.no_account'.tr(),
                        style:
                            tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        children: [
                          TextSpan(
                            text: ' ${'auth.sign_up'.tr()}',
                            style: tt.bodyMedium?.copyWith(
                                color: cs.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
