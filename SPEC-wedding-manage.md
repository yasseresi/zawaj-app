# Spec: wedding-manage

Conventions: [SPEC-common.md](SPEC-common.md) · Map: [SPEC-map.md](SPEC-map.md)

## Objective
1. Load a wedding on its own, so that deep links, notification taps and post-transfer refreshes work even when the wedding is not in (or is stale in) the cached `GET /weddings` list.
2. Let the owner correct the wedding's name, date and description after creation. Today these are write-once.

## Endpoints
- `GET /weddings/:id` → `Wedding` (viewer+). New `WeddingService.get` and repository `get`.
- `PATCH /weddings/:id` `{name?, event_date?, description?}` → `Wedding` (owner). New `WeddingService.update` and repository `update`.

## Behaviour
- `WeddingsProvider` gains `refresh(String id)`: it calls `GET /weddings/:id` and replaces that item in the list (or inserts it if missing). A 404 removes it from the list and shows the "not found / no access" state.
- The wedding route (`/weddings/:id`) resolves the wedding from the list first and falls back to `refresh(id)` when it is missing. Deep links and notification taps no longer dead-end.
- **Edit wedding:** the owner only sees an "Edit" item in the wedding screen's app-bar overflow menu (⋮) (`guest_list_screen.dart`). It opens a full-screen route `/weddings/:id/edit`.
  - Reuses the create-wedding form fields (extracted into a shared `WeddingForm` widget; `CreateWeddingScreen` uses it too). The fields are prefilled.
  - Name: required, ≤120 characters. Date: adaptive date picker. Description: ≤2000 characters.
  - Save stays disabled until a change is made. Back-navigation with unsaved changes asks for confirmation. Only changed fields are sent.
  - On success: pop the route, show a toast, and update the wedding in `WeddingsProvider` (the header name and date update in place).

## Success Criteria
- [ ] Opening `/weddings/<id>` cold (not in the list) loads the wedding through `GET /weddings/:id`.
- [ ] Editors and viewers never see the Edit item. If an owner is demoted while the screen is open, a 403 on save shows a toast.
- [ ] Changing only the date sends `{event_date:"YYYY-MM-DD"}`.
- [ ] Unit tests: `WeddingsProvider.refresh` (replace / insert / 404 remove), edit provider diff and dirty tracking. Widget test: Save gating and the discard confirm.

## Open Questions
1. Clearing a date or description: the backend DTO uses `omitempty` pointers, so sending `""` for `event_date` fails the `datetime` validator. Default: in the app, date and description can be changed but not cleared. Check `WeddingService.Update` before deciding whether a backend tweak is worth it (ask first).
