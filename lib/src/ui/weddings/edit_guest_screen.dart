import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/ui/weddings/providers/edit_guest_provider.dart';
import 'package:zawaj_app/src/ui/weddings/widgets/guest_form_fields.dart';
import 'package:zawaj_app/src/utils/phone.dart';

/// Full edit of a guest (editor+): every field, prefilled. Save is enabled only
/// when something changed and the form is valid; leaving with unsaved edits
/// asks first. Pops the updated [Guest] on success.
class EditGuestScreen extends StatelessWidget {
  const EditGuestScreen({
    super.key,
    required this.weddingId,
    required this.guest,
    this.repository,
  });

  final String weddingId;
  final Guest guest;
  final GuestRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditGuestProvider>(
      create: (_) => EditGuestProvider(
          weddingId: weddingId, guest: guest, repository: repository),
      child: const _EditGuestView(),
    );
  }
}

class _EditGuestView extends StatefulWidget {
  const _EditGuestView();

  @override
  State<_EditGuestView> createState() => _EditGuestViewState();
}

class _EditGuestViewState extends State<_EditGuestView> {
  final _formKey = GlobalKey<FormState>();
  late final EditGuestProvider _provider = context.read<EditGuestProvider>();
  late final Guest _g = _provider.original;
  late final _name = TextEditingController(text: _g.fullName);
  late final _contact = TextEditingController(
      text: normalizePhone(_g.contact) != null
          ? formatPhone(normalizePhone(_g.contact)!)
          : _g.contact);
  late final _relationship = TextEditingController(text: _g.relationship);
  late final _table = TextEditingController(text: _g.tableLabel);
  late final _meal = TextEditingController(text: _g.meal);
  late RsvpStatus _status = _g.status;
  late int _companions = _g.companions;

  @override
  void dispose() {
    for (final c in [_name, _contact, _relationship, _table, _meal]) {
      c.dispose();
    }
    super.dispose();
  }

  GuestFormValues get _values => GuestFormValues(
        fullName: _name.text,
        contact: _contact.text,
        relationship: _relationship.text,
        status: _status,
        companions: _companions,
        tableLabel: _table.text,
        meal: _meal.text,
      );

  bool get _isValid {
    final legacy = _provider.legacyContact;
    final contactOk = (legacy != null && _contact.text == legacy) ||
        AppPhoneField.valueOf(_contact.text) != null;
    return GuestFormFields.validateName(_name.text) == null &&
        contactOk &&
        GuestFormFields.maxLength(80)(_relationship.text) == null &&
        GuestFormFields.maxLength(40)(_table.text) == null &&
        GuestFormFields.maxLength(40)(_meal.text) == null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    final saved = await _provider.save(_values);
    if (!mounted) return;
    if (saved == null) {
      showToast(context,
          message: _provider.errorMessage ?? 'errors.unknown'.tr(),
          status: 'error');
      return;
    }
    showToast(context, message: 'guests.updated_toast'.tr(), status: 'success');
    context.pop(saved);
  }

  Future<void> _onPopInvoked(bool didPop, Object? _) async {
    if (didPop) return;
    if (await confirmDiscardChanges(context) && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select((EditGuestProvider p) => p.isSaving);
    final dirty = _provider.isDirty(_values);

    return PopScope(
      canPop: !dirty || isSaving,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppTopBar(title: 'guests.edit_title'.tr()),
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
                  GuestFormFields(
                    name: _name,
                    contact: _contact,
                    status: _status,
                    onStatusChanged: (s) => setState(() => _status = s),
                    companions: _companions,
                    onCompanionsChanged: (n) => setState(() => _companions = n),
                    enabled: !isSaving,
                    showDetails: true,
                    relationship: _relationship,
                    tableLabel: _table,
                    meal: _meal,
                    legacyContact: _provider.legacyContact,
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
