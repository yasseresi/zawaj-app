import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/wedding_model.dart';
import '../../data/models/invite_link_model.dart';
import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import 'providers/share_provider.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key, required this.weddingId, this.wedding});
  final String weddingId;
  final Wedding? wedding;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => ShareProvider(weddingId: weddingId)..load(),
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
      if (p.errorMessage != null)
        Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(p.errorMessage!,
                style: TextStyle(color: context.colors.error))),
      SizedBox(height: AppSpacing.md.h),
      ...p.members.map((m) => AppCard(
          margin: EdgeInsets.only(bottom: 8.h),
          child: ListTile(
              leading: CircleAvatar(child: Text(m.avatarInitial)),
              title: Text(m.label),
              subtitle: Text('@${m.username}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('share.role_${m.role.name}'.tr()),
                if (!m.role.isOwner)
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => p.removeMember(m.userId))
              ])))),
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
              final file = await provider.export(format);
              if (file == null || !context.mounted) return;
              await SharePlus.instance.share(
                ShareParams(files: [XFile(file.path)], text: label),
              );
            }
          : null,
      icon: isCurrent
          ? SizedBox.square(
              dimension: 18.r,
              child: const CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon),
      label: Text(label),
    );
  }
}
