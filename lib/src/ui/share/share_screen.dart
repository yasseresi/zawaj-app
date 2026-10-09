import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/wedding_model.dart';
import '../../data/models/wedding_member_model.dart';
import '../../data/repositories/invite_repository.dart';
import '../../data/repositories/wedding_repository.dart';
import '../../data/models/invite_link_model.dart';
import '../../data/models/join_request_model.dart';
import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import 'providers/share_provider.dart';
import 'widgets/invite_link_tile.dart';
import 'widgets/join_request_tile.dart';
import 'widgets/member_tile.dart';
import 'widgets/role_picker_sheet.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({
    super.key,
    required this.weddingId,
    this.wedding,
    this.weddingRepository,
    this.inviteRepository,
  });
  final String weddingId;
  final Wedding? wedding;
  final WeddingRepository? weddingRepository;
  final InviteRepository? inviteRepository;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => ShareProvider(
          weddingId: weddingId,
          wedding: wedding,
          weddingRepository: weddingRepository,
          inviteRepository: inviteRepository,
        )..load(),
        child: _ShareView(wedding: wedding),
      );
}

class _ShareView extends StatefulWidget {
  const _ShareView({this.wedding});
  final Wedding? wedding;
  @override
  State<_ShareView> createState() => _ShareViewState();
}

class _ShareViewState extends State<_ShareView> {
  final _username = TextEditingController();
  bool _qr = false;
  String _role = 'editor';

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final p = context.read<ShareProvider>();
    final ok = await p.invite(_username.text, _role);
    if (ok && mounted) {
      _username.clear();
      context.showSuccessSnackBar('share.invite_sent'.tr());
    }
  }

  Future<void> _createLink() async {
    final p = context.read<ShareProvider>();
    if (p.link == null && await p.createLink(_role) && mounted) {
      context.showSuccessSnackBar('share.link_created'.tr());
    }
  }

  Future<void> _changeRole(WeddingMember member) async {
    final provider = context.read<ShareProvider>();
    final picked = await showModalBottomSheet<WeddingRole>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RolePickerSheet(
        title: 'share.change_role_title'.tr(namedArgs: {'name': member.label}),
        selected: member.role,
      ),
    );
    if (picked == null || picked == member.role || !mounted) return;
    final ok = await provider.setRole(member.userId, picked);
    if (!mounted) return;
    if (ok) {
      context.showSuccessSnackBar('share.role_changed'.tr(namedArgs: {
        'name': member.label,
        'role': 'share.role_${picked.name}'.tr(),
      }));
    } else {
      showToast(context,
          message: provider.errorMessage ?? 'errors.unknown'.tr(),
          status: 'error');
    }
  }

  Future<void> _confirmTransfer(WeddingMember member) async {
    final provider = context.read<ShareProvider>();
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: 'share.transfer_title'.tr(),
      message: 'share.transfer_message'.tr(namedArgs: {'name': member.label}),
      confirmLabel: 'share.transfer_confirm'.tr(),
      isDestructive: true,
    );
    if (!(confirmed ?? false) || !mounted) return;
    final ok = await provider.transferOwnership(member.userId);
    if (!mounted) return;
    if (ok) {
      context.showSuccessSnackBar(
          'share.transferred'.tr(namedArgs: {'name': member.label}));
    } else {
      showToast(context,
          message: provider.errorMessage ?? 'errors.unknown'.tr(),
          status: 'error');
    }
  }

  Future<void> _confirmRevoke(InviteLink link) async {
    final provider = context.read<ShareProvider>();
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: 'share.revoke_title'.tr(),
      message: 'share.revoke_message'.tr(),
      confirmLabel: 'share.revoke_link'.tr(),
      isDestructive: true,
    );
    if (!(confirmed ?? false) || !mounted) return;
    if (await provider.revokeLink(link.id) && mounted) {
      context.showSuccessSnackBar('share.link_revoked'.tr());
    }
  }

  /// Approve a join request. When the link grants editor, the owner picks
  /// editor or viewer first; a viewer request is approved as is.
  Future<void> _approve(JoinRequest request) async {
    final provider = context.read<ShareProvider>();
    var role = request.role;
    if (role == WeddingRole.editor) {
      final picked = await showModalBottomSheet<WeddingRole>(
        context: context,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RolePickerSheet(
          title: 'share.approve_title'.tr(namedArgs: {'name': request.label}),
          selected: request.role,
        ),
      );
      if (picked == null || !mounted) return;
      role = picked;
    }
    final ok = await provider.approveRequest(request, role: role);
    if (!mounted) return;
    if (ok) {
      context.showSuccessSnackBar('share.request_approved'.tr(namedArgs: {
        'name': request.label,
        'role': 'share.role_${role.name}'.tr(),
      }));
    } else {
      showToast(context,
          message: provider.errorMessage ?? 'errors.unknown'.tr(),
          status: 'error');
    }
  }

  Future<void> _decline(JoinRequest request) async {
    final provider = context.read<ShareProvider>();
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: 'share.decline_title'.tr(namedArgs: {'name': request.label}),
      message: 'share.decline_message'.tr(),
      confirmLabel: 'share.decline'.tr(),
      cancelLabel: 'actions.cancel'.tr(),
      isDestructive: true,
    );
    if (!(confirmed ?? false) || !mounted) return;
    final ok = await provider.declineRequest(request);
    if (!mounted) return;
    if (ok) {
      context.showSuccessSnackBar('share.request_declined'.tr());
    } else {
      showToast(context,
          message: provider.errorMessage ?? 'errors.unknown'.tr(),
          status: 'error');
    }
  }

  Future<void> _confirmRemove(WeddingMember member) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: 'share.remove_title'.tr(),
      message: 'share.remove_message'.tr(namedArgs: {'name': member.label}),
      confirmLabel: 'share.remove_confirm'.tr(),
      cancelLabel: 'actions.cancel'.tr(),
      isDestructive: true,
    );
    if ((confirmed ?? false) && mounted) {
      await context.read<ShareProvider>().removeMember(member.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ShareProvider>();
    final link = p.link;
    return Scaffold(
      appBar: AppTopBar(title: 'share.title'.tr()),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final content = _content(context, p, link);
        return Center(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth:
                        constraints.maxWidth > 1024 ? 1000 : double.infinity),
                child: content));
      })),
    );
  }

  Widget _content(BuildContext context, ShareProvider p, InviteLink? link) {
    return ListView(padding: EdgeInsets.all(AppSpacing.lg.w), children: [
      if (p.isOwner && p.joinRequests.isNotEmpty) ...[
        Text(
            'share.join_requests'
                .tr(namedArgs: {'count': '${p.joinRequests.length}'}),
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: AppSpacing.sm.h),
        for (final r in p.joinRequests)
          JoinRequestTile(
            key: ValueKey('join-${r.id}'),
            request: r,
            deciding: p.isDeciding(r.id),
            onApprove: () => _approve(r),
            onDecline: () => _decline(r),
          ),
        SizedBox(height: AppSpacing.lg.h),
      ],
      Text('share.collaborators'.tr(),
          style: context.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
      if (p.isOwner) ...[
        SizedBox(height: AppSpacing.sm.h),
        Row(children: [
          Expanded(
              child: AppTextField(
                  controller: _username,
                  hint: 'share.username_hint'.tr(),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _invite())),
          SizedBox(width: AppSpacing.sm.w),
          FilledButton(
              onPressed: p.busy ? null : _invite, child: const Icon(Icons.add)),
        ]),
      ],
      if (p.errorMessage != null)
        Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(p.errorMessage!,
                style: TextStyle(color: context.colors.error))),
      SizedBox(height: AppSpacing.md.h),
      for (final m in p.members)
        MemberTile(
          member: m,
          // Owners manage everyone but themselves (the owner row).
          onChangeRole:
              (p.isOwner && !m.role.isOwner) ? () => _changeRole(m) : null,
          onMakeOwner:
              (p.isOwner && !m.role.isOwner) ? () => _confirmTransfer(m) : null,
          onRemove:
              (p.isOwner && !m.role.isOwner) ? () => _confirmRemove(m) : null,
        ),
      if (p.isOwner) ...[
        SizedBox(height: AppSpacing.lg.h),
        Text('share.link_section'.tr(),
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: AppSpacing.sm.h),
        Row(children: [
          Expanded(
              child: SegmentedButton<bool>(segments: [
            ButtonSegment(
                value: false,
                label: Text('share.link'.tr()),
                icon: const Icon(Icons.link)),
            ButtonSegment(
                value: true,
                label: Text('share.qr'.tr()),
                icon: const Icon(Icons.qr_code_2))
          ], selected: {
            _qr
          }, onSelectionChanged: (v) => setState(() => _qr = v.first))),
        ]),
        SizedBox(height: AppSpacing.md.h),
        if (link == null) ...[
          DropdownButtonFormField<String>(
              initialValue: _role,
              items: [
                DropdownMenuItem(
                    value: 'editor', child: Text('share.role_editor'.tr())),
                DropdownMenuItem(
                    value: 'viewer', child: Text('share.role_viewer'.tr()))
              ],
              onChanged: (v) => setState(() => _role = v ?? _role)),
          SizedBox(height: AppSpacing.sm.h),
          FilledButton.icon(
              onPressed: p.busy ? null : _createLink,
              icon: const Icon(Icons.add_link),
              label: Text('share.create_link'.tr())),
        ] else if (_qr)
          Center(child: QrImageView(data: link.appUrl, size: 220.r))
        else
          Row(children: [
            Expanded(
                child: Text(link.displayUrl, overflow: TextOverflow.ellipsis)),
            IconButton(
                onPressed: () async {
                  await CopyService.instance.copy(link.appUrl);
                  if (context.mounted) {
                    context.showSuccessSnackBar('share.copied'.tr());
                  }
                },
                icon: const Icon(Icons.copy))
          ]),
        if (link != null) ...[
          SizedBox(height: AppSpacing.md.h),
          OutlinedButton.icon(
              onPressed: () =>
                  SharePlus.instance.share(ShareParams(text: link.appUrl)),
              icon: const Icon(Icons.share),
              label: Text('share.share_link'.tr())),
        ],
        if (p.activeLinks.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md.h),
          Text(
              'share.active_links'
                  .tr(namedArgs: {'count': '${p.activeLinks.length}'}),
              style: context.textTheme.labelLarge
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          SizedBox(height: AppSpacing.xs.h),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(children: [
            for (final l in p.activeLinks)
              InviteLinkTile(
                key: ValueKey(l.id),
                link: l,
                onRevoke: p.busy ? null : () => _confirmRevoke(l),
              ),
          ]),
        ),
      ],
      SizedBox(height: AppSpacing.lg.h),
      Text('share.export_section'.tr(),
          style: context.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
      SizedBox(height: AppSpacing.sm.h),
      Wrap(
        spacing: AppSpacing.sm.w,
        runSpacing: AppSpacing.sm.h,
        children: [
          _ExportButton(
            format: ExportFormat.csv,
            label: 'share.export_csv'.tr(),
            icon: Icons.table_view_outlined,
          ),
          _ExportButton(
            format: ExportFormat.xlsx,
            label: 'share.export_xlsx'.tr(),
            icon: Icons.grid_on_outlined,
          ),
          _ExportButton(
            format: ExportFormat.pdf,
            label: 'share.export_pdf'.tr(),
            icon: Icons.picture_as_pdf_outlined,
          ),
        ],
      ),
    ]);
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton(
      {required this.format, required this.label, required this.icon});

  final ExportFormat format;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShareProvider>();
    final isCurrent = provider.exporting == format;
    return OutlinedButton.icon(
      onPressed: provider.exporting == null
          ? () async {
              final file = await provider.export(
                format,
                languageCode: context.locale.languageCode,
              );
              if (file == null || !context.mounted) return;
              await SharePlus.instance.share(
                ShareParams(files: [XFile(file.path)], text: label),
              );
            }
          : null,
      icon: isCurrent
          ? SizedBox.square(
              dimension: 18.r,
              child: const CircularProgressIndicator.adaptive(strokeWidth: 2))
          : Icon(icon),
      label: Text(label),
    );
  }
}
