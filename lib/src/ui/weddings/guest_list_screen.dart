import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/ui/weddings/add_guest_screen.dart';
import 'package:zawaj_app/src/ui/weddings/guest_detail_screen.dart';
import 'package:zawaj_app/src/ui/weddings/providers/guests_provider.dart';
import 'package:zawaj_app/src/ui/weddings/providers/wedding_provider.dart';
import 'package:zawaj_app/src/utils/phone.dart';

/// Screen 5 (guest list) wired to `GET /weddings/:id/guests`. Header shows the
/// wedding name + "N guests · date", a search box and four RSVP filter tabs with
/// wedding-wide counts drive server-side filtering, and the body renders the
/// filtered guests (loading / empty / error / list). RTL-first per the mockup.
class GuestListScreen extends StatelessWidget {
  const GuestListScreen({
    super.key,
    required this.weddingId,
    this.wedding,
    this.weddingRepository,
    this.guestRepository,
  });

  final String weddingId;

  /// The wedding passed through navigation `extra` (name/date/count for the
  /// header), shown instantly. Null when deep-linked or opened from a
  /// notification — [WeddingProvider] then cold-loads it.
  final Wedding? wedding;
  final WeddingRepository? weddingRepository;
  final GuestRepository? guestRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WeddingProvider>(
          create: (_) => WeddingProvider(
              weddingId: weddingId,
              initial: wedding,
              repository: weddingRepository)
            ..load(),
        ),
        ChangeNotifierProvider<GuestsProvider>(
          create: (_) =>
              GuestsProvider(weddingId: weddingId, repository: guestRepository)
                ..load(),
        ),
      ],
      child: _GuestListView(weddingId: weddingId),
    );
  }
}

class _GuestListView extends StatefulWidget {
  const _GuestListView({required this.weddingId});

  final String weddingId;

  @override
  State<_GuestListView> createState() => _GuestListViewState();
}

class _GuestListViewState extends State<_GuestListView> {
  final _search = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 350));

  @override
  void initState() {
    super.initState();
    _rememberLastAccessedList();
  }

  Future<void> _rememberLastAccessedList() async {
    await StorageService.instance.setLastAccessedWeddingId(widget.weddingId);
  }

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
    if (!mounted) return;
    if (added ?? false) await provider.load();
  }

  /// Share can change the caller's role (ownership transfer), so re-check it
  /// on return.
  Future<void> _openShare(Wedding wedding) async {
    final weddingState = context.read<WeddingProvider>();
    await context.push('/weddings/${widget.weddingId}/share', extra: wedding);
    await weddingState.load();
  }

  Future<void> _openEdit(Wedding wedding) async {
    final weddingState = context.read<WeddingProvider>();
    final updated = await context.push<Wedding>('/weddings/${wedding.id}/edit',
        extra: wedding);
    if (updated != null) weddingState.applyUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    final weddingState = context.watch<WeddingProvider>();
    final wedding = weddingState.wedding;

    if (weddingState.isNotFound) {
      return Scaffold(
        appBar: AppTopBar(title: 'home.title'.tr()),
        body: AppEmptyState(
          icon: Icons.event_busy_outlined,
          title: 'weddings.not_found_title'.tr(),
          subtitle: 'weddings.not_found_subtitle'.tr(),
        ),
      );
    }
    if (wedding == null) {
      return Scaffold(
        appBar: AppTopBar(title: 'home.title'.tr()),
        body: weddingState.status.isFailure
            ? AppErrorWidget(
                title: 'weddings.error_title'.tr(),
                message: weddingState.errorMessage,
                onRetry: () => context.read<WeddingProvider>().load(),
              )
            : AppLoading(message: 'weddings.loading'.tr()),
      );
    }

    final canEdit = wedding.role.canEdit;
    return Scaffold(
      appBar: AppTopBar(
        title: wedding.name,
        actions: [
          IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'share.title'.tr(),
              onPressed: () => _openShare(wedding)),
          if (wedding.role.isOwner)
            PopupMenuButton<_WeddingAction>(
              tooltip: 'weddings.more_actions'.tr(),
              onSelected: (action) => switch (action) {
                _WeddingAction.edit => _openEdit(wedding),
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _WeddingAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_outlined),
                    title: Text('weddings.edit'.tr(),
                        style: TextStyle(color: context.colors.onSurface)),
                  ),
                ),
              ],
            ),
        ],
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
            _headerSubtitle(context, wedding),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg.w, AppSpacing.sm.h,
                  AppSpacing.lg.w, AppSpacing.sm.h),
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
    // GET /weddings/:id has no guest count, so once the guest list has loaded
    // its wedding-wide total is the source of truth (also after adds/deletes,
    // and across later reloads or their failures).
    final total = context.select((GuestsProvider p) => p.knownCounts?.all);
    final count = 'weddings.guests_count'.plural(total ?? w.guestCount);
    final text = w.eventDate == null
        ? count
        : 'guests.count_date'.tr(namedArgs: {
            'count': count,
            'date': w.eventDate!.toIso8601DateOnly
          });
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child:
          Text(text, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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
          padding:
              EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: tt.labelLarge?.copyWith(color: fg)),
              SizedBox(width: 6.w),
              Text('$count',
                  style: tt.labelMedium
                      ?.copyWith(color: fg, fontWeight: FontWeight.bold)),
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

    return RefreshIndicator.adaptive(
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

  Future<void> _openGuest(BuildContext context) async {
    final updated = await context.pushNamed<Object?>(
      'guest_detail',
      pathParameters: {'id': weddingId, 'gid': guest.id},
      extra: GuestDetailArgs(
        initial: guest,
        canEdit: canEdit,
        onGuestUpdated: context.read<GuestsProvider>().replace,
      ),
    );
    if (updated == true && context.mounted) {
      await context.read<GuestsProvider>().load();
    }
  }

  /// Confirms then deletes via the provider. Always returns false so the
  /// [Dismissible] snaps back and the provider's list rebuild (on success) is
  /// what removes the tile — avoids a dismissed widget lingering in the tree.
  Future<bool> _confirmDelete(BuildContext context) async {
    final provider = context.read<GuestsProvider>();
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: 'guests.delete_title'.tr(),
      message: 'guests.delete_message'.tr(namedArgs: {'name': guest.fullName}),
      confirmLabel: 'guests.delete_action'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return false;

    final error = await provider.delete(guest.id);
    if (!context.mounted) return false;
    showGlobalToast(
      message: error ?? 'guests.deleted_toast'.tr(),
      status: error == null ? 'success' : 'error',
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    final card = AppCard(
      onTap: () => _openGuest(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              guest.initial,
              style: tt.titleMedium
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
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
                    // Phones grouped like guest detail; other contacts as-is.
                    switch (normalizePhone(guest.contact)) {
                      final phone? => formatPhone(phone),
                      null => guest.contact,
                    },
                    textDirection: normalizePhone(guest.contact) != null
                        ? TextDirection.ltr
                        : null,
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

    if (!canEdit) return card;

    return Dismissible(
      key: ValueKey('guest_${guest.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      background: _deleteBackground(context),
      child: card,
    );
  }

  /// The red delete affordance revealed while swiping the tile.
  Widget _deleteBackground(BuildContext context) {
    final cs = context.colors;
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: cs.error,
        borderRadius: AppBorders.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: cs.onError),
          SizedBox(width: AppSpacing.xs.w),
          Text(
            'guests.delete_action'.tr(),
            style: context.textTheme.labelLarge
                ?.copyWith(color: cs.onError, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

enum _WeddingAction { edit }
