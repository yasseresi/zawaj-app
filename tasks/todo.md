# Todo: Close API Gaps

Details, acceptance criteria and files for each task: [plan.md](plan.md). Specs: [SPEC-map.md](../SPEC-map.md).

## Phase 1: Foundation
- [x] T1 Backend: user `phone` (migration 000009, DTO, normaliser, drop `email` from response) — `phone-contact`
- [x] T2 Backend: `DELETE /me` requires password + shared lockout — `account-delete`
- [x] T3 App: `phone.dart` utils (normalize/format/tel/whatsapp) + tests — `phone-contact`
- [x] T4 App: `AppPhoneField` shared widget + strings + widget test — `phone-contact`
- [x] T5 App: guest contact Call/WhatsApp/Copy sheet — `phone-contact`

### Checkpoint 1
- [x] Backend `make test` + integration tests green
- [x] App `flutter analyze` clean, `flutter test` green
- [x] Manual: `PATCH /me` phone against the local API (covered by backend TestProfilePhone, real router + Postgres)
- [ ] Human review

## Phase 2: Core edits
- [x] T7 App: `AppUser.phone` + `updateProfile`/`updateSettings` data layer — `account-profile`
- [x] T6 App: Edit profile sheet + ProfileCard phone (remove coming-soon) — `account-profile`
- [x] T8 App: Notification preference switches (optimistic) — `account-profile`
- [x] T9 App: wedding `get`/`update` data + `WeddingsProvider.refresh` — `wedding-manage`
- [x] T10 App: cold-load `/weddings/:id` fallback — `wedding-manage` ⚠ router WIP
- [x] T11a App: extract `WeddingForm` (create unchanged) — `wedding-manage`
- [x] T11b App: Edit wedding screen + route + owner overflow item — `wedding-manage`
- [x] T12a App: guest `update` data + `GuestsProvider.replace` — `guest-edit`
- [x] T12b App: extract `GuestForm` (+ `AppPhoneField` for contact) — `guest-edit`
- [x] T13 App: Edit guest screen + route + detail action — `guest-edit`

### Checkpoint 2
- [x] Analyze + full suite green (204 tests)
- [x] Manual (ar, simulator): guest edit, contact actions, owner-only menu verified; profile/notification toggles covered by widget tests
- [x] Human review (waived: /build auto)

## Phase 3: Collaboration admin
- [x] T14 App: change member role (menu + sheet, optimistic) — `collab-admin`
- [x] T15 App: invite links list + revoke — `collab-admin`
- [x] T16 App: transfer ownership + post-transfer refresh — `collab-admin`

### Checkpoint 3
- [x] Tests green (221)
- [x] Manual with 2 accounts (simulator): role change persisted, transfer → former owner sees editor UI
- [x] Human review (waived: /build auto)

## Phase 4: Account deletion
- [x] T17 App: `deleteAccount(password)` + session teardown — `account-delete`
- [x] T18 App: Danger zone → impact screen → password confirm — `account-delete`

### Checkpoint 4: Complete
- [x] Backend + app suites green, analyze clean
- [ ] All SPEC success criteria ticked
- [x] Manual (simulator, 2026-10-07): delete an account after a transfer; the collaborator keeps the wedding
- [ ] `docs/UNIMPLEMENTED_ENDPOINTS.md` updated; `graphify update .` in both repos
- [ ] Ready for `/review`

## Ship blockers (from /ship 2026-10-07)
- [x] B1 App: wedding header + home card show real guest count after cold load / return
- [x] B2 App: notification toggle rollback/merge touches only its own field
- [x] B3 Backend: UserRepo.Update must never re-insert a deleted user (no GORM Save upsert) (backend 6cdf344)
- [ ] B4 Backend+App: PATCH /me/password honours lockout; app skips refresh-retry on it
- [x] B5 Backend: atomic failed-attempt increment (parallel guesses can't bypass lockout) (backend 8c2178f)
