# Spec: join-approval

Conventions: [SPEC-common.md](SPEC-common.md) · Map: [SPEC-map.md](SPEC-map.md) · Depends on: `collab-admin`

## Objective
Invite links are shareable (group chat, QR) and accounts are free, so a person the owner removed can come back through any live link with a second account, and the only way to stop one person using a shared link is to break it for everyone. From now on, joining by link needs the owner's approval: links stay shareable and never have to be revoked for one person, and every newcomer is seen and approved by the owner. Username invites, where the owner picks the exact account, still join directly. (Decided 2026-10-07.)

## Backend (../backend)
- **Migration 000012 `join_requests`**: `id`, `wedding_id`, `user_id`, `link_id`, `role` (the role the link grants), `status` (`pending` | `approved` | `declined`), `created_at`, `decided_at`, `decided_by`. At most one pending request per (wedding, user), enforced by a partial unique index.
- **`POST /invite/:token/accept`** (changed, breaking; the app ships in the same release):
  - Already a member: `200 {wedding_id, wedding_name, role, status:"member"}`, membership unchanged (as now).
  - Removed by the owner (ceiling `none`): `403 removed_from_wedding`, and no request is created (as now).
  - Otherwise: create the pending request, or return the existing one: `202 {wedding_id, wedding_name, role, status:"pending"}`. Notify the owner (`join_requested`, in-app + push).
- **`GET /weddings/:id/join-requests`** (owner): pending requests, oldest first: `{id, user_id, username, display_name, role, created_at}`.
- **`POST /weddings/:id/join-requests/:rid/approve`** (owner) `{role?: editor|viewer}`, defaulting to the requested role, which the owner can lower but not raise:
  - Creates the membership (`via_link_id` = the link).
  - Records the outcome as the member's ceiling (an owner decision, like a username invite).
  - Marks the request approved and notifies the requester (`join_approved`).
  - A request that isn't pending (already decided) → 404.
- **`POST /weddings/:id/join-requests/:rid/decline`** (owner): marks it declined and notifies the requester (`join_declined`). The requester may ask again later; the owner sees the new request.
- **Remove D3's auto-revoke.** Owner removal and demotion no longer revoke the link the member joined with; links stay working for everyone. `via_link_id` is still recorded, for history.
- Ceilings stay. Demotions still stick (links can't override them), and removed users are still refused before any request is created.
- Wedding and account deletion also delete `join_requests`. Swagger and the ADR-004 addendum are updated.

- **Limits and hygiene (added 2026-10-08):**
  - A declined user can't ask again for 24h (`409 join_request_declined`).
  - At most 50 pending requests per wedding (`429 join_queue_full`).
  - The owner is pushed only when the queue was empty; later requests are stored in-app silently.
  - Revoking a link closes the requests made through it.
  - A request is `closed` (no cooldown) when the user joins another way or is removed.
  - Approval re-checks the owner's last decision and refuses a removed user (`403 removed_from_wedding`).
  - The owner's list never shows existing members.

## App UX
- **Invite preview → Accept:**
  - `pending`: the card switches to a "Request sent" state: "{wedding} — the owner will review your request. You'll get a notification." with a Done button back to home.
  - `member`: open the wedding (as now).
  - `removed_from_wedding`: the existing localized message.
- **Share screen (owner):** a **Join requests (N)** section at the top, shown only when N > 0. Each row shows avatar, name and @username, the requested role, and how long ago. Two actions:
  - **Approve:** a sheet with the role picker, defaulting to the requested role, editor/viewer only.
  - **Decline:** destructive, with a confirm.
  - Rows update optimistically, with rollback and a toast on failure. After an approval the members list reloads.
- **Notifications:**
  - `join_requested` (owner): tap → that wedding's share screen.
  - `join_approved` (requester): tap → the wedding; the home list also picks it up.
  - `join_declined`: tap → nothing.
- **Remove confirm:** back to the original text, without "the link will stop working".
- ar/en/fr strings; RTL-first.

## Success criteria
- [x] Opening a link never makes anyone a member without owner approval (integration test).
- [ ] A removed user is refused at accept, with no request and no notification.
- [ ] A second account's request appears to the owner, and declining it leaves them out.
- [ ] The owner can approve at a lower role, but never above what the link grants.
- [ ] Removing a member leaves every link active (D3 revoke gone).
- [ ] One pending request per (wedding, user): repeated taps return the same request.
- [ ] Non-owners get 403/404 on list, approve and decline.
- [ ] App: preview pending state, approve/decline with rollback, and notification taps; unit and widget tests.

## Out of scope
- Per-link "no approval needed" or single-use links. Possible later.
- Requester cancelling their own request.
- Expiring links.
