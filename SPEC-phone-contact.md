# Spec: phone-contact

Conventions: [SPEC-common.md](SPEC-common.md) · Map: [SPEC-map.md](SPEC-map.md)

## Objective
The app is used **only in Algeria**, and users and guests are reached by phone, not by email. This module:
1. adds an optional, unverified `phone` to the user (replacing the unused `email`),
2. provides one reusable phone input that `account-profile` and `guest-edit` both use, and
3. makes guest contacts actionable (call / WhatsApp).

Login stays username + password; ADR-003 is unchanged.

## Phone format (Algeria only)
Phones are stored and displayed in **local national format**. There is no `+213` in the UI and none in storage.
- Mobile: `0[5-7]` + 8 digits (10 digits total), e.g. `0672859965`
- Fixed line: `0[2-4]` + 7 digits (9 digits total), e.g. `021234567`
- Canonical regex: `^(0[5-7][0-9]{8}|0[2-4][0-9]{7})$`
- Input is lenient: spaces, dashes, dots and parentheses are stripped. A leading `+213`, `00213` or `213` (for example from a pasted contact) is rewritten to a leading `0`.
- Display grouping: mobile `0672 85 99 65`, fixed `021 23 45 67`. Always LTR.
- International form is only built when a link needs it: WhatsApp → `https://wa.me/213` + the number without its leading 0. Calls use `tel:0672859965` directly.

## Backend (../backend)
- Migration `000009_user_phone.up.sql`: `ALTER TABLE users ADD COLUMN phone varchar(10);`. The down migration drops it. The `email` column **stays** (no destructive drop; see Open Questions).
- `models.User`: add `Phone *string` (`json:"phone,omitempty"`) and stop serialising `email` in `dto.UserResponse`.
- `dto.UpdateMeRequest`: add `Phone *string`. Validate it in the service (not with a struct tag, so it can be normalised first): strip separators, map `+213`/`00213`/`213` → `0`, then match the canonical regex; otherwise `apperr.Validation("invalid phone number")`. `""` clears it (→ `NULL`).
- `dto.UpdateSettingsRequest.Email`: keep accepting it for compatibility. Not used by the app.
- Update the ADR-003 note in `models/user.go` and `docs/ARCHITECTURE.md`: "optional unverified Algerian phone contact; not an auth factor".
- Run `make docs`.

## App
- `lib/src/utils/phone.dart`:
  - `normalizePhone(String raw) → String?`: returns the canonical local number, or null if invalid. Mirrors the backend rules.
  - `formatPhone(String local) → String`: the display grouping.
  - `whatsappUri(String local) → Uri`, `telUri(String local) → Uri`.
- `lib/src/shared/widgets/app_phone_field.dart`: an `AppTextField` variant with `TextInputType.phone`, `autofillHints: [AutofillHints.telephoneNumber]`, hint `0672 85 99 65`, LTR input inside RTL layouts, digits-only input formatter (plus separators while typing), max 10 digits, inline validation through `normalizePhone`, and optional (empty is valid). It emits the canonical value.
- `AppUser`: add `phone` (`String?`) and parse it.
- Guest detail contact row: if the contact normalises to a phone number, tapping it opens an action sheet with **Call**, **WhatsApp** and **Copy**. Otherwise it is shown as plain text (legacy data). Uses `url_launcher`, which is already a dependency.

## Success Criteria
- [ ] `PATCH /me {"phone":"0672859965"}` → 200, `phone:"0672859965"`. `{"phone":"+213 672 85 99 65"}` → stored as `0672859965`. `{"phone":"0812345678"}` / `{"phone":"0551"}` → 400. `{"phone":""}` → cleared.
- [ ] `GET /me` no longer returns `email`.
- [ ] `normalizePhone` unit tests: mobile 05/06/07, fixed 02/03/04, `+213`/`00213`/`213` prefixes, separators, wrong prefix (`08`, `01`), wrong length, empty.
- [ ] Widget test: the field accepts `0672 85 99 65` and emits `0672859965`, and rejects `123` with an inline error.
- [ ] Guest detail: a phone contact shows the Call/WhatsApp/Copy sheet, and WhatsApp opens `wa.me/213672859965`. Non-phone text shows no sheet.
- [ ] Numbers render LTR inside Arabic UI.

## Open Questions
1. Drop the `users.email` column now, or leave it in place for a later cleanup migration? Default: leave it.
2. Should phone be unique per user? Default: no (it's unverified, so uniqueness would let anyone squat on someone else's number).
