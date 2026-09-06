import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../../ui/auth/providers/session_provider.dart';
import 'providers/invite_preview_provider.dart';

class InvitePreviewScreen extends StatelessWidget {
  const InvitePreviewScreen({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvitePreviewProvider(token: token)..load(),
      child: const _InvitePreviewView(),
    );
  }
}

class _InvitePreviewView extends StatelessWidget {
  const _InvitePreviewView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvitePreviewProvider>();
    final authenticated = sessionProvider.isAuthenticated;
    return Scaffold(
      appBar: AppTopBar(title: 'share.invite_preview'.tr()),
      body: Center(
        child: provider.isLoading
            ? const CircularProgressIndicator.adaptive()
            : provider.errorMessage != null
                ? Text(provider.errorMessage!)
                : Card(
                    child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl.w),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(provider.preview!.weddingName,
                              style: context.textTheme.headlineSmall),
                          SizedBox(height: 8.h),
                          Text('share.preview_role'.tr(namedArgs: {
                            'role': 'share.role_${provider.preview!.role}'.tr()
                          })),
                          SizedBox(height: 20.h),
                          if (authenticated)
                            FilledButton(
                                onPressed: provider.isAccepting
                                    ? null
                                    : () async {
                                        final success = await context
                                            .read<InvitePreviewProvider>()
                                            .accept();
                                        if (success && context.mounted) {
                                          pendingInviteToken = null;
                                          context.go(
                                              '/weddings/${provider.accepted!.weddingId}');
                                        }
                                      },
                                child: Text('share.accept_invite'.tr()))
                          else
                            FilledButton(
                                onPressed: () {
                                  pendingInviteToken = context
                                      .read<InvitePreviewProvider>()
                                      .token;
                                  context.go(AppRoutes.login);
                                },
                                child: Text('share.login_to_accept'.tr()))
                        ]))),
      ),
    );
  }
}
