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
- [ ] T11a App: extract `WeddingForm` (create unchanged) — `wedding-manage`
- [ ] T11b App: Edit wedding screen + route + owner overflow item — `wedding-manage`
- [ ] T12a App: guest `update` data + `GuestsProvider.replace` — `guest-edit`
- [ ] T12b App: extract `GuestForm` (+ `AppPhoneField` for contact) — `guest-edit`
- [ ] T13 App: Edit guest screen + route + detail action — `guest-edit`

### Checkpoint 2
- [ ] Analyze + full suite green
- [ ] Manual (ar + en): profile edit, notification toggles, wedding edit (owner-only), guest edit updates the list
- [ ] Human review

## Phase 3: Collaboration admin
- [ ] T14 App: change member role (menu + sheet, optimistic) — `collab-admin`
- [ ] T15 App: invite links list + revoke — `collab-admin`
- [ ] T16 App: transfer ownership + post-transfer refresh — `collab-admin`

### Checkpoint 3
- [ ] Tests green
- [ ] Manual with 2 accounts: role change, revoked link fails, former owner sees editor UI
- [ ] Human review

## Phase 4: Account deletion
- [ ] T17 App: `deleteAccount(password)` + session teardown — `account-delete`
- [ ] T18 App: Danger zone → impact screen → password confirm — `account-delete`

### Checkpoint 4: Complete
- [ ] Backend + app suites green, analyze clean
- [ ] All SPEC success criteria ticked
- [ ] Manual: delete an account after a transfer; the collaborator keeps the wedding
- [ ] `docs/UNIMPLEMENTED_ENDPOINTS.md` updated; `graphify update .` in both repos
- [ ] Ready for `/review`
