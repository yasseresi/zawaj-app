import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';
import 'package:zawaj_app/src/utils/phone.dart';

/// Call / WhatsApp / Copy actions for a guest's phone number (national
/// format). Opened from the guest detail contact row.
Future<void> showContactActionsSheet(BuildContext context, String phone) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => ContactActionsSheet(phone: phone),
  );
}

class ContactActionsSheet extends StatelessWidget {
  const ContactActionsSheet({super.key, required this.phone});
  final String phone;

  Future<void> _launch(BuildContext context, Uri uri) async {
    Navigator.of(context).pop();
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!opened) {
      showGlobalToast(
          message: 'guests.contact_launch_failed'.tr(), status: 'error');
    }
  }

  Future<void> _copy(BuildContext context) async {
    Navigator.of(context).pop();
    await Clipboard.setData(ClipboardData(text: phone));
    showGlobalToast(message: 'guests.contact_copied'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    return Material(
      color: cs.surface,
      borderRadius: AppBorders.bottomSheet,
      clipBehavior: Clip.antiAlias,
      // Explicit colours: the theme's ListTile title style carries none, which
      // renders washed-out text inside sheets.
      child: ListTileTheme(
        textColor: cs.onSurface,
        iconColor: cs.primary,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(formatPhone(phone),
                    style:
                        tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: AppSpacing.sm.h),
              ListTile(
                leading: Icon(Icons.call_outlined, color: cs.primary),
                title: Text('guests.contact_call'.tr()),
                onTap: () => _launch(context, telUri(phone)),
              ),
              ListTile(
                leading: Icon(Icons.chat_outlined, color: cs.primary),
                title: Text('guests.contact_whatsapp'.tr()),
                onTap: () => _launch(context, whatsappUri(phone)),
              ),
              ListTile(
                leading: Icon(Icons.copy_rounded, color: cs.primary),
                title: Text('guests.contact_copy'.tr()),
                onTap: () => _copy(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
