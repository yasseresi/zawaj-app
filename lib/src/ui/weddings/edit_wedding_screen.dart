import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/ui/weddings/providers/edit_wedding_provider.dart';
import 'package:zawaj_app/src/ui/weddings/widgets/wedding_form_fields.dart';

/// Owner-only edit of a wedding's name, date and description. Prefilled;
/// Save is enabled only when something changed and the form is valid; leaving
/// with unsaved edits asks first. Pops the server's (bare) wedding on success —
/// merge it with `Wedding.withEdits`.
class EditWeddingScreen extends StatelessWidget {
  const EditWeddingScreen({super.key, required this.wedding, this.repository});

  final Wedding wedding;
  final WeddingRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditWeddingProvider>(
      create: (_) =>
          EditWeddingProvider(wedding: wedding, repository: repository),
      child: const _EditWeddingView(),
    );
  }
}

class _EditWeddingView extends StatefulWidget {
  const _EditWeddingView();

  @override
  State<_EditWeddingView> createState() => _EditWeddingViewState();
}

class _EditWeddingViewState extends State<_EditWeddingView> {
  final _formKey = GlobalKey<FormState>();
  late final Wedding _original = context.read<EditWeddingProvider>().original;
  late final _name = TextEditingController(text: _original.name);
  late final _description = TextEditingController(text: _original.description);
  late DateTime? _date = _original.eventDate;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _isDirty => context
      .read<EditWeddingProvider>()
      .isDirty(name: _name.text, date: _date, description: _description.text);

  bool get _isValid =>
      WeddingFormFields.validateName(_name.text) == null &&
      WeddingFormFields.validateDescription(_description.text) == null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    final provider = context.read<EditWeddingProvider>();
    final saved = await provider.save(
        name: _name.text, date: _date, description: _description.text);
    if (!mounted) return;
    if (saved == null) {
      showToast(context,
          message: provider.errorMessage ?? 'errors.unknown'.tr(),
          status: 'error');
      return;
    }
    showToast(context,
        message: 'weddings.updated_toast'.tr(), status: 'success');
    context.pop(saved);
  }

  Future<void> _onPopInvoked(bool didPop, Object? _) async {
    if (didPop) return;
    if (await confirmDiscardChanges(context) && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select((EditWeddingProvider p) => p.isSaving);
    final dirty = _isDirty;

    return PopScope(
      canPop: !dirty || isSaving,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppTopBar(title: 'weddings.edit_title'.tr()),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: () => setState(() {}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WeddingFormFields(
                    name: _name,
                    description: _description,
                    date: _date,
                    onDateChanged: (d) => setState(() => _date = d),
                    enabled: !isSaving,
                    // A saved date can be changed but not cleared (API limit).
                    canClearDate: _original.eventDate == null,
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  AppButton(
                    label: 'actions.save'.tr(),
                    isLoading: isSaving,
                    isFullWidth: true,
                    onPressed: (dirty && _isValid && !isSaving) ? _save : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
