import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../../data/repositories/invite_repository.dart';
import 'providers/pending_invites_provider.dart';
import 'widgets/invite_card.dart';

class PendingInvitesScreen extends StatelessWidget {
  const PendingInvitesScreen({
    super.key,
    this.repository,
    this.initialInvites,
  });

  final InviteRepository? repository;
  final List<PendingInvite>? initialInvites;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PendingInvitesProvider>(
      create: (_) => PendingInvitesProvider(
        repository: repository,
        initialInvites: initialInvites,
      )..load(),
      child: const _PendingInvitesView(),
    );
  }
}

class _PendingInvitesView extends StatelessWidget {
  const _PendingInvitesView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PendingInvitesProvider>();

    return Scaffold(
      appBar: AppTopBar(
        title: 'invites.title'.tr(),
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PendingInvitesProvider provider) {
    if (provider.status.isFailure) {
      return AppErrorWidget(
        title: 'invites.error_title'.tr(),
        message: provider.errorMessage,
        onRetry: () => context.read<PendingInvitesProvider>().load(),
      );
    }

    if (provider.isLoading) {
      return _buildSkeletonLoading();
    }

    if (provider.isEmpty) {
      return AppEmptyState(
        icon: Icons.mail_outline_rounded,
        title: 'invites.empty_title'.tr(),
        subtitle: 'invites.empty_subtitle'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PendingInvitesProvider>().load(),
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.md.w),
        itemCount: provider.invites.length,
        itemBuilder: (context, index) {
          final invite = provider.invites[index];
          final isAcceptLoading = provider.actionLoadingId == invite.id;

          return InviteCard(
            invite: invite,
            isAcceptLoading: isAcceptLoading,
            onAccept: () => _handleAccept(context, invite),
            onDecline: () => _showDeclineDialog(context, invite),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.md.w),
        itemCount: 2,
        itemBuilder: (context, index) {
          return AppCard(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18.h,
                  width: 200.w,
                  color: Colors.white,
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 12.h,
                  width: 140.w,
                  color: Colors.white,
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, PendingInvite invite) async {
    final success =
        await context.read<PendingInvitesProvider>().acceptInvite(invite.id);
    if (success && context.mounted) {
      context.showSuccessSnackBar('invites.accept_success'.tr());
    }
  }

  Future<void> _showDeclineDialog(
      BuildContext context, PendingInvite invite) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: 'invites.decline_confirm_title'.tr(),
      message: 'invites.decline_confirm_message'.tr(
        namedArgs: {'event': invite.event},
      ),
      confirmLabel: 'invites.decline'.tr(),
      cancelLabel: 'actions.cancel'.tr(),
      isDestructive: true,
    );

    if ((confirmed ?? false) && context.mounted) {
      final success =
          await context.read<PendingInvitesProvider>().declineInvite(invite.id);
      if (success && context.mounted) {
        context.showSuccessSnackBar('invites.decline_success'.tr());
      }
    }
  }
}
