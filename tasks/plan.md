# Implementation Plan: Close API Gaps

Specs: [SPEC-map.md](../SPEC-map.md) (index) · [SPEC-common.md](../SPEC-common.md) (conventions, UX rules, boundaries). Task checklist: [todo.md](todo.md). Previous plan: [archive/](archive/).

## Overview
Wire the 9 unused backend endpoints into the Flutter app with complete, role-aware UI. Also add two backend changes: an Algerian `phone` on the user, and a password-guarded `DELETE /me`. Work proceeds in 4 phases, with a human checkpoint after each.

## Architecture Decisions
- **Vertical slices.** Each task delivers a working path (service → repo → provider → UI → tests) or a self-contained foundation piece. Each task leaves the app building and the tests green.
- **Backend first where it carries risk.** Both backend changes (`T1`, `T2`) land in Phase 1. The `DELETE /me` contract change is the riskiest item and nothing depends on its app side yet, so doing it early fails fast.
- **Two repos, two branches.** App: `feat/api-gaps` (exists). Backend: `feat/phone-and-delete-guard`, cut from backend `main`. Commit only our own files; the backend WIP (`cmd/api/main.go`, `go.mod`, `deploy/loadtest/*`, `internal/observability/dbpool*`) stays untouched.
- **Shared forms through extraction, not duplication.** `WeddingForm` and `GuestForm` are pulled out of the existing create screens in their own refactor tasks, with tests, before the edit screens use them. Create behaviour must not change.
- **Phone format.** Local Algerian `0XXXXXXXXX` everywhere. The normaliser rules are identical on the backend (Go) and in the app (Dart), and table-driven tests share the same cases.
- **Session is the source of truth for the user.** Every `/me` write returns `AppUser` and goes through `SessionProvider.updateUser`.
- **Optimistic updates only for reversible toggles and role changes.** Everything else waits for the server.

## Dependency Graph
```
T1 backend phone ─┐
T3 phone utils ───┼─> T4 AppPhoneField ─┬─> T6 edit-profile sheet
                  │                     └─> T13 EditGuestScreen
                  └─> T5 guest contact actions
T7 user data layer (phone, updateProfile/Settings) ─> T6, T8 notif toggles
T9 wedding data + refresh ─> T10 cold-load route ─> T11 edit wedding ─> T16 transfer
T12 guest update data + GuestForm extract ─> T13
T14 role change, T15 revoke link (independent, Phase 3)
T2 backend delete guard ─> T17 app delete data ─> T18 delete flow UI (also needs T16)
```

## Task List (detail)

### Phase 1: Foundation (backend + phone primitives)

**T1: Backend — user phone field.** Migration `000009_user_phone` adds `users.phone varchar(10)`. Add `Phone` to the model. Drop `email` from `UserResponse`. `UpdateMeRequest.Phone` is normalised and validated in `internal/validation/phone.go`, and `""` clears it.
- Accept: `PATCH /me {"phone":"+213 672 85 99 65"}` → stored `0672859965`. `0812345678` → 400. `""` → null. `GET /me` has no `email`.
- Verify: `go test ./internal/validation -race`; `TEST_DATABASE_URL=… go test ./test -run 'TestSettings|TestMe' -race`; `make lint`; `make docs`.
- Files: `internal/database/migrations/000009_user_phone.{up,down}.sql`, `internal/models/user.go`, `internal/dto/auth.go`, `internal/service/auth.go`, `internal/validation/phone.go`(+`_test`), `test/settings_test.go`. **M** (the migration pair counts as one file).

**T2: Backend — `DELETE /me` requires a password.** Add `dto.DeleteAccountRequest{Password}`. The service verifies the password and calls the existing `registerFailure` on a mismatch (shared lockout). 423 when locked.
- Accept: no body → 400. Wrong password → 401 and the attempt counter goes up. Correct password → 200, and the user plus owned weddings are gone.
- Verify: `go test ./test -run TestDeleteAccount -race`; `make docs`.
- Files: `internal/dto/auth.go`, `internal/service/auth.go`, `internal/handler/auth.go`, `test/auth_test.go`, `docs/swagger/*`. **M**

**T3: App — phone utils.** `lib/src/utils/phone.dart`: `normalizePhone`, `formatPhone`, `telUri`, `whatsappUri`.
- Accept: the same table cases as T1 pass. Formatting gives `0672 85 99 65` and `021 23 45 67`. WhatsApp → `https://wa.me/213672859965`.
- Verify: `flutter test test/unit/phone_test.dart`.
- Files: `lib/src/utils/phone.dart`, `test/unit/phone_test.dart`. **S**

**T4: App — `AppPhoneField`.** Shared widget: LTR inside RTL, phone keyboard, autofill hint, digit formatter, inline validation, emits the canonical value. Adds `common.phone_*` strings.
- Accept: the widget test accepts `0672 85 99 65` → `0672859965`, shows an inline error for `123`, and treats empty as valid.
- Verify: `flutter test test/widget/app_phone_field_test.dart`; `flutter analyze`.
- Files: `lib/src/shared/widgets/app_phone_field.dart`, `widgets.dart` (export), `assets/translations/{ar,en,fr}.json`, `locale_keys.g.dart`, test. **M**

**T5: App — guest contact actions.** On guest detail, tapping a phone contact opens a sheet with Call / WhatsApp / Copy. Non-phone contacts stay plain text.
- Accept: the widget test shows the sheet for `0672859965` and no sheet for `ali@x.dz`. The numbers render LTR.
- Verify: `flutter test test/widget/guest_detail_screen_test.dart`.
- Files: `lib/src/ui/weddings/guest_detail_screen.dart`, `lib/src/ui/weddings/widgets/contact_actions_sheet.dart`, translations, test. **M**

**Checkpoint 1:** backend `make test` + integration tests green; app `flutter analyze` + `flutter test` green. Manual: `curl` `PATCH /me` with a phone against the local API. Human review.

### Phase 2: Core edits (profile, wedding, guest)

**T7: App — user data layer.** `AppUser.phone`. `AuthService.updateProfile({displayName?, phone?})` diff body. `AuthRepository.updateProfile` / `updateSettings` pass-throughs.
- Accept: `user_model_test` parses `phone`. The service only sends non-null keys.
- Files: `user_model.dart`, `auth_service.dart`, `auth_repository{,_impl}.dart`, `test/unit/user_model_test.dart`. **M**

**T6: App — Edit profile sheet.** Bottom sheet with name + `AppPhoneField`, dirty-gated Save, diff payload, session update, and the phone line on `ProfileCard`. Removes the "coming soon" toast.
- Accept: SPEC-account-profile criteria 1–2 and the provider unit test (dirty, diff, failure keeps input).
- Files: `settings/widgets/edit_profile_sheet.dart`, `settings/providers/settings_provider.dart`, `settings_screen.dart`, `widgets/profile_card.dart`, tests (+ strings). **M**
- Deps: T4, T7.

**T8: App — notification preferences.** "Notifications" section with Push + RSVP switches. Optimistic with rollback; RSVP is disabled while Push is off.
- Accept: SPEC-account-profile criteria 3–4, unit test for rollback.
- Files: `settings_provider.dart`, `settings_screen.dart`, translations, `test/unit/settings_provider_test.dart`. **S–M**
- Deps: T7.

**T9: App — wedding get/update data + `WeddingsProvider.refresh`.** New `WeddingService.get`/`update` (diff body) and repository methods. `refresh(id)` replaces, inserts, or removes on a 404.
- Accept: unit tests for replace / insert / 404-remove.
- Files: `wedding_service.dart`, `wedding_repository{,_impl}.dart`, `weddings_provider.dart`, `test/unit/weddings_provider_test.dart`. **M**

**T10: App — cold-load wedding route.** The `/weddings/:id` screen falls back to `refresh(id)` when the wedding is missing from the list. It shows a loading state, then content or a not-found state.
- Accept: a widget/unit test where the empty list plus `get` success renders the wedding and a 404 renders not-found. A notification tap on an uncached wedding works.
- Files: `guest_list_screen.dart` (wedding screen), `app_router.dart` (if the builder reads the provider), test. **S–M**
- Deps: T9. ⚠ touches `app_router.dart` (see Open Question 1).

**T11: App — edit wedding.** Extract `WeddingForm` from `CreateWeddingScreen` (no behaviour change), then build the `/weddings/:id/edit` screen and an owner-only "Edit" overflow item. Dirty-gated, diff, discard confirm.
- Accept: the create flow tests still pass; SPEC-wedding-manage criteria 2–4.
- Files: `weddings/widgets/wedding_form.dart`, `create_wedding_screen.dart`, `edit_wedding_screen.dart`, `providers/edit_wedding_provider.dart`, `app_routes.dart`/`app_router.dart`, `guest_list_screen.dart` + tests. **L → split into T11a (extract form + keep create green) and T11b (edit screen + route + menu).**
- Deps: T9.

**T12: App — guest update data + `GuestForm` extraction.** New `GuestService.update`/repository `update` (diff body) and `GuestsProvider.replace(guest)`. Extract `GuestForm` from `AddGuestScreen` with create mode unchanged, and switch its contact field to `AppPhoneField`.
- Accept: the `add_guest_provider_test` stays green; a new unit test covers the diff and the in-place list replace.
- Files: `guest_service.dart`, `guest_repository{,_impl}.dart`, `guests_provider.dart`, `weddings/widgets/guest_form.dart`, `add_guest_screen.dart`, tests. **L → split T12a (data + replace) / T12b (form extract).**
- Deps: T4.

**T13: App — EditGuestScreen.** Edit action (editor+) on guest detail opens `/weddings/:id/guests/:gid/edit`, prefilled. Dirty-gated, diff, discard confirm. On success: reload detail and replace the list row. Legacy non-phone contacts are kept.
- Accept: SPEC-guest-edit criteria.
- Files: `edit_guest_screen.dart`, `providers/edit_guest_provider.dart`, `guest_detail_screen.dart`, routes, tests. **M**
- Deps: T12.

**Checkpoint 2:** analyze + full test suite green. Manual in the simulator (ar + en): edit the profile, toggle notifications, edit a wedding as owner (not visible as editor), edit a guest and confirm the list updates. Human review.

### Phase 3: Collaboration admin

**T14: App — change member role.** Member tile overflow menu (owner only, not on their own tile) → role sheet with descriptions. `ShareProvider.setRole` is optimistic with rollback.
- Files: `share_screen.dart`, `share/widgets/member_actions.dart` (+role sheet), `share_provider.dart`, `test/unit/share_provider_test.dart`, widget test. **M**

**T15: App — revoke invite link.** List of active links with a Revoke action and confirm dialog. A 404 counts as success; the shown QR clears when its link is revoked.
- Files: `share_screen.dart`, `share/widgets/invite_link_tile.dart`, `share_provider.dart`, tests, strings. **M**

**T16: App — transfer ownership.** `WeddingService.transferOwnership` + repository. "Make owner" in the member menu → confirm dialog with the demotion copy → `POST`, then `WeddingsProvider.refresh` and a members reload. Owner controls disappear.
- Accept: SPEC-collab-admin criterion 2 (no owner controls anywhere afterwards).
- Files: `wedding_service.dart`, `wedding_repository{,_impl}.dart`, `share_provider.dart`, `member_actions.dart`, tests. **M**
- Deps: T9, T14.

**Checkpoint 3:** tests green. Manual with 2 accounts: role change reflects for the other user; revoked link → the preview fails; after transfer the former owner sees editor UI. Human review.

### Phase 4: Account deletion

**T17: App — delete data + session teardown.** `AuthService.deleteAccount(password)` sends the body. `SessionProvider.deleteAccount` does a best-effort device unregister, clears tokens, and sets the session to unauthenticated (reusing the `signOut` teardown).
- Accept: unit tests for success → tokens cleared and signed out; 401/423 → stay signed in and return the mapped failure.
- Files: `auth_service.dart`, `auth_repository{,_impl}.dart`, `session_provider.dart`, test. **M**
- Deps: T2.

**T18: App — delete account flow UI.** Settings "Danger zone" row → `/settings/delete-account` impact screen (owned weddings with guest and collaborator counts, Transfer shortcut, shared-weddings count) → password step with a gated destructive button. Inline 401 error, lockout message, and a redirect to login after success.
- Accept: SPEC-account-delete criteria 2–4.
- Files: `settings/delete_account_screen.dart`, `settings/providers/delete_account_provider.dart`, `settings_screen.dart`, routes, tests (+ strings). **M–L** (split the impact step and password step if it grows past 5 files).
- Deps: T16, T17.

**Checkpoint 4 (complete):** full backend + app suites green, `flutter analyze` clean, all SPEC success criteria ticked. Manual: delete a test account that owns a shared wedding (after a transfer) and confirm the collaborator still has it. Update `docs/UNIMPLEMENTED_ENDPOINTS.md` → all covered. Run `graphify update .` in both repos. Ready for `/review`.

## Risks and Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Uncommitted router WIP (`isPublic ? onboarding : onboarding`) breaks invite deep links and collides with T10/T11/T13/T18 | High | Resolve Open Question 1 before T10. Stage hunks selectively (`git add -p`) until then |
| Form extraction (T11a/T12b) regresses the create flows | Med | Extraction tasks are separate from the edit tasks; existing provider and widget tests must stay green before moving on |
| `DELETE /me` contract change while an old app build is installed | Low | No shipped client calls `DELETE /me` today, so nothing breaks |
| Dart and Go phone rules drift apart | Med | The same table of cases in `phone_test.dart` and `phone_test.go`; a comment in each points to the other |
| Backend WIP on `main` (`go.mod`, `main.go`) gets committed by accident | Med | Branch first; `git add` explicit paths only |
| RTL layout breaks on new sheets/menus at 1.3× text | Low | Each widget test pumps with `ar` + `textScaler 1.3` |
| Flaky concurrent `flutter test` | Low | Already guarded by `dart_test.yaml concurrency:1` |

## Parallelization
After Checkpoint 1, the T6–T8 (profile), T9–T11 (wedding) and T12–T13 (guest) tracks touch disjoint files except `app_routes.dart`/`app_router.dart` and the translation JSON. They are safe to run in parallel if those shared files are merged carefully. Default: sequential, single session.

## Open Questions
1. **Router WIP:** is the `app_router.dart` change (`isPublic ? AppRoutes.onboarding : AppRoutes.onboarding`) intentional? It redirects public routes, including invite deep links, to onboarding until onboarding completes. Revert it, commit it, or leave it unstaged?
2. Spec defaults still stand unless you say otherwise: keep the `users.email` column; phone not unique; delete-account shares the login lockout counter.
