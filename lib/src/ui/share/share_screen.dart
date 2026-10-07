import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/wedding_model.dart';
import '../../data/models/wedding_member_model.dart';
import '../../data/models/invite_link_model.dart';
import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import 'providers/share_provider.dart';
import 'widgets/invite_link_tile.dart';
import 'widgets/member_tile.dart';
import 'widgets/role_picker_sheet.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key, required this.weddingId, this.wedding});
  final String weddingId;
  final Wedding? wedding;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) =>
            ShareProvider(weddingId: weddingId, wedding: wedding)..load(),
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
      builder: (_) => RolePickerSheet(member: member),
    );
    if (picked == null || picked == member.role || !mounted) return;
    final ok = await provider.setRole(member.userId, picked);
    if (!mounted) return;
    if (ok) {
      context.showSuccessSnackBar('share.role_changed'.tr(namedArgs: {
        'name': member.label,
        'role': 'share.role_${picked.name}'.tr(),
      }));
      // Demoted to viewer: they could leave and rejoin through an editor link.
      if (member.role == WeddingRole.editor && picked == WeddingRole.viewer) {
        await _offerRevoke(
          provider,
          role: 'editor',
          title: 'share.revoke_after_demote_title'.tr(),
          message: (count) => 'share.revoke_after_demote_message'
              .tr(namedArgs: {'name': member.label, 'count': '$count'}),
        );
      }
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

  Future<void> _confirmRemove(WeddingMember member) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: 'share.remove_title'.tr(),
      message: 'share.remove_message'.tr(namedArgs: {'name': member.label}),
      confirmLabel: 'share.remove_confirm'.tr(),
      cancelLabel: 'actions.cancel'.tr(),
      isDestructive: true,
    );
    if (!(confirmed ?? false) || !mounted) return;
    final provider = context.read<ShareProvider>();
    if (!await provider.removeMember(member.userId) || !mounted) return;
    // Removal doesn't invalidate links: offer to close the way back in.
    await _offerRevoke(
      provider,
      title: 'share.revoke_after_remove_title'.tr(),
      message: (count) => 'share.revoke_after_remove_message'
          .tr(namedArgs: {'name': member.label, 'count': '$count'}),
    );
  }

  /// Asks whether to revoke the active links (all, or only those granting
  /// [role]) that would let a removed/demoted member back in at their old
  /// level. Does nothing when there are none.
  Future<void> _offerRevoke(
    ShareProvider provider, {
    String? role,
    required String title,
    required String Function(int count) message,
  }) async {
    final count = (role == null
            ? provider.activeLinks
            : provider.activeLinksGranting(role))
        .length;
    if (count == 0 || !mounted) return;
    final revoke = await showAdaptiveConfirmDialog(
      context,
      title: title,
      message: message(count),
      confirmLabel: 'share.revoke_all_confirm'.tr(),
      cancelLabel: 'share.keep_links'.tr(),
      isDestructive: true,
    );
    if (!(revoke ?? false) || !mounted) return;
    if (await provider.revokeAllLinks(role: role)) {
      if (mounted) context.showSuccessSnackBar('share.links_revoked'.tr());
    } else if (mounted) {
      showToast(context,
          message: provider.errorMessage ?? 'errors.unknown'.tr(),
          status: 'error');
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
