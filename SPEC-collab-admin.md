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
  - **Remove** → the existing confirm flow. *(Added 2026-10-07)* Removing a member doesn't invalidate invite links, so if any are active a follow-up dialog offers **Revoke links** / **Keep links** (destructive style, explains that people who haven't joined will need a new link). Revoking tries every active link; failures stay listed with an error toast. Links never change an existing member's role (backend df8a7d9). *(Added 2026-10-07)* Demoting an editor to viewer likewise offers to revoke the active **editor** links (viewer links stay), since the member could otherwise leave and rejoin through one.
  - The owner's own tile shows no menu.
- **Invite links list:** each active link shows its role and created date with a **Revoke** action. A confirm dialog explains that people who haven't joined yet will no longer be able to use the link. After a successful revoke, the link disappears from the list with an animation. If the revoked link is the one currently shown as a QR code, the QR clears.
- Editors and viewers see the members read-only (no menus) and no invite-link list.

## Success Criteria
- [ ] Role change updates the tile immediately. A simulated failure rolls it back and toasts.
- [ ] After a transfer, the former owner sees no owner-only controls anywhere (wedding screen overflow, share screen, delete) without restarting the app.
- [ ] A revoked link is removed from the list, and a 404 on revoke (already revoked) is treated as success.
- [ ] Unit tests: `ShareProvider.setRole` (optimistic + rollback), `revokeLink`, `transfer` (refresh triggered). Widget tests: menu visible only to the owner on others' tiles, transfer confirm copy.
