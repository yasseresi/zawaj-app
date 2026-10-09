# Task List: Zawaj App Prototype Completion

## Stream 1: Analytics Screen (Screen 8)
- [x] Implement `AnalyticsProvider` and state models (`lib/src/ui/analytics/providers/analytics_provider.dart`) [Priority: High]
- [x] Implement custom Donut Chart & Legend widgets (`lib/src/ui/analytics/widgets/donut_chart_widget.dart`) [Priority: High]
- [x] Implement RSVP Timeline Chart widget (`lib/src/ui/analytics/widgets/timeline_chart_widget.dart`) [Priority: Medium] — shipped as guest_capacity_chart_widget.dart
- [x] Implement `AnalyticsScreen` view matching prototype dark mode (`lib/src/ui/analytics/analytics_screen.dart`) [Priority: High]
- [x] Write unit & widget tests for `AnalyticsScreen` [Priority: High]

## Stream 2: Activity Log Screen (Screen 9)
- [x] Implement `ActivityLogProvider` (`lib/src/ui/activity/providers/activity_log_provider.dart`) [Priority: High]
- [x] Implement `ActivityItemTile` & `DayGroup` widgets (`lib/src/ui/activity/widgets/activity_item_tile.dart`) [Priority: High]
- [x] Implement `ActivityLogScreen` view (`lib/src/ui/activity/activity_log_screen.dart`) [Priority: High]
- [x] Write unit & widget tests for `ActivityLogScreen` [Priority: High]

## Stream 3: Pending Invites Screen (Screen 10)
- [x] Implement `PendingInvitesProvider` (`lib/src/ui/invites/providers/pending_invites_provider.dart`) [Priority: High]
- [x] Implement `InviteCard` widget with Accept/Decline actions (`lib/src/ui/invites/widgets/invite_card.dart`) [Priority: High]
- [x] Implement `PendingInvitesScreen` view with decline dialog & toasts (`lib/src/ui/invites/pending_invites_screen.dart`) [Priority: High]
- [x] Write unit & widget tests for `PendingInvitesScreen` [Priority: High]

## Stream 4: Settings & Profile Screen (Screen 11)
- [x] Implement `SettingsProvider` supporting Theme & Locale changes (`lib/src/ui/settings/providers/settings_provider.dart`) [Priority: High]
- [x] Implement `ProfileCard` & `SettingsSection` widgets (`lib/src/ui/settings/widgets/profile_card.dart`) [Priority: High]
- [x] Implement `SettingsScreen` view (`lib/src/ui/settings/settings_screen.dart`) [Priority: High]
- [x] Write unit & widget tests for `SettingsScreen` [Priority: High]

## Stream 5: App Navigation Shell & Integration
- [x] Implement `MainNavigationShell` with bottom navigation bar (`lib/src/ui/shell/main_navigation_shell.dart`) [Priority: High]
- [x] Update `AppRouter` and `AppRoutes` to mount shell routes (`lib/src/routing/app_router.dart`) [Priority: High]
- [x] Run full test suite & static analysis verification (`flutter analyze && flutter test`) [Priority: High]
