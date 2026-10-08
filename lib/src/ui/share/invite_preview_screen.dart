import '../../data/models/join_request_model.dart';
import '../../data/repositories/wedding_repository.dart';
import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../../ui/auth/providers/session_provider.dart';
import 'providers/invite_preview_provider.dart';

/// Opened from an invite link. Shows the wedding and the role the link grants;
/// accepting sends the owner a join request (or opens the wedding for someone
/// already in it).
class InvitePreviewScreen extends StatelessWidget {
  const InvitePreviewScreen(
      {super.key, required this.token, this.weddingRepository});
  final String token;
  final WeddingRepository? weddingRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          InvitePreviewProvider(token: token, repository: weddingRepository)
            ..load(),
      child: const _InvitePreviewView(),
    );
  }
}

class _InvitePreviewView extends StatelessWidget {
  const _InvitePreviewView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvitePreviewProvider>();
    final accepted = provider.accepted;
    final Widget body;
    if (provider.isLoading) {
      body = const CircularProgressIndicator.adaptive();
    } else if (accepted != null && accepted.isPending) {
      body = _RequestSentCard(result: accepted);
    } else if (provider.preview == null) {
      body = Padding(
        padding: EdgeInsets.all(AppSpacing.xl.w),
        child: Text(provider.errorMessage ?? 'errors.unknown'.tr(),
            textAlign: TextAlign.center),
      );
    } else {
      body = const _PreviewCard();
    }
    return Scaffold(
      appBar: AppTopBar(title: 'share.invite_preview'.tr()),
      body: Center(child: body),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  Future<void> _requestToJoin(BuildContext context) async {
    final provider = context.read<InvitePreviewProvider>();
    if (!await provider.accept() || !context.mounted) return;
    pendingInviteToken = null;
    final result = provider.accepted!;
    // Already in the wedding: open it. A pending request stays on this screen
    // (the "Request sent" card).
    if (!result.isPending) context.go('/weddings/${result.weddingId}');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvitePreviewProvider>();
    final preview = provider.preview!;
    final authenticated =
        context.select((SessionProvider s) => s.isAuthenticated);
    final cs = context.colors;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(preview.weddingName,
              style: context.textTheme.headlineSmall,
              textAlign: TextAlign.center),
          SizedBox(height: 8.h),
          Text(
            'share.preview_request_role'
                .tr(namedArgs: {'role': 'share.role_${preview.role}'.tr()}),
            textAlign: TextAlign.center,
          ),
          if (provider.errorMessage != null) ...[
            SizedBox(height: 12.h),
            Text(provider.errorMessage!,
                textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
          ],
          SizedBox(height: 20.h),
          if (authenticated)
            FilledButton(
              onPressed:
                  provider.isAccepting ? null : () => _requestToJoin(context),
              child: provider.isAccepting
                  ? Semantics(
                      label: 'share.request_to_join'.tr(),
                      child: SizedBox.square(
                        dimension: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Text('share.request_to_join'.tr()),
            )
          else
            FilledButton(
              onPressed: () {
                pendingInviteToken = provider.token;
                context.go(AppRoutes.login);
              },
              child: Text('share.login_to_accept'.tr()),
            ),
        ]),
      ),
    );
  }
}

/// Shown after a join request is sent: the owner decides, and the requester
/// is notified either way.
class _RequestSentCard extends StatelessWidget {
  const _RequestSentCard({required this.result});
  final JoinResult result;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.mark_email_read_outlined, size: 48.r, color: cs.primary),
          SizedBox(height: 12.h),
          Text('share.request_sent_title'.tr(),
              style: context.textTheme.headlineSmall),
          SizedBox(height: 8.h),
          Text(
            'share.request_sent_message'
                .tr(namedArgs: {'wedding': result.weddingName}),
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: 20.h),
          FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text('actions.done'.tr()),
          ),
        ]),
      ),
    );
  }
}
