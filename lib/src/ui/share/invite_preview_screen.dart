import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../../data/models/invite_link_model.dart';
import '../../services/wedding_service.dart';
import '../../ui/auth/providers/session_provider.dart';

class InvitePreviewScreen extends StatefulWidget {
  const InvitePreviewScreen({super.key, required this.token});
  final String token;
  @override
  State<InvitePreviewScreen> createState() => _InvitePreviewScreenState();
}

class _InvitePreviewScreenState extends State<InvitePreviewScreen> {
  InvitePreview? preview;
  String? error;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await WeddingService.instance.previewInvite(widget.token);
    if (!mounted) return;
    result.match(
        (f) => setState(() {
              error = f.message;
              loading = false;
            }),
        (v) => setState(() {
              preview = v;
              loading = false;
            }));
  }

  void _authenticate() {
    pendingInviteToken = widget.token;
    context.go(AppRoutes.login);
  }

  Future<void> _accept() async {
    final result = await WeddingService.instance.acceptInviteLink(widget.token);
    if (!mounted) return;
    result.match((f) => setState(() => error = f.message), (v) {
      pendingInviteToken = null;
      context.go('/weddings/${v.weddingId}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = sessionProvider.isAuthenticated;
    return Scaffold(
        appBar: AppTopBar(title: 'share.invite_preview'.tr()),
        body: Center(
            child: loading
                ? const CircularProgressIndicator()
                : error != null
                    ? Text(error!)
                    : Card(
                        child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl.w),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(preview!.weddingName,
                                      style: context.textTheme.headlineSmall),
                                  SizedBox(height: 8.h),
                                  Text('share.preview_role'.tr(namedArgs: {
                                    'role': 'share.role_${preview!.role}'.tr()
                                  })),
                                  SizedBox(height: 20.h),
                                  if (authenticated)
                                    FilledButton(
                                        onPressed: _accept,
                                        child: Text('share.accept_invite'.tr()))
                                  else
                                    FilledButton(
                                        onPressed: _authenticate,
                                        child:
                                            Text('share.login_to_accept'.tr()))
                                ])))));
  }
}
