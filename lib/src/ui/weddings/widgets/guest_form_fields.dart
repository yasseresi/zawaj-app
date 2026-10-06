import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/guest_model.dart';

/// The guest fields shared by add and edit: name (required, ≤120), phone
/// contact, RSVP status and companions; [showDetails] adds relationship,
/// (edit). Place inside a [Form]; the parent owns the state.
class GuestFormFields extends StatelessWidget {
  const GuestFormFields({
    super.key,
    required this.name,
    required this.contact,
    required this.status,
    required this.onStatusChanged,
    required this.companions,
    required this.onCompanionsChanged,
    this.enabled = true,
    this.showDetails = false,
    this.relationship,
    this.legacyContact,
  });

  static const nameMax = 120;

  final TextEditingController name;
  final TextEditingController contact;
  final RsvpStatus status;
  final ValueChanged<RsvpStatus> onStatusChanged;
  final int companions;
  final ValueChanged<int> onCompanionsChanged;
  final bool enabled;
  final bool showDetails;
  final TextEditingController? relationship;

  /// A saved contact that isn't a phone number; accepted while unchanged.
  final String? legacyContact;

  static String? validateName(String? v) {
    if (AppUtils.isBlank(v)) return 'guests.name_required'.tr();
    if (v!.trim().length > nameMax) return 'guests.name_too_long'.tr();
    return null;
  }

  static String? Function(String?) maxLength(int max) =>
      (v) => (v != null && v.trim().length > max)
          ? 'guests.field_too_long'.tr(namedArgs: {'max': '$max'})
          : null;

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: AppSpacing.md.h);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: name,
          enabled: enabled,
          label: 'guests.name_label'.tr(),
          hint: 'guests.name_hint'.tr(),
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline),
          autofillHints: const [AutofillHints.name],
          validator: validateName,
        ),
        gap,
        AppPhoneField(
          controller: contact,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          legacyValue: legacyContact,
        ),
        if (legacyContact != null && contact.text == legacyContact) ...[
          SizedBox(height: AppSpacing.xs.h),
          Text('guests.contact_legacy_hint'.tr(),
              style: context.textTheme.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
        if (showDetails) ...[
          gap,
          AppTextField(
            controller: relationship,
            enabled: enabled,
            label: 'guests.relationship_label'.tr(),
            hint: 'guests.relationship_hint'.tr(),
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.diversity_3_outlined),
            validator: maxLength(80),
          ),
        ],
        gap,
        _StatusSelector(
          value: status,
          enabled: enabled,
          onChanged: onStatusChanged,
        ),
        gap,
        _CompanionsStepper(
          value: companions,
          enabled: enabled,
          onChanged: onCompanionsChanged,
        ),
      ],
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
