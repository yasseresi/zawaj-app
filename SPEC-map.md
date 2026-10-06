# Capability Map: Close API Gaps

Source audit: [docs/UNIMPLEMENTED_ENDPOINTS.md](docs/UNIMPLEMENTED_ENDPOINTS.md). This map is the index of the specs; module ids are stable and never renamed.

| Module id | Responsibility | Endpoints | Backend change? | Depends on |
|---|---|---|---|---|
| `phone-contact` | Shared Algerian phone input + validation (local `0XXXXXXXXX` format); user `phone` replaces `email`; tap a guest contact to call or WhatsApp | `PATCH /me` (phone) | Yes: migration + DTO | — |
| `account-profile` | Edit display name + phone; notification preference toggles | `PATCH /me`, `PATCH /me/settings` | No (uses `phone-contact`'s) | `phone-contact` |
| `wedding-manage` | Fetch a single wedding; edit its name/date/description | `GET /weddings/:id`, `PATCH /weddings/:id` | No | — |
| `guest-edit` | Full guest edit form (shared with add-guest) | `PATCH /weddings/:id/guests/:gid` | No | `phone-contact` |
| `collab-admin` | Change member role, revoke invite link, transfer ownership | `PATCH …/members/:userId`, `DELETE …/invite-links/:linkId`, `POST …/transfer` | No | `wedding-manage` |
| `account-delete` | Password-confirmed deletion with an owned-weddings warning that points to transfer | `DELETE /me` | Yes: password required | `collab-admin` |

Build order: `phone-contact` → `account-profile`, `wedding-manage`, `guest-edit` (in parallel) → `collab-admin` → `account-delete`

Specs: `SPEC-<module-id>.md` at the project root. Shared conventions (stack, commands, style, boundaries) live in [SPEC-common.md](SPEC-common.md); each module spec covers only what is specific to it.

## Decisions (2026-10-06)
- `DELETE /me` requires the current password, checked on the server.
- `/me/settings` UI exposes only `notif_push` and `notif_rsvp`. Email and `notif_email` are hidden. Dark mode stays on the device (current `ThemeProvider` behaviour).
- Phone is an optional, **unverified** profile contact field. Login stays username + password; ADR-003 is unchanged (no SMS/OTP).
- The app is Algeria-only. Phones are stored and displayed in local format (`0672859965`), with no `+213`. The international form is only built for WhatsApp links.
