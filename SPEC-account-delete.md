# Spec: account-delete

Conventions: [SPEC-common.md](SPEC-common.md) · Map: [SPEC-map.md](SPEC-map.md) · Depends on: `collab-admin`

## Objective
Let users permanently delete their account from inside the app (an App Store / Play requirement) without letting them, or someone holding their unlocked phone, wipe weddings that collaborators depend on by accident.

## Backend (../backend)
- `DELETE /me` now requires the JSON body `{"password": "..."}` (new `dto.DeleteAccountRequest`, `binding:"required"`).
- `AuthService.DeleteAccount(ctx, userID, password)`: verify with `auth.VerifySecret`. A wrong password → `apperr.Unauthenticated("password is incorrect")` (401), and it counts toward the existing login-lockout counter, so the endpoint can't be used to brute-force the password. If locked → 423.
- Update the godoc, run `make docs`, and add an integration test for: missing body → 400, wrong password → 401, correct password → 200 and the user plus owned weddings are gone.
- Breaking change: the app ships in the same release, and no other client exists.

## App UX
- Settings → a new **"Danger zone"** section at the bottom, below Logout, with a red text row: "Delete account".
- **Step 1, impact screen** (full-screen route `/settings/delete-account`):
  - Lists what will be deleted. If the user **owns** weddings (from `WeddingsProvider`, `role == owner`), each one is listed with its guest count and collaborator count, plus the warning: "These weddings and all their guests will be deleted for every collaborator."
  - For each owned wedding that has other members: a **"Transfer ownership"** button that deep-links to that wedding's share screen (`collab-admin`). The list updates when the user returns.
  - Weddings the user only collaborates on: "You'll be removed from N shared weddings."
  - A "Continue" button.
- **Step 2, confirm:** a password field (obscured, with a show toggle) and a destructive button "Delete my account permanently". The button is disabled until a password is entered and shows a spinner while the request runs.
- On success: unregister the push device (best effort), clear the tokens and session, go to onboarding/login, and show a toast "Account deleted".
- On 401: an inline error under the password field; the field keeps focus. On 423: the lockout message.

## Code
- `AuthService.deleteAccount({required String password})` sends the body (`ApiClient.delete` supports `data`).
- `AuthRepository.deleteAccount`. `SessionProvider.deleteAccount(password)` reuses the logout teardown.
- `DeleteAccountProvider` (impact summary + submit state).

## Success Criteria
- [ ] Without the correct password the account is never deleted (server-enforced, integration-tested).
- [ ] A user who owns a shared wedding sees it listed with a working Transfer shortcut before they can continue.
- [ ] After deletion: no tokens in secure storage, the device token is unregistered, the app is on the login/onboarding screen, and Back can't return to the authenticated screens.
- [ ] Unit tests: impact summary (owned vs shared), submit success/401/423 handling. Widget test: button gating, inline 401 error.

## Open Questions
1. Should a wrong password here count toward the *login* lockout (shared counter) or have its own? Default: shared, because it's simpler and still blocks brute force.
