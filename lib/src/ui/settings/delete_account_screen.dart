import '../../data/repositories/wedding_repository.dart';
import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../auth/providers/session_provider.dart';
import 'providers/delete_account_provider.dart';

/// Two-step account deletion. Step 1 shows the impact — owned weddings (and
/// who else loses them) with a shortcut to transfer ownership first, plus
/// shared weddings the user leaves. Step 2 re-checks the password. On success
/// the session ends and the router guard returns to login.
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key, this.weddingRepository, this.session});

  final WeddingRepository? weddingRepository;
  final SessionProvider? session;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DeleteAccountProvider>(
      create: (_) => DeleteAccountProvider(
          weddingRepository: weddingRepository, session: session)
        ..load(),
      child: const _DeleteAccountView(),
    );
  }
}

class _DeleteAccountView extends StatefulWidget {
  const _DeleteAccountView();

  @override
  State<_DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<_DeleteAccountView> {
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _confirmStep = false;
  bool _obscure = true;
  String? _passwordError;

  @override
  void dispose() {
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _transfer(OwnedWedding owned) async {
    final provider = context.read<DeleteAccountProvider>();
    await context.push('/weddings/${owned.wedding.id}/share',
        extra: owned.wedding);
    await provider.load();
  }

  Future<void> _submit() async {
    context.hideKeyboard();
    final provider = context.read<DeleteAccountProvider>();
    final outcome = await provider.submit(_password.text);
    if (!mounted) return;
    switch (outcome) {
      case DeleteOutcome.deleted:
        showGlobalToast(message: 'settings.account_deleted'.tr());
      case DeleteOutcome.wrongPassword:
        setState(() => _passwordError = 'settings.delete_wrong_password'.tr());
        _passwordFocus.requestFocus();
      case DeleteOutcome.locked:
        setState(() => _passwordError = 'errors.locked'.tr());
      case DeleteOutcome.failed:
        showToast(context,
            message: provider.errorMessage ?? 'errors.unknown'.tr(),
            status: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'settings.delete_account'.tr()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _confirmStep ? _confirm(context) : _impact(context),
          ),
        ),
      ),
    );
  }

  Widget _impact(BuildContext context) {
    final provider = context.watch<DeleteAccountProvider>();
    final cs = context.colors;
    final tt = context.textTheme;

    return Column(
      key: const ValueKey('impact'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.warning_amber_rounded, size: 56.r, color: cs.error),
        SizedBox(height: AppSpacing.md.h),
        Text('settings.delete_title'.tr(),
            textAlign: TextAlign.center,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: AppSpacing.sm.h),
        Text('settings.delete_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        SizedBox(height: AppSpacing.lg.h),
        if (provider.status.isLoading || provider.status.isInitial)
          const AppLoading()
        else if (provider.status.isFailure)
          AppErrorWidget(
            title: 'weddings.error_title'.tr(),
            message: provider.errorMessage,
            onRetry: provider.load,
          )
        else ...[
          if (provider.owned.isNotEmpty) ...[
            Text('settings.delete_owned_title'.tr(),
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: AppSpacing.xs.h),
            Text('settings.delete_owned_warning'.tr(),
                style: tt.bodySmall?.copyWith(color: cs.error)),
            SizedBox(height: AppSpacing.sm.h),
            for (final owned in provider.owned) _ownedTile(context, owned),
          ],
          if (provider.sharedCount > 0) ...[
            SizedBox(height: AppSpacing.md.h),
            Text('settings.delete_shared'.plural(provider.sharedCount),
                style: tt.bodyMedium),
          ],
          if (provider.owned.isEmpty && provider.sharedCount == 0)
            Text('settings.delete_no_weddings'.tr(),
                textAlign: TextAlign.center, style: tt.bodyMedium),
          SizedBox(height: AppSpacing.xl.h),
          AppButton(
            label: 'settings.delete_continue'.tr(),
            variant: ButtonVariant.danger,
            isFullWidth: true,
            onPressed: () => setState(() => _confirmStep = true),
          ),
        ],
      ],
    );
  }

  Widget _ownedTile(BuildContext context, OwnedWedding owned) {
    final tt = context.textTheme;
    final cs = context.colors;
    final w = owned.wedding;
    return AppCard(
      margin: EdgeInsets.only(bottom: AppSpacing.sm.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(w.name,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 2.h),
          Text(
            '${'weddings.guests_count'.plural(w.guestCount)} · '
            '${'settings.delete_collaborators'.plural(owned.collaborators)}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (owned.collaborators > 0)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => _transfer(owned),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text('settings.delete_transfer'.tr()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _confirm(BuildContext context) {
    final provider = context.watch<DeleteAccountProvider>();
    final cs = context.colors;
    final tt = context.textTheme;
    return Column(
      key: const ValueKey('confirm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_outline_rounded, size: 56.r, color: cs.error),
        SizedBox(height: AppSpacing.md.h),
        Text('settings.delete_confirm_title'.tr(),
            textAlign: TextAlign.center,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: AppSpacing.sm.h),
        Text('settings.delete_confirm_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        SizedBox(height: AppSpacing.lg.h),
        TextField(
          controller: _password,
          focusNode: _passwordFocus,
          obscureText: _obscure,
          enabled: !provider.isSubmitting,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _passwordError = null),
          onSubmitted: (_) => _password.text.isEmpty ? null : _submit(),
          decoration: InputDecoration(
            isDense: true,
            labelText: 'auth.current_password'.tr(),
            prefixIcon: const Icon(Icons.lock_outline),
            errorText: _passwordError,
            suffixIcon: IconButton(
              tooltip: 'settings.toggle_password'.tr(),
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xl.h),
        AppButton(
          label: 'settings.delete_permanently'.tr(),
          variant: ButtonVariant.danger,
          isFullWidth: true,
          isLoading: provider.isSubmitting,
          onPressed: (_password.text.isEmpty || provider.isSubmitting)
              ? null
              : _submit,
        ),
        SizedBox(height: AppSpacing.sm.h),
        TextButton(
          onPressed: provider.isSubmitting
              ? null
              : () => setState(() => _confirmStep = false),
          child: Text('settings.delete_back'.tr()),
        ),
      ],
    );
  }
}
