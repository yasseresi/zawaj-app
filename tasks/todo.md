# Task List: Zawaj App Prototype Completion

## Stream 1: Analytics Screen (Screen 8)
- [ ] Implement `AnalyticsProvider` and state models (`lib/src/ui/analytics/providers/analytics_provider.dart`) [Priority: High]
- [ ] Implement custom Donut Chart & Legend widgets (`lib/src/ui/analytics/widgets/donut_chart_widget.dart`) [Priority: High]
- [ ] Implement RSVP Timeline Chart widget (`lib/src/ui/analytics/widgets/timeline_chart_widget.dart`) [Priority: Medium]
- [ ] Implement `AnalyticsScreen` view matching prototype dark mode (`lib/src/ui/analytics/analytics_screen.dart`) [Priority: High]
- [ ] Write unit & widget tests for `AnalyticsScreen` [Priority: High]

## Stream 2: Activity Log Screen (Screen 9)
- [ ] Implement `ActivityLogProvider` (`lib/src/ui/activity/providers/activity_log_provider.dart`) [Priority: High]
- [ ] Implement `ActivityItemTile` & `DayGroup` widgets (`lib/src/ui/activity/widgets/activity_item_tile.dart`) [Priority: High]
- [ ] Implement `ActivityLogScreen` view (`lib/src/ui/activity/activity_log_screen.dart`) [Priority: High]
- [ ] Write unit & widget tests for `ActivityLogScreen` [Priority: High]

## Stream 3: Pending Invites Screen (Screen 10)
- [ ] Implement `PendingInvitesProvider` (`lib/src/ui/invites/providers/pending_invites_provider.dart`) [Priority: High]
- [ ] Implement `InviteCard` widget with Accept/Decline actions (`lib/src/ui/invites/widgets/invite_card.dart`) [Priority: High]
- [ ] Implement `PendingInvitesScreen` view with decline dialog & toasts (`lib/src/ui/invites/pending_invites_screen.dart`) [Priority: High]
- [ ] Write unit & widget tests for `PendingInvitesScreen` [Priority: High]

## Stream 4: Settings & Profile Screen (Screen 11)
- [ ] Implement `SettingsProvider` supporting Theme & Locale changes (`lib/src/ui/settings/providers/settings_provider.dart`) [Priority: High]
- [ ] Implement `ProfileCard` & `SettingsSection` widgets (`lib/src/ui/settings/widgets/profile_card.dart`) [Priority: High]
- [ ] Implement `SettingsScreen` view (`lib/src/ui/settings/settings_screen.dart`) [Priority: High]
- [ ] Write unit & widget tests for `SettingsScreen` [Priority: High]

## Stream 5: App Navigation Shell & Integration
- [ ] Implement `MainNavigationShell` with bottom navigation bar (`lib/src/ui/shell/main_navigation_shell.dart`) [Priority: High]
- [ ] Update `AppRouter` and `AppRoutes` to mount shell routes (`lib/src/routing/app_router.dart`) [Priority: High]
- [ ] Run full test suite & static analysis verification (`flutter analyze && flutter test`) [Priority: High]
