# Backend endpoints not used by the mobile app

Audit date: 2026-10-06. Compared `backend/internal/handler/*.go` routes against `lib/src/services`, `lib/src/data/repositories`, and `lib/src/ui`.

## A. Not in the app at all (no service method)

| # | Endpoint | Min role | What it does | Backend handler |
|---|----------|----------|--------------|-----------------|
| A1 | `GET /weddings/:id` | viewer | Fetch one wedding. The app currently reads it out of the `GET /weddings` list. | `wedding.go` `h.get` |
| A2 | `PATCH /weddings/:id` | owner | Edit wedding `name`, `event_date`, `description`. | `wedding.go` `h.update` |
| A3 | `POST /weddings/:id/transfer` | owner | Transfer ownership to another member (`{user_id}`). Audited. | `wedding.go` `h.transferOwnership` |
| A4 | `PATCH /weddings/:id/guests/:gid` | editor | Edit guest fields: `full_name`, `contact`, `relationship`, `status`, `companions`, `table_label`, `meal`. The app only uses `/status`. | `guest.go` `h.update` |

## B. Service method exists, but no UI calls it

| # | Endpoint | Service method | Notes |
|---|----------|----------------|-------|
| B1 | `PATCH /me` | `AuthService.updateProfile` | Edit `display_name`. The Settings "account" row shows a "coming soon" toast. |
| B2 | `PATCH /me/settings` | `AuthService.updateSettings` | `email`, `dark_mode`, `notif_push`, `notif_email`, `notif_rsvp`. The theme is local only; no notification-preference UI. |
| B3 | `DELETE /me` | `AuthService.deleteAccount` | Delete account. No UI. Note: App Store requires in-app account deletion. |
| B4 | `PATCH /weddings/:id/members/:userId` | `WeddingService.setMemberRole` (and repo) | Change a member's role (editor/viewer). Wired up to the repository, but the share screen has no control for it. |
| B5 | `DELETE /weddings/:id/invite-links/:linkId` | `WeddingService.revokeInviteLink` (and repo) | Revoke an invite link. Wired up to the repository, but no UI. |

## C. Infra (not for the client)

`GET /healthz`, `GET /readyz`, `GET /metrics`

## Already covered (for reference)

auth/register, login, refresh, recover, logout · `GET /me` · `PATCH /me/password` · `POST|DELETE /me/devices` · `GET|POST /weddings` · `DELETE /weddings/:id` · `GET /weddings/:id/members` · `DELETE /weddings/:id/members/:userId` · `POST|GET /weddings/:id/invite-links` · `GET /invite/:token` · `POST /invite/:token/accept` · `POST /weddings/:id/invites` · `GET /invites` · `POST /invites/:id/accept|decline` · guests list/get/create/delete/status/notes · `GET /weddings/:id/stats` · `GET /weddings/:id/activity` · export csv/xlsx/pdf · notifications list/unread_count/read/read_all
