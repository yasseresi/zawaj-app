# Spec: account-profile

Conventions: [SPEC-common.md](SPEC-common.md) · Map: [SPEC-map.md](SPEC-map.md) · Depends on: `phone-contact`

## Objective
Let a signed-in user edit their display name and phone, and control which notifications they receive. Today the Settings → "Edit profile" row shows a "coming soon" toast, and there are no notification preferences.

## Endpoints
- `PATCH /me` `{display_name?, phone?}` → updated `AppUser` (`AuthService.updateProfile`, extended with `phone`).
- `PATCH /me/settings` `{notif_push?, notif_rsvp?}` → updated `AppUser` (`AuthService.updateSettings`, already exists).

## UX
- **Edit profile** (Settings → Account → Edit profile) opens a bottom sheet (2 fields):
  - Display name: required, 1–80 characters, trimmed.
  - Phone: `AppPhoneField`, optional.
  - Save stays disabled until a field changes and the form is valid. Only changed fields are sent. On success the sheet closes, a toast appears, and `SessionProvider.user` updates, which refreshes `ProfileCard`.
  - On failure the sheet stays open with the input kept and a toast shows the reason.
- **ProfileCard** shows the formatted phone under the username when set.
- **New section "Notifications"** between Appearance and Collaboration, with two `SwitchListTile.adaptive`s:
  - "Push notifications" → `notif_push`
  - "RSVP updates" → `notif_rsvp`. Its subtitle reads "When a guest's status changes". It is disabled while push is off, because RSVP alerts arrive by push.
  - Toggles are optimistic: they flip immediately. On failure they revert and a toast appears. A toggle is debounced: while its request is in flight, further taps are ignored.
- Email and email-notification options are not shown.

## Code
- `SettingsProvider` (or a new `ProfileProvider`): `updateProfile({displayName, phone})` and `setNotifPush(bool)` / `setNotifRsvp(bool)`. Each pushes the returned user into `SessionProvider`.
- `AuthRepository`: add `updateProfile` and `updateSettings` pass-throughs.
- New widget `lib/src/ui/settings/widgets/edit_profile_sheet.dart`.

## Success Criteria
- [ ] Editing the name only sends `{display_name}`, and ProfileCard updates without an app restart.
- [ ] Clearing the phone sends `{phone: ""}`, and the phone line disappears from ProfileCard.
- [ ] A failed toggle reverts and toasts. A successful toggle survives a cold start (it reads back from `GET /me`).
- [ ] The RSVP switch is disabled while push is off.
- [ ] Unit tests: dirty tracking, diff payload, optimistic rollback. Widget test: Save enabled/disabled, validation.
- [ ] The "coming soon" toast for Edit profile is removed.
