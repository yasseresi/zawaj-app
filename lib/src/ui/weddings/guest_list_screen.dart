import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/ui/weddings/add_guest_screen.dart';
import 'package:zawaj_app/src/ui/weddings/guest_detail_screen.dart';
import 'package:zawaj_app/src/ui/weddings/providers/guests_provider.dart';

/// Screen 5 (guest list) wired to `GET /weddings/:id/guests`. Header shows the
/// wedding name + "N guests · date", a search box and four RSVP filter tabs with
/// wedding-wide counts drive server-side filtering, and the body renders the
/// filtered guests (loading / empty / error / list). RTL-first per the mockup.
class GuestListScreen extends StatelessWidget {
  const GuestListScreen({super.key, required this.weddingId, this.wedding});

  final String weddingId;

  /// The wedding passed through navigation `extra` (name/date/count for the
  /// header). Null when the screen is deep-linked — the header falls back to a
  /// generic title.
  final Wedding? wedding;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GuestsProvider>(
      create: (_) => GuestsProvider(weddingId: weddingId)..load(),
      child: _GuestListView(wedding: wedding),
    );
  }
}

class _GuestListView extends StatefulWidget {
  const _GuestListView({this.wedding});

  final Wedding? wedding;

  @override
  State<_GuestListView> createState() => _GuestListViewState();
}

class _GuestListViewState extends State<_GuestListView> {
  final _search = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 350));

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer.run(() {
      if (mounted) context.read<GuestsProvider>().search(value);
    });
  }

  Future<void> _openAdd() async {
    final provider = context.read<GuestsProvider>();
    final added = await showAppSheet<bool>(
      child: AddGuestScreen(weddingId: provider.weddingId),
    );
    if (added ?? false) await provider.load();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.wedding?.role.canEdit ?? false;
    return Scaffold(
      appBar: AppTopBar(
        title: widget.wedding?.name ?? 'home.title'.tr(),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: _openAdd,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (widget.wedding != null) _headerSubtitle(context, widget.wedding!),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg.w, AppSpacing.sm.h, AppSpacing.lg.w, AppSpacing.sm.h),
              child: AppTextField(
                controller: _search,
                hint: 'guests.search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
              ),
            ),
            const _FilterTabs(),
            Expanded(child: _GuestBody(canEdit: canEdit)),
          ],
        ),
      ),
    );
  }

  Widget _headerSubtitle(BuildContext context, Wedding w) {
    final cs = context.colors;
    final tt = context.textTheme;
    final count = 'weddings.guests_count'.plural(w.guestCount);
    final text = w.eventDate == null
        ? count
        : 'guests.count_date'
            .tr(namedArgs: {'count': count, 'date': w.eventDate!.toIso8601DateOnly});
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Text(text, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
    );
  }
}

/// The four RSVP filter tabs, each showing its wedding-wide count.
class _FilterTabs extends StatelessWidget {
  const _FilterTabs();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuestsProvider>();
    final counts = provider.counts;
    final active = provider.filter;

    final tabs = <(GuestFilter, String, int)>[
      (GuestFilter.all, 'guests.tab_all'.tr(), counts.all),
      (GuestFilter.confirmed, 'guests.tab_confirmed'.tr(), counts.confirmed),
      (GuestFilter.pending, 'guests.tab_pending'.tr(), counts.pending),
      (GuestFilter.declined, 'guests.tab_declined'.tr(), counts.declined),
    ];

    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm.w),
        itemBuilder: (_, i) {
          final (filter, label, count) = tabs[i];
          return _FilterChip(
            label: label,
            count: count,
            selected: filter == active,
            onTap: () => context.read<GuestsProvider>().setFilter(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final fg = selected ? cs.onPrimary : cs.onSurfaceVariant;

    return Material(
      color: selected ? cs.primary : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: tt.labelLarge?.copyWith(color: fg)),
              SizedBox(width: 6.w),
              Text('$count',
                  style: tt.labelMedium?.copyWith(
                      color: fg, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Body: loading / error / empty / guest list, driven by [GuestsProvider].
class _GuestBody extends StatelessWidget {
  const _GuestBody({required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuestsProvider>();

    if (provider.status.isLoading || provider.status.isInitial) {
      return AppLoading(message: 'guests.loading'.tr());
    }
    if (provider.status.isFailure) {
      return AppErrorWidget(
        title: 'guests.error_title'.tr(),
        message: provider.errorMessage,
        onRetry: () => context.read<GuestsProvider>().load(),
      );
    }
    if (provider.isEmpty) {
      final searching = provider.searchQuery.isNotEmpty;
      final filtering = provider.filter != GuestFilter.all;
      if (searching) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'guests.search_empty'
              .tr(namedArgs: {'query': provider.searchQuery}),
        );
      }
      if (filtering) {
        return AppEmptyState(
          icon: Icons.filter_alt_off_rounded,
          title: 'guests.filter_empty'.tr(),
        );
      }
      return AppEmptyState(
        icon: Icons.group_outlined,
        title: 'guests.empty_title'.tr(),
        subtitle: 'guests.empty_subtitle'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<GuestsProvider>().load(),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg.w, AppSpacing.sm.h, AppSpacing.lg.w, AppSpacing.xl.h),
        itemCount: provider.guests.length,
        separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm.h),
        itemBuilder: (_, i) => _GuestTile(
          guest: provider.guests[i],
          weddingId: provider.weddingId,
          canEdit: canEdit,
        ),
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  const _GuestTile({
    required this.guest,
    required this.weddingId,
    required this.canEdit,
  });

  final Guest guest;
  final String weddingId;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return AppCard(
      onTap: () => context.pushNamed(
        'guest_detail',
        pathParameters: {'id': weddingId, 'gid': guest.id},
        extra: GuestDetailArgs(initial: guest, canEdit: canEdit),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              guest.initial,
              style: tt.titleMedium?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.fullName,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (guest.contact.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    guest.contact,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          GuestStatusPill(status: guest.status, compact: true),
        ],
      ),
    );
  }
}
