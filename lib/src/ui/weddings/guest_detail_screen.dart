import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/guest_detail_model.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/ui/weddings/providers/guest_detail_provider.dart';
import 'package:zawaj_app/src/ui/weddings/widgets/add_note_sheet.dart';
import 'package:zawaj_app/src/ui/weddings/widgets/edit_status_sheet.dart';

/// Navigation payload for the guest-detail route: the tapped guest (for an
/// instant header) plus whether the caller may edit it.
class GuestDetailArgs {
  const GuestDetailArgs({this.initial, this.canEdit = false});
  final Guest? initial;
  final bool canEdit;
}

/// Screen 7 (guest detail) wired to `GET /weddings/:id/guests/:gid`. Shows the
/// guest's identity + status, an info card, the notes thread, and the change
/// history timeline. [initial] (passed via nav `extra`) renders the header while
/// the fetch is in flight. RTL-first per the mockup.
class GuestDetailScreen extends StatelessWidget {
  const GuestDetailScreen({
    super.key,
    required this.weddingId,
    required this.guestId,
    this.initial,
    this.canEdit = false,
    this.repository,
  });

  final String weddingId;
  final String guestId;
  final Guest? initial;
  final bool canEdit;
  final GuestRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GuestDetailProvider>(
      create: (_) => GuestDetailProvider(
        weddingId: weddingId,
        guestId: guestId,
        repository: repository,
      )..load(),
      child: _GuestDetailView(initial: initial, canEdit: canEdit),
    );
  }
}

class _GuestDetailView extends StatelessWidget {
  const _GuestDetailView({this.initial, this.canEdit = false});

  final Guest? initial;
  final bool canEdit;

  Future<void> _editStatus(BuildContext context, RsvpStatus current) async {
    final provider = context.read<GuestDetailProvider>();
    final picked = await showAppSheet<RsvpStatus>(
      child: EditStatusSheet(current: current),
    );
    if (picked == null || picked == current) return;
    final ok = await provider.setStatus(picked);
    if (!context.mounted) return;
    if (!ok) {
      showToast(context,
          message: provider.errorMessage ?? 'errors.server'.tr(),
          status: 'error');
      return;
    }
    showToast(context, message: 'guests.status_toast'.tr(), status: 'success');
  }

  Future<void> _addNote(BuildContext context) async {
    final provider = context.read<GuestDetailProvider>();
    final body = await showAppSheet<String>(child: const AddNoteSheet());
    if (body == null || body.isEmpty) return;
    final ok = await provider.addNote(body);
    if (!context.mounted) return;
    if (!ok) {
      showToast(context,
          message: provider.errorMessage ?? 'errors.server'.tr(),
          status: 'error');
      return;
    }
    showToast(context, message: 'guests.note_added_toast'.tr(), status: 'success');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuestDetailProvider>();
    final detail = provider.detail;
    final guest = detail?.guest ?? initial;

    return Scaffold(
      appBar: AppTopBar(
        title: 'guests.detail_title'.tr(),
        actions: (canEdit && guest != null)
            ? [
                IconButton(
                  icon: const Icon(Icons.note_add_outlined),
                  tooltip: 'guests.add_note_title'.tr(),
                  onPressed: () => _addNote(context),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'guests.edit_status_title'.tr(),
                  onPressed: () => _editStatus(context, guest.status),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        top: false,
        child: _body(context, provider, detail, guest),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    GuestDetailProvider provider,
    GuestDetail? detail,
    Guest? guest,
  ) {
    // Failure: full-screen error when we have no guest to show; otherwise
    // inline error banner above the (stale) content so details never vanish.
    if (provider.status.isFailure && guest == null) {
      return AppErrorWidget(
        title: 'guests.detail_error_title'.tr(),
        message: provider.errorMessage,
        onRetry: () => context.read<GuestDetailProvider>().load(),
      );
    }
    if (guest == null) {
      return AppLoading(message: 'guests.loading'.tr());
    }

    return RefreshIndicator(
      onRefresh: () => context.read<GuestDetailProvider>().load(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg.w, AppSpacing.md.h, AppSpacing.lg.w, AppSpacing.xl.h),
        children: [
          if (provider.status.isFailure) ...[
            AppErrorWidget(
              title: 'guests.detail_error_title'.tr(),
              message: provider.errorMessage,
              compact: true,
              onRetry: () => context.read<GuestDetailProvider>().load(),
            ),
            SizedBox(height: AppSpacing.md.h),
          ],
          _Identity(guest: guest),
          SizedBox(height: AppSpacing.lg.h),
          _InfoCard(guest: guest),
          SizedBox(height: AppSpacing.lg.h),
          _SectionTitle(title: 'guests.notes_title'.tr(), count: detail?.notes.length),
          SizedBox(height: AppSpacing.sm.h),
          _Notes(notes: detail?.notes ?? const []),
          SizedBox(height: AppSpacing.lg.h),
          _SectionTitle(title: 'guests.history_title'.tr()),
          SizedBox(height: AppSpacing.sm.h),
          _History(history: detail?.history ?? const []),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.guest});
  final Guest guest;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 34.r,
          backgroundColor: cs.primary.withValues(alpha: 0.12),
          child: Text(
            guest.initial,
            style: tt.headlineSmall
                ?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: AppSpacing.md.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(guest.fullName,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (guest.relationship.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(guest.relationship,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
              SizedBox(height: AppSpacing.sm.h),
              GuestStatusPill(status: guest.status),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.guest});
  final Guest guest;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      if (guest.contact.isNotEmpty)
        (Icons.mail_outline, 'guests.info_contact'.tr(), guest.contact),
      (Icons.group_outlined, 'guests.info_companions'.tr(), '${guest.companions}'),
      if (guest.tableLabel.isNotEmpty)
        (Icons.table_restaurant_outlined, 'guests.info_table'.tr(), guest.tableLabel),
      if (guest.meal.isNotEmpty)
        (Icons.restaurant_outlined, 'guests.info_meal'.tr(), guest.meal),
    ];

    return AppCard(
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const AppDivider(),
            _InfoRow(icon: row.$1, label: row.$2, value: row.$3),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: cs.primary),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(label,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Text(value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.count});
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        if (count != null && count! > 0)
          Text('$count', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.notes});
  final List<GuestNote> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return _EmptyLine(text: 'guests.notes_empty'.tr());
    }
    return Column(
      children: [
        for (final note in notes) ...[
          _NoteCard(note: note),
          SizedBox(height: AppSpacing.sm.h),
        ],
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final GuestNote note;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.body, style: tt.bodyMedium),
          if (note.createdAt != null) ...[
            SizedBox(height: AppSpacing.sm.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(note.createdAt!.toIso8601DateOnly,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ],
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.history});
  final List<ActivityLog> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _EmptyLine(text: 'guests.history_empty'.tr());
    }
    return AppCard(
      child: Column(
        children: [
          for (final (i, entry) in history.indexed)
            _TimelineRow(entry: entry, last: i == history.length - 1),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.last});
  final ActivityLog entry;
  final bool last;

  static String _label(ActivityAction a) => switch (a) {
        ActivityAction.guestAdded => 'guests.act_guest_added'.tr(),
        ActivityAction.guestUpdated => 'guests.act_guest_updated'.tr(),
        ActivityAction.guestStatusChanged => 'guests.act_guest_status_changed'.tr(),
        ActivityAction.noteAdded => 'guests.act_note_added'.tr(),
        ActivityAction.collaboratorJoined => 'guests.act_collaborator_joined'.tr(),
        ActivityAction.listExported => 'guests.act_list_exported'.tr(),
        ActivityAction.unknown => 'guests.act_unknown'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Container(
              width: 10.r,
              height: 10.r,
              decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(_label(entry.action), style: tt.bodyMedium),
          ),
          if (entry.createdAt != null)
            Text(entry.createdAt!.toIso8601DateOnly,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
      child: Text(
        text,
        style: context.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }
}
