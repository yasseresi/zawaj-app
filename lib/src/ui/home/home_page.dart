import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/shared/providers/theme_provider.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/ui/weddings/providers/weddings_provider.dart';

/// Home shell for the Phase-2 weddings slice ("قوائمي"): lists the caller's
/// weddings with role + guest count, rendering the mockup-defined
/// loading / empty / error / list states. Scopes its own [WeddingsProvider]
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
            tooltip: 'settings.language'.tr(),
            icon: const Icon(Icons.translate_rounded),
            onPressed: () => _cycleLocale(context),
          ),
          IconButton(
            tooltip: 'settings.theme'.tr(),
            icon: Icon(context.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggle(context),
          ),
          IconButton(
            tooltip: 'settings.logout'.tr(),
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<SessionProvider>().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        return AppLoading(message: 'weddings.loading'.tr());
      case AppStatus.failure:
        return AppErrorWidget(
          title: 'weddings.error_title'.tr(),
          message: provider.errorMessage,
          onRetry: () => context.read<WeddingsProvider>().load(),
        );
      case AppStatus.success:
        if (provider.isEmpty) {
          return AppEmptyState(
            icon: Icons.celebration_outlined,
            title: 'weddings.empty_title'.tr(),
            subtitle: 'weddings.empty_subtitle'.tr(),
            actionLabel: 'weddings.create'.tr(),
            onAction: () => _openCreate(context),
          );
        }
        return RefreshIndicator(
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

  void _cycleLocale(BuildContext context) {
    const locales = [Locale('ar'), Locale('en'), Locale('fr')];
    final current = context.locale;
    final next = locales[
        (locales.indexWhere((l) => l.languageCode == current.languageCode) + 1) %
            locales.length];
    context.setLocale(next);
  }
}

/// A single wedding row: name, event date, role badge, guest count. Taps through
/// to the wedding's guest list (Phase-2 guests slice).
class _WeddingTile extends StatelessWidget {
  const _WeddingTile({required this.wedding});

  final Wedding wedding;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return AppCard(
      onTap: () => context.pushNamed(
        'wedding',
        pathParameters: {'id': wedding.id},
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(Icons.favorite_rounded, color: cs.primary, size: 22.sp),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wedding.name,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  _subtitle(context),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final guests = 'weddings.guests_count'.plural(wedding.guestCount);
    final date = wedding.eventDate;
    if (date == null) return guests;
    return '${date.toIso8601DateOnly} · $guests';
  }
}
