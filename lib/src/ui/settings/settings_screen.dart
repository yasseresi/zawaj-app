import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import '../../shared/providers/theme_provider.dart';
import '../auth/providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/profile_card.dart';
import 'widgets/settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    // Capture locale here (build is a valid listen life-cycle); reading it inside
    // `create` would listen to an InheritedWidget in a callback that never
    // re-runs, which throws.
    final initialLocale = context.locale;
    return ChangeNotifierProvider<SettingsProvider>(
      create: (_) => SettingsProvider(
        themeProvider: themeProvider,
        initialLocale: initialLocale,
      ),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final cs = context.colors;

    return Scaffold(
      appBar: AppTopBar(
        title: 'settings.title'.tr(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md.w),
          child: Column(
            children: [
              ProfileCard(user: session.user),
              SizedBox(height: AppSpacing.lg.h),
              SettingsSection(
                title: 'settings.account_section'.tr(),
                children: [
                  SettingsRow(
                    label: 'settings.edit_profile'.tr(),
                    icon: Icons.person_outline_rounded,
                    onTap: () => _showEditProfile(context),
                  ),
                  SettingsRow(
                    label: 'settings.change_password'.tr(),
                    icon: Icons.lock_outline_rounded,
                    onTap: () => context.push(AppRoutes.changePassword),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg.h),
              SettingsSection(
                title: 'settings.appearance_section'.tr(),
                children: [
                  SettingsRow(
                    label: 'settings.language'.tr(),
                    icon: Icons.language_rounded,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getLanguageName(context.locale.languageCode),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20.r,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () => _showLanguagePicker(context),
                  ),
                  SettingsRow(
                    label: 'settings.dark_mode'.tr(),
                    icon: Icons.dark_mode_outlined,
                    trailing: Switch(
                      value: settingsProvider.isDarkMode,
                      onChanged: (value) {
                        context.read<SettingsProvider>().toggleDarkMode(value);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg.h),
              SettingsSection(
                title: 'settings.collaboration_section'.tr(),
                children: [
                  SettingsRow(
                    label: 'settings.pending_invites'.tr(),
                    icon: Icons.mark_email_unread_outlined,
                    onTap: () => context.push(AppRoutes.pendingInvites),
                  ),
                  SettingsRow(
                    label: 'settings.notifications'.tr(),
                    icon: Icons.notifications_none_rounded,
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl.h),
              AppButton(
                label: 'settings.logout'.tr(),
                variant: ButtonVariant.danger,
                isFullWidth: true,
                isLoading: settingsProvider.isLoggingOut,
                onPressed: () => _showLogoutDialog(context),
              ),
              SizedBox(height: AppSpacing.xl.h),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    return switch (code) {
      'en' => 'settings.english'.tr(),
      'fr' => 'settings.french'.tr(),
      _ => 'settings.arabic'.tr(),
    };
  }

  Future<void> _showEditProfile(BuildContext context) async {
    final user = context.read<SessionProvider>().user;
    if (user == null) return;
    final settings = context.read<SettingsProvider>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        user: user,
        onSave: (name, phone) async {
          final ok =
              await settings.updateProfile(displayName: name, phone: phone);
          if (!ok) {
            showGlobalToast(
                message: settings.profileErrorMessage ?? 'errors.unknown'.tr(),
                status: 'error');
          }
          return ok;
        },
      ),
    );
    if (saved ?? false) {
      showGlobalToast(message: 'settings.profile_saved'.tr());
    }
  }

  void _showLanguagePicker(BuildContext context) {
    final currentCode = context.locale.languageCode;

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings.language'.tr(),
                  style: ctx.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
                _LanguageOptionTile(
                  title: 'settings.arabic'.tr(),
                  subtitle: 'العربية',
                  selected: currentCode == 'ar',
                  onTap: () {
                    _changeLanguage(context, const Locale('ar'));
                    Navigator.pop(ctx);
                  },
                ),
                _LanguageOptionTile(
                  title: 'settings.english'.tr(),
                  subtitle: 'English',
                  selected: currentCode == 'en',
                  onTap: () {
                    _changeLanguage(context, const Locale('en'));
                    Navigator.pop(ctx);
                  },
                ),
                _LanguageOptionTile(
                  title: 'settings.french'.tr(),
                  subtitle: 'Français',
                  selected: currentCode == 'fr',
                  onTap: () {
                    _changeLanguage(context, const Locale('fr'));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeLanguage(BuildContext context, Locale locale) {
    context.setLocale(locale);
    context.read<SettingsProvider>().setLocale(locale);
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: 'settings.logout_confirm_title'.tr(),
      message: 'settings.logout_confirm_message'.tr(),
      confirmLabel: 'settings.logout'.tr(),
      cancelLabel: 'actions.cancel'.tr(),
      isDestructive: true,
    );
    if ((confirmed ?? false) && context.mounted) {
      await context.read<SettingsProvider>().logout();
    }
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15.sp,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 13.sp,
        ),
      ),
      trailing: selected
          ? Icon(
              Icons.check_circle_rounded,
              color: cs.primary,
              size: 22.r,
            )
          : null,
    );
  }
}
