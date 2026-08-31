import '../../imports/core_imports.dart';
import '../../utils/platform_info.dart';

/// Platform-adaptive date picker.
///
/// iOS → a Cupertino wheel picker in a modal bottom sheet.
/// Everything else → the Material [showDatePicker] dialog.
///
/// Returns the chosen [DateTime] (date only), or `null` if dismissed.
Future<DateTime?> showAdaptiveDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  if (PlatformInfo.isIOS) {
    return _showCupertinoDatePicker(
      context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

Future<DateTime?> _showCupertinoDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  var selected = initialDate;
  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (sheetContext) {
      final cs = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        top: false,
        child: SizedBox(
          height: 320,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text('actions.cancel'.tr()),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.of(sheetContext).pop(selected),
                    child: Text('actions.done'.tr()),
                  ),
                ],
              ),
              Divider(height: 1, color: cs.outlineVariant),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (value) => selected = value,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
