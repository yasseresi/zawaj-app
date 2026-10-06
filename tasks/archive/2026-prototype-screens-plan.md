# Feature Implementation Plan: Remaining Prototype Screens & Navigation Shell

## Overview
Implement the remaining screens from the Arabic React prototype (`زواج/`) into `zawaj_app` matching the design specs, theme, and RTL/multilingual support:
1. **Screen 8: Guest Analytics & Reminders (`AnalyticsScreen`)**
2. **Screen 9: Activity Log (`ActivityLogScreen`)**
3. **Screen 10: Pending Invites (`PendingInvitesScreen`)**
4. **Screen 11: Settings & Profile (`SettingsScreen`)**
5. **App Navigation Shell (`BottomNav` / Router integration)**

---

## Architectural Principles & Conventions
- **Clean Architecture & MVVM**: `Screen` (View) + `ChangeNotifierProvider` (ViewModel) + `Repository` (Data layer).
- **Exact Prototype Match**: Match colors (`--d-surface`, `--primary`, `--secondary`), typography (Serif titles), spacing, and dark/light modes as specified in `زواج/screens-2.jsx` and `screens-3.jsx`.
- **Localization**: All strings extracted to `assets/translations/ar.json`, `en.json`, `fr.json` using `.tr()`.
- **Theme & Language**: Integrated in `SettingsScreen` (Light/Dark mode + Arabic/English/French switcher).

---

## Subagent Work Breakdown (Parallel Streams)

### Stream 1: Analytics Screen & Charts (`lib/src/ui/analytics/`)
- **Files**:
  - `lib/src/ui/analytics/analytics_screen.dart`
  - `lib/src/ui/analytics/providers/analytics_provider.dart`
  - `lib/src/ui/analytics/widgets/donut_chart_widget.dart`
  - `lib/src/ui/analytics/widgets/timeline_chart_widget.dart`
  - `lib/src/ui/analytics/widgets/broadcast_sheet.dart`
  - `test/unit/analytics_provider_test.dart`
  - `test/widget/analytics_screen_test.dart`
- **Acceptance Criteria**:
  - Stat cards (Total Guests, Pending Responses).
  - Custom Donut chart rendering Confirmed, Declined, Pending ratios.
  - RSVP timeline chart showing response trajectory.
  - Broadcast reminder modal sheet with confirmation state.
  - Dark mode design matching `screens-2.jsx`.

### Stream 2: Activity Log Screen (`lib/src/ui/activity/`)
- **Files**:
  - `lib/src/ui/activity/activity_log_screen.dart`
  - `lib/src/ui/activity/providers/activity_log_provider.dart`
  - `lib/src/ui/activity/widgets/activity_item_tile.dart`
  - `test/unit/activity_log_provider_test.dart`
  - `test/widget/activity_log_screen_test.dart`
- **Acceptance Criteria**:
  - Day-grouped timeline ("اليوم", "أمس", "هذا الأسبوع").
  - Action-specific icons and background pill colors.
  - Filter modal sheet (filter by activity action/user).
  - Empty and loading skeleton states.

### Stream 3: Pending Invites Screen (`lib/src/ui/invites/`)
- **Files**:
  - `lib/src/ui/invites/pending_invites_screen.dart`
  - `lib/src/ui/invites/providers/pending_invites_provider.dart`
  - `lib/src/ui/invites/widgets/invite_card.dart`
  - `test/unit/pending_invites_provider_test.dart`
  - `test/widget/pending_invites_screen_test.dart`
- **Acceptance Criteria**:
  - List of wedding co-host / partner invites with sender avatar, event title, and date.
  - Accept and Decline action buttons.
  - Decline confirmation dialog & success toast notification.
  - Empty state when no invites pending.

### Stream 4: Settings & Profile Screen (`lib/src/ui/settings/`)
- **Files**:
  - `lib/src/ui/settings/settings_screen.dart`
  - `lib/src/ui/settings/providers/settings_provider.dart`
  - `lib/src/ui/settings/widgets/profile_card.dart`
  - `lib/src/ui/settings/widgets/settings_section.dart`
  - `test/unit/settings_provider_test.dart`
  - `test/widget/settings_screen_test.dart`
- **Acceptance Criteria**:
  - Profile card header with avatar, name, email, and subscription badge.
  - Language selection (Arabic, English, French) with immediate locale update.
  - Theme mode toggle (Light / Dark).
  - Logout action with confirmation dialog.

### Stream 5: Navigation Shell & Routing Integration (`lib/src/routing/`)
- **Files**:
  - `lib/src/ui/shell/main_navigation_shell.dart`
  - `lib/src/routing/app_router.dart`
  - `lib/src/routing/app_routes.dart`
- **Acceptance Criteria**:
  - Bottom navigation bar with 4 tabs: Home (Lists), Analytics, Activity, Settings.
  - StatefulShellRoute in GoRouter for persistent navigation state across tabs.

---

## Checkpoints & Verification Steps
1. **Checkpoint 1**: All 4 screen feature modules implemented independently via parallel subagents.
2. **Checkpoint 2**: GoRouter updated to mount `MainNavigationShell` with all 4 tab destinations.
3. **Checkpoint 3**: Run `flutter analyze` and `flutter test` across all unit and widget tests.
