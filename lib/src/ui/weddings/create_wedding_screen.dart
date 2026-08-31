import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/ui/weddings/providers/create_wedding_provider.dart';

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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showAdaptiveDatePicker(
      context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
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
      showToast(context,
          message: provider.errorMessage ?? 'errors.server'.tr(), status: 'error');
      return;
    }
    showToast(context, message: 'weddings.created_toast'.tr(), status: 'success');
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((CreateWeddingProvider p) => p.isLoading);
    final cs = context.colors;

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
                AppTextField(
                  controller: _name,
                  enabled: !isLoading,
                  label: 'weddings.name_label'.tr(),
                  hint: 'weddings.name_hint'.tr(),
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.favorite_outline),
                  validator: (v) {
                    if (AppUtils.isBlank(v)) return 'weddings.name_required'.tr();
                    if (v!.trim().length > 120) return 'weddings.name_too_long'.tr();
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md.h),
                GestureDetector(
                  onTap: isLoading ? null : _pickDate,
                  child: AbsorbPointer(
                    child: AppTextField(
                      readOnly: true,
                      enabled: !isLoading,
                      label: 'weddings.date_label'.tr(),
                      hint: 'weddings.date_hint'.tr(),
                      prefixIcon: const Icon(Icons.event_outlined),
                      suffixIcon: _date == null
                          ? null
                          : IconButton(
                              icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
                              onPressed: isLoading ? null : () => setState(() => _date = null),
                            ),
                      // controller-less: drive the displayed text via initialValue key
                      key: ValueKey(_date?.toIso8601DateOnly ?? 'no-date'),
                      initialValue: _date?.toIso8601DateOnly ?? '',
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
                AppTextField(
                  controller: _description,
                  enabled: !isLoading,
                  label: 'weddings.description_label'.tr(),
                  hint: 'weddings.description_hint'.tr(),
                  maxLines: 4,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                  validator: (v) =>
                      (v != null && v.trim().length > 2000) ? 'weddings.description_too_long'.tr() : null,
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
