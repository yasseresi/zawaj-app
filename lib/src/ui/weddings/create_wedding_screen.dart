import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/ui/weddings/providers/create_wedding_provider.dart';
import 'package:zawaj_app/src/ui/weddings/widgets/wedding_form_fields.dart';

/// Create-wedding form: name (required, ≤120), optional event date (YYYY-MM-DD)
/// and description (≤2000). On success pops `true` so the home list reloads.
class CreateWeddingScreen extends StatelessWidget {
  const CreateWeddingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreateWeddingProvider>(
      create: (_) => CreateWeddingProvider(),
      child: const _CreateWeddingView(),
    );
  }
}

class _CreateWeddingView extends StatefulWidget {
  const _CreateWeddingView();

  @override
  State<_CreateWeddingView> createState() => _CreateWeddingViewState();
}

class _CreateWeddingViewState extends State<_CreateWeddingView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  DateTime? _date;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    final provider = context.read<CreateWeddingProvider>();
    final ok = await provider.submit(
      name: _name.text,
      eventDate: _date?.toIso8601DateOnly,
      description: _description.text,
    );
    if (!mounted) return;
    if (!ok) {
      final retry = await showAdaptiveConfirmDialog(
        context,
        title: 'weddings.create_error_title'.tr(),
        message: provider.errorMessage ?? 'weddings.create_error_message'.tr(),
        confirmLabel: 'actions.retry'.tr(),
      );
      if ((retry ?? false) && mounted) await _submit();
      return;
    }
    showToast(context, message: 'weddings.created_toast'.tr(), status: 'success');
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((CreateWeddingProvider p) => p.isLoading);

    return Scaffold(
      appBar: AppTopBar(title: 'weddings.create_title'.tr()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WeddingFormFields(
                  name: _name,
                  description: _description,
                  date: _date,
                  onDateChanged: (d) => setState(() => _date = d),
                  enabled: !isLoading,
                ),
                SizedBox(height: AppSpacing.xl.h),
                AppButton(
                  label: 'weddings.create'.tr(),
                  isLoading: isLoading,
                  isFullWidth: true,
                  onPressed: isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
