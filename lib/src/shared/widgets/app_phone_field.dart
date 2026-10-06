import '../../imports/core_imports.dart';
import '../../utils/phone.dart';

/// Algerian phone input (national format, e.g. `0672 85 99 65`).
///
/// Always LTR, even inside RTL layouts. Accepts digits and common separators
/// (a pasted `+213…` number is fine) and validates with [normalizePhone].
/// Read the stored value with [AppPhoneField.valueOf].
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    this.controller,
    this.label,
    this.required = false,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController? controller;

  /// Defaults to `phone.label`.
  final String? label;

  /// When false (default) an empty field is valid.
  final bool required;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  /// Canonical value for [text]: the national number, `''` when empty, or
  /// null when the input is not a valid Algerian number.
  static String? valueOf(String text) =>
      text.trim().isEmpty ? '' : normalizePhone(text);

  String? _validate(String? value) {
    final v = valueOf(value ?? '');
    if (v == null) return 'phone.invalid'.tr();
    if (v.isEmpty && required) return 'phone.required'.tr();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'phone.label'.tr(),
      hint: 'phone.hint'.tr(),
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.telephoneNumber],
      textDirection: TextDirection.ltr,
      prefixIcon: const Icon(Icons.phone_outlined),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-.()]')),
        LengthLimitingTextInputFormatter(20),
      ],
      validator: _validate,
      onChanged: onChanged,
    );
  }
}
