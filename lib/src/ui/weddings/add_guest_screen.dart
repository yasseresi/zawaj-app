import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/ui/weddings/providers/add_guest_provider.dart';

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
      contact: _contact.text,
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
              AppTextField(
                controller: _name,
                enabled: !isLoading,
                label: 'guests.name_label'.tr(),
                hint: 'guests.name_hint'.tr(),
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (v) {
                  if (AppUtils.isBlank(v)) return 'guests.name_required'.tr();
                  if (v!.trim().length > 120) return 'guests.name_too_long'.tr();
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.md.h),
              AppTextField(
                controller: _contact,
                enabled: !isLoading,
                label: 'guests.contact_label'.tr(),
                hint: 'guests.contact_hint'.tr(),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.alternate_email),
              ),
              SizedBox(height: AppSpacing.md.h),
              _StatusSelector(
                value: _status,
                enabled: !isLoading,
                onChanged: (s) => setState(() => _status = s),
              ),
              SizedBox(height: AppSpacing.md.h),
              _CompanionsStepper(
                value: _companions,
                enabled: !isLoading,
                onChanged: (n) => setState(() => _companions = n),
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

/// Three-option RSVP status segmented control (screen 6 pills).
class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final RsvpStatus value;
  final ValueChanged<RsvpStatus> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final options = <(RsvpStatus, String)>[
      (RsvpStatus.pending, 'guests.status_pending'.tr()),
      (RsvpStatus.confirmed, 'guests.status_confirmed'.tr()),
      (RsvpStatus.declined, 'guests.status_declined'.tr()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('guests.status_label'.tr(),
            style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        SizedBox(height: AppSpacing.xs.h),
        Row(
          children: [
            for (final (i, opt) in options.indexed) ...[
              if (i > 0) SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: _StatusOption(
                  label: opt.$2,
                  selected: opt.$1 == value,
                  onTap: enabled ? () => onChanged(opt.$1) : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Center(
            child: Text(
              label,
              style: tt.labelLarge?.copyWith(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Companions counter (screen 6 stepper); clamped to 0..1000 per the backend.
class _CompanionsStepper extends StatelessWidget {
  const _CompanionsStepper({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('guests.companions_label'.tr(),
            style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        SizedBox(height: AppSpacing.xs.h),
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outline, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepButton(
                icon: Icons.remove,
                filled: false,
                onTap: (enabled && value > 0) ? () => onChanged(value - 1) : null,
              ),
              Text('$value',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              _StepButton(
                icon: Icons.add,
                filled: true,
                onTap:
                    (enabled && value < 1000) ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.filled, required this.onTap});

  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Material(
      color: filled ? cs.primary : cs.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 36.w,
          height: 36.h,
          child: Icon(icon, size: 20.sp, color: filled ? cs.onPrimary : cs.primary),
        ),
      ),
    );
  }
}
