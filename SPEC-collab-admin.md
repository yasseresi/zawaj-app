# Spec: collab-admin

Conventions: [SPEC-common.md](SPEC-common.md) · Map: [SPEC-map.md](SPEC-map.md) · Depends on: `wedding-manage`

## Objective
Give owners full control over who can do what on a wedding: change a member's role, kill a leaked invite link, and hand the wedding over to someone else (for example, the couple taking over from a planner). Today only invite and remove exist.

## Endpoints
- `PATCH /weddings/:id/members/:userId` `{role: editor|viewer}` (owner). The service and repository already exist.
- `DELETE /weddings/:id/invite-links/:linkId` (owner). The service and repository already exist.
- `POST /weddings/:id/transfer` `{user_id}` (owner). New `WeddingService.transferOwnership` and repository method. On the server, the target must already be a member. The old owner becomes **editor**.

## UX (Share screen, owner view only)
- **Member tile:** replace the lone remove icon with an overflow menu (⋮) holding these actions:
  - **Change role** → a bottom sheet with two radio options (Editor: "can add and edit guests"; Viewer: "can only view"). The current role is preselected. Optimistic: the tile updates at once and rolls back with a toast on failure.
  - **Make owner** → confirm dialog: "<name> becomes the owner. You'll become an editor and lose owner controls (delete wedding, manage members). This can only be undone by the new owner." On confirm: `POST /transfer`, then `WeddingsProvider.refresh(id)` (from `wedding-manage`) and a reload of the members. The screen re-renders in editor mode, with owner controls hidden, and a toast appears.
  - **Remove** → the existing confirm flow.
- *(Added 2026-10-07)* **Owner decisions stick (server-enforced, backend 2f65a81).** Invite links never undo a demotion or removal: a demoted member who leaves and rejoins by link gets at most the role the owner set; a removed member is refused (`403 removed_from_wedding`, shown as a localized "the owner removed you… ask them to invite you again"). Only a new username invite from the owner re-admits them. Remove and demote therefore need no "revoke links?" follow-up; the links stay usable for everyone else.
  - The owner's own tile shows no menu.
- **Invite links list:** each active link shows its role and created date with a **Revoke** action. A confirm dialog explains that people who haven't joined yet will no longer be able to use the link. After a successful revoke, the link disappears from the list with an animation. If the revoked link is the one currently shown as a QR code, the QR clears.
- Editors and viewers see the members read-only (no menus) and no invite-link list.

## Success Criteria
- [ ] Role change updates the tile immediately. A simulated failure rolls it back and toasts.
- [ ] After a transfer, the former owner sees no owner-only controls anywhere (wedding screen overflow, share screen, delete) without restarting the app.
- [ ] A revoked link is removed from the list, and a 404 on revoke (already revoked) is treated as success.
- [ ] Unit tests: `ShareProvider.setRole` (optimistic + rollback), `revokeLink`, `transfer` (refresh triggered). Widget tests: menu visible only to the owner on others' tiles, transfer confirm copy.
