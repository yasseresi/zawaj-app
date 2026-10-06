# Spec: guest-edit

Conventions: [SPEC-common.md](SPEC-common.md) · Map: [SPEC-map.md](SPEC-map.md) · Depends on: `phone-contact`

## Objective
Editors can fix any guest field, not just the RSVP status. Typos in names and wrong companion counts currently mean deleting and re-adding the guest, which loses its notes and history.

## Endpoint
`PATCH /weddings/:id/guests/:gid` `{full_name?, contact?, relationship?, status?, companions?, table_label?, meal?}` → `Guest` (editor+). New `GuestService.update` and repository `update`.

## UX
- Guest detail app bar (editor+): add an **Edit** (pencil) action next to the existing note and status actions. It opens a full-screen route `/weddings/:id/guests/:gid/edit`.
- Extract the add-guest form into a shared `GuestForm` widget. `AddGuestScreen` (create) and `EditGuestScreen` (prefilled) both use it. The initial-note field shows only in create mode.
- Fields: full name (required, ≤120), contact (`AppPhoneField`), relationship (≤80), status (segmented control), companions (stepper, 0–1000). *(Table and meal removed 2026-10-07 at the user's request: not needed. The backend fields stay, but the app neither shows nor edits them.)*
- Legacy contact that isn't a phone number: show it in the field with a hint telling the user to enter a phone number. It is saved unchanged unless the user edits it.
- Save stays disabled until a change is made. Back-navigation with unsaved changes asks for confirmation. Only changed fields are sent. On success: pop, show a toast, reload `GuestDetailProvider` (the history shows "guest updated"), and update the row in `GuestsProvider`'s list without a full refetch.
- The quick status sheet stays as the one-tap path. The full form is for everything else.

## Success Criteria
- [ ] Viewers don't see Edit.
- [ ] Changing only companions sends `{companions: N}`.
- [ ] Editing keeps the guest's notes and history, and adds a `guest_updated` history entry.
- [ ] After saving, the list row shows the new name and status without a pull-to-refresh.
- [ ] Unit tests: edit provider diff and dirty tracking, list in-place update. Widget tests: `GuestForm` in both modes, Save gating, discard confirm.
