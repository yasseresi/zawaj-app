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
- [x] B4 Backend+App: PATCH /me/password honours lockout; app skips refresh-retry on it (backend 50921dc)
- [x] B5 Backend: atomic failed-attempt increment (parallel guesses can't bypass lockout) (backend 8c2178f)
- [x] B6 Backend: user writes are column-scoped (a stale/overlapping write can't revert password, profile or prefs) (backend 7bbfd6f)
- [x] B7 Backend: accepting an invite link never changes an existing membership (no re-escalation after demote/remove) (backend df8a7d9)
  - [x] ~~B7a App: revoke-links prompt after removal~~ (superseded by C1/C2: server-enforced)
- [x] R1 App: wedding header keeps the last known guest total across reloads/failures
- [x] ~~B8 App: revoke-editor-links prompt after demotion~~ (superseded by C1/C2; backend guard test d633247 kept)
- [x] C1 Backend: membership ceilings — links capped at the owner's last role decision; owner-removed users refused (403 removed_from_wedding); owner username invite after the decision supersedes it (backend 2f65a81)
- [x] C2 App: drop the revoke-links prompts; localized message for removed_from_wedding on link/invite accept
- [x] D1 Backend: owner re-invite records its role as the new ceiling (was cleared → viewer re-invite could leave + rejoin as editor) (backend 905b3ab)
- [x] D2 Backend: owner removal withdraws pending username invites (stale invite blocked re-invite with 409) (backend 3fcc2c4)
- [x] D3 Backend+App: option (b) — memberships record via_link_id; owner removal / demotion below it revokes that link (second-account reuse); app re-fetches links, remove copy updated (backend 71e4ecd)

## Join approval (SPEC-join-approval.md) — approved 2026-10-08; J1–J3 backend 64e6010
- [x] J1 Backend: migration 000012 join_requests + model + repo; link accept → 202 pending request (member → 200, removed → 403); owner notified (join_requested)
- [x] J2 Backend: owner list / approve (role ≤ requested; membership + ceiling + via_link_id; join_approved) / decline (join_declined); cascades on wedding/account delete; Swagger + ADR
- [x] J3 Backend: drop D3 auto-revoke on removal/demotion (links stay active); update tests
- [x] J4 App: data layer — acceptInviteLink returns member|pending; join-request list/approve/decline in WeddingService/Repository
- [x] J5 App: invite preview "Request sent" state; share screen Join requests section (approve sheet w/ role, decline confirm, optimistic + rollback); revert remove-confirm copy
- [x] J6 App: notification taps for join_requested (→ share) / join_approved (→ wedding) / join_declined (no nav); API smoke on a fresh SQL-migrated DB passed 17/17. Simulator walkthrough NOT done (needs app pointed at a server with this backend)


## Join approval — ship round fixes (approved 2026-10-08)
- [x] K1 Backend: CreatePending ON CONFLICT predicate as SQL literal (generic-plan 500 every ~6th accept); parallel test asserts codes; single-conn repeat test
- [x] K2 Backend: close pending requests on owner removal + username-invite join; Approve re-checks ceiling under lock (removed → 403), already-member → close quietly; list hides members
- [x] K3 Backend: revoke link closes its pending requests; cap 50 pending/wedding (429 join_queue_full, per-wedding lock); owner push skipped while an unread join_requested exists
- [x] K4 Backend tests: close test DB pools; gated 20-goroutine parallel tests; partial-index assertion; row-lock test; cooldown expiry; notification data; audit rows; approve validation; AutoMigrate index parity
- [x] K5 App: role sheet explicit selection (approve as editor); request age; preview copy/progress/localized load errors; characters.first; RTL-isolated @username; _decide try/finally; share screen widget tests
- [x] K6 App: join_queue_full localized on preview
- [x] K7 App: 401 refresh interceptor tests (refresh+retry, single-flight, logout on failure, skipAuthRefresh)
- [x] K8 Backend: lockout lifecycle tests (expiry, reset on success)
- [x] K9 Backend: deterministic sync instead of RSVP 500ms wait and the 20ms sleep
- [x] K10 Backend: WeddingRepo.Update column-scoped (no stale owner_id write-back)
- [x] K11 App: invite token format validation + URL-encoding in WeddingService

## Ship round 6 fixes (2026-10-09)
- [x] L1 Backend: resetSchema refuses DBs not named *_test
- [x] L2 Backend: wait (bounded) for in-flight pushes on shutdown
- [x] L3 Backend: request log uses route template (no invite tokens)
- [x] L4 Backend: re-push owner when oldest pending request >24h old
- [x] L5 Backend: Swagger note — approve 403 removed still closes request
- [x] L6 App: _decide marks settled before onSuccess
- [x] L7 App: pendingInviteToken stores canonical token
- [x] L8 App: plural time strings (ar/en/fr)
- [x] L9 App: role picker icon excluded from semantics
