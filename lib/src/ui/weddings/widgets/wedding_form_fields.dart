import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

/// The wedding fields shared by create and edit: name (required, ≤120),
/// optional event date and description (≤2000). Place inside a [Form]; the
/// parent owns the controllers, the date and submission.
class WeddingFormFields extends StatelessWidget {
  const WeddingFormFields({
    super.key,
    required this.name,
    required this.description,
    required this.date,
    required this.onDateChanged,
    this.enabled = true,
    this.canClearDate = true,
  });

  static const nameMax = 120;
  static const descriptionMax = 2000;

  final TextEditingController name;
  final TextEditingController description;
  final DateTime? date;
  final ValueChanged<DateTime?> onDateChanged;
  final bool enabled;

  /// The backend can't clear a saved event date, so edit mode hides the clear
  /// button once a date exists.
  final bool canClearDate;

  static String? validateName(String? v) {
    if (AppUtils.isBlank(v)) return 'weddings.name_required'.tr();
    if (v!.trim().length > nameMax) return 'weddings.name_too_long'.tr();
    return null;
  }

  static String? validateDescription(String? v) =>
      (v != null && v.trim().length > descriptionMax)
          ? 'weddings.description_too_long'.tr()
          : null;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showAdaptiveDatePicker(
      context,
      initialDate: date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: name,
          enabled: enabled,
          label: 'weddings.name_label'.tr(),
          hint: 'weddings.name_hint'.tr(),
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.favorite_outline),
          validator: validateName,
        ),
        SizedBox(height: AppSpacing.md.h),
        GestureDetector(
          onTap: enabled ? () => _pickDate(context) : null,
          child: AbsorbPointer(
            child: AppTextField(
              readOnly: true,
              enabled: enabled,
              label: 'weddings.date_label'.tr(),
              hint: 'weddings.date_hint'.tr(),
              prefixIcon: const Icon(Icons.event_outlined),
              suffixIcon: (date == null || !canClearDate)
                  ? null
                  : IconButton(
                      icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
                      onPressed: enabled ? () => onDateChanged(null) : null,
                    ),
              // controller-less: drive the displayed text via initialValue key
              key: ValueKey(date?.toIso8601DateOnly ?? 'no-date'),
              initialValue: date?.toIso8601DateOnly ?? '',
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        AppTextField(
          controller: description,
          enabled: enabled,
          label: 'weddings.description_label'.tr(),
          hint: 'weddings.description_hint'.tr(),
          maxLines: 4,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          validator: validateDescription,
        ),
      ],
    );
  }
}
