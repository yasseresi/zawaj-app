import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/ui/weddings/providers/weddings_provider.dart';

/// Home shell for the Phase-2 weddings slice ("قوائمي"): lists the caller's
/// weddings with role + guest count. Mirrors the `زواج/` prototype's home
/// states one-for-one — skeleton loading, empty state, list, long-press delete
/// menu, confirm dialog, and success toast. Scopes its own [WeddingsProvider]
/// and loads on mount.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WeddingsProvider>(
      create: (_) => WeddingsProvider()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeddingsProvider>();

    return Scaffold(
      appBar: AppTopBar(
        title: 'home.title'.tr(),
        actions: [
          IconButton(
            tooltip: 'settings.logout'.tr(),
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<SessionProvider>().signOut(),
          ),
        ],
      ),
      floatingActionButton: provider.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openCreate(context),
              icon: const Icon(Icons.add_rounded),
              label: Text('weddings.create'.tr()),
            ),
      body: SafeArea(child: _body(context, provider)),
    );
  }

  Widget _body(BuildContext context, WeddingsProvider provider) {
    switch (provider.status) {
      case AppStatus.initial:
      case AppStatus.loading:
        return const _SkeletonList();
      case AppStatus.failure:
        return AppErrorWidget(
          title: 'weddings.error_title'.tr(),
          message: provider.errorMessage,
          onRetry: () => context.read<WeddingsProvider>().load(),
        );
      case AppStatus.success:
        if (provider.isEmpty) {
          return _EmptyLists(onCreate: () => _openCreate(context));
        }
        return RefreshIndicator.adaptive(
          onRefresh: () => context.read<WeddingsProvider>().load(),
          child: ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            itemCount: provider.weddings.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md.h),
            itemBuilder: (_, i) => _WeddingTile(wedding: provider.weddings[i]),
          ),
        );
    }
  }

  /// Push the create form; if it pops `true` a wedding was created, so reload
  /// the list to reflect it (server is the source of truth for role/count).
  Future<void> _openCreate(BuildContext context) async {
    final provider = context.read<WeddingsProvider>();
    final created = await context.pushNamed<Object?>('create_wedding');
    if (created == true) await provider.load();
  }
}

/// A single wedding row matching the prototype's `ListCard`: serif name with a
/// "shared" badge for non-owner roles, a guest-count + date meta row, and a
/// primary "عرض" pill that opens the wedding. Long-pressing an owned wedding
/// reveals the delete menu.
class _WeddingTile extends StatelessWidget {
  const _WeddingTile({required this.wedding});

  final Wedding wedding;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return GestureDetector(
      onLongPressStart: (details) =>
          _onLongPress(context, details.globalPosition),
      child: AppCard(
        onTap: _open(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          wedding.name,
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!wedding.role.isOwner) ...[
                        SizedBox(width: AppSpacing.sm.w),
                        const _SharedBadge(),
                      ],
                    ],
                  ),
                  SizedBox(height: 6.h),
                  _MetaRow(wedding: wedding),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            AppButton(
              label: 'weddings.view'.tr(),
              height: ButtonSize.small,
              onPressed: _open(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Open the wedding; on return, silently re-sync the list so edits, guest
  /// counts, a transfer, or lost access show without a loading flash.
  VoidCallback _open(BuildContext context) => () async {
        final provider = context.read<WeddingsProvider>();
        await context.pushNamed(
          'wedding',
          pathParameters: {'id': wedding.id},
          extra: wedding,
        );
        await provider.load(silent: true);
      };

  /// Owner-only: the backend delete is gated on the owner role, so hide the
  /// affordance for shared weddings entirely.
  Future<void> _onLongPress(BuildContext context, Offset globalPos) async {
    if (!wedding.role.isOwner) return;

    final cs = context.colors;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        globalPos & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, size: 18.sp, color: cs.error),
              SizedBox(width: AppSpacing.sm.w),
              Text(
                'weddings.delete'.tr(),
                style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );

    if (selected == 'delete' && context.mounted) {
      await _confirmDelete(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<WeddingsProvider>();
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: 'weddings.delete_confirm_title'.tr(),
      message: 'weddings.delete_confirm_message'.tr(),
      confirmLabel: 'weddings.delete_confirm_action'.tr(),
      cancelLabel: 'weddings.cancel'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await provider.delete(wedding.id);
    if (!context.mounted) return;

    if (ok) {
      showToast(context,
          message: 'weddings.deleted_toast'.tr(), status: 'success');
    } else {
      showToast(context,
          message: provider.errorMessage ?? 'weddings.delete_error'.tr(),
          status: 'error');
    }
  }
}

/// The amber "مشترك" pill shown on weddings the caller doesn't own.
class _SharedBadge extends StatelessWidget {
  const _SharedBadge();

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final bg = appColors.warningContainer ?? appColors.warning;
    final fg = appColors.onWarningContainer ?? appColors.onWarning;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        'weddings.shared_badge'.tr(),
        style: context.textTheme.labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 10.sp),
      ),
    );
  }
}

/// Guest-count and event-date meta row with leading icons.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.wedding});

  final Wedding wedding;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final style =
        context.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    return Wrap(
      spacing: 14.w,
      runSpacing: 4.h,
      children: [
        _meta(Icons.people_alt_outlined,
            'weddings.guests_count'.pluralOrZero(wedding.guestCount), style, cs),
        if (wedding.eventDate != null)
          _meta(Icons.calendar_today_outlined,
              wedding.eventDate!.toIso8601DateOnly, style, cs),
      ],
    );
  }

  Widget _meta(IconData icon, String label, TextStyle? style, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: cs.onSurfaceVariant),
        SizedBox(width: 4.w),
        Text(label, style: style),
      ],
    );
  }
}

/// Empty state mirroring the prototype: a filled primary-tint disc with a
/// clipboard glyph, a title, a subtitle, and a primary create button.
class _EmptyLists extends StatelessWidget {
  const _EmptyLists({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132.w,
              height: 132.w,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined,
                  size: 62.sp, color: cs.primary),
            ),
            SizedBox(height: 20.h),
            Text(
              'weddings.empty_title'.tr(),
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              'weddings.empty_subtitle'.tr(),
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            AppButton(
              label: 'weddings.create'.tr(),
              prefixIcon: const Icon(Icons.add_rounded, size: 18),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

/// Three shimmer placeholder cards shown while the list loads — matches the
/// prototype's `LoadingLists` skeleton.
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md.h),
        itemBuilder: (_, __) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('حفل زفاف ليلى وعمر',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Text('245 ضيف · 12 يونيو 2026', style: tt.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
