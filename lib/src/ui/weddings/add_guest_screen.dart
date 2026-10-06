import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/ui/weddings/providers/add_guest_provider.dart';
import 'package:zawaj_app/src/ui/weddings/widgets/guest_form_fields.dart';

/// Screen 6 (add guest) as a modal bottom sheet: name (required), contact,
/// RSVP status segmented control, a companions stepper, and notes. On success
/// pops `true` so the guest list reloads. Present via [showAppSheet].
class AddGuestScreen extends StatelessWidget {
  const AddGuestScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddGuestProvider>(
      create: (_) => AddGuestProvider(weddingId: weddingId),
      child: const _AddGuestView(),
    );
  }
}

class _AddGuestView extends StatefulWidget {
  const _AddGuestView();

  @override
  State<_AddGuestView> createState() => _AddGuestViewState();
}

class _AddGuestViewState extends State<_AddGuestView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _note = TextEditingController();
  RsvpStatus _status = RsvpStatus.pending;
  int _companions = 0;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    final provider = context.read<AddGuestProvider>();
    final ok = await provider.submit(
      fullName: _name.text,
      contact: AppPhoneField.valueOf(_contact.text),
      status: _status,
      companions: _companions,
      note: _note.text,
    );
    if (!mounted) return;
    if (!ok) {
      showToast(context,
          message: provider.errorMessage ?? 'errors.server'.tr(), status: 'error');
      return;
    }
    showToast(context, message: 'guests.added_toast'.tr(), status: 'success');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isLoading = context.select((AddGuestProvider p) => p.isLoading);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppBorders.bottomSheet,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg.w,
        right: AppSpacing.lg.w,
        top: AppSpacing.sm.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: AppSpacing.md.h),
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'guests.add_title'.tr(),
                style: context.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.lg.h),
              GuestFormFields(
                name: _name,
                contact: _contact,
                status: _status,
                onStatusChanged: (v) => setState(() => _status = v),
                companions: _companions,
                onCompanionsChanged: (n) => setState(() => _companions = n),
                enabled: !isLoading,
              ),
              SizedBox(height: AppSpacing.md.h),
              AppTextField(
                controller: _note,
                enabled: !isLoading,
                label: 'guests.note_label'.tr(),
                hint: 'guests.note_hint'.tr(),
                maxLines: 3,
                minLines: 2,
                keyboardType: TextInputType.multiline,
              ),
              SizedBox(height: AppSpacing.lg.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'actions.cancel'.tr(),
                      variant: ButtonVariant.outline,
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'guests.save'.tr(),
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
