# Spec: Shared conventions for the API-gap modules

Applies to every `SPEC-<module>.md` listed in [SPEC-map.md](SPEC-map.md).

## Tech Stack
- Flutter (Dart SDK >=3.5), `provider` ChangeNotifier view-models, `go_router` 17, `dio` 5 via `ApiClient`, `fpdart` `Either<Failure, T>` (`FutureEither`), `easy_localization` (ar primary / en / fr, RTL-first), `flutter_screenutil`, `url_launcher`.
- Backend (only for `phone-contact` and `account-delete`): Go 1.26.6, Gin + GORM + Postgres, golang-migrate SQL migrations, in `../backend` (separate git repo).

## Commands
```bash
# App (from zawaj_app/)
flutter pub get
flutter analyze
flutter test                                   # serialised by dart_test.yaml
flutter test test/unit/<file>_test.dart
flutter pub run easy_localization:generate -S assets/translations -O lib/src/core/i18n -o locale_keys.g.dart

# Backend (from backend/)
make test                                      # unit, -race
TEST_DATABASE_URL=postgres://postgres:postgres@localhost:5432/zawaj_test?sslmode=disable go test ./test -race
make lint
make docs                                      # after changing handler annotations
```

## Project Structure (per feature slice)
```
lib/src/services/<x>_service.dart          → transport only: path, body, parse
lib/src/data/repositories/<x>_repository*.dart → interface + impl (thin pass-through)
lib/src/data/models/                        → Equatable models, fromJson
lib/src/ui/<feature>/providers/             → ChangeNotifier view-model
lib/src/ui/<feature>/<screen>.dart          → screen
lib/src/ui/<feature>/widgets/               → feature widgets (sheets, tiles)
lib/src/shared/widgets/                     → cross-feature widgets (AppTextField, AppButton…)
lib/src/routing/app_routes.dart + app_router.dart
assets/translations/{ar,en,fr}.json         → every user string, all three files
test/unit/ test/widget/                     → mirrors lib
```

## Code Style
Match the existing view-models: inject the repository with a default, keep a status and error message, and return `bool` from write actions so the view can toast.
```dart
/// Edit the wedding (owner). Sends only changed fields; reloads on success.
Future<bool> save() async {
  if (!isDirty) return true;
  _saving = true;
  _errorMessage = null;
  notifyListeners();
  final result = await _repository.update(_weddingId, _changedFields());
  _saving = false;
  return result.match(
    (failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    },
    (wedding) {
      _wedding = wedding;
      notifyListeners();
      return true;
    },
  );
}
```
- Strings: `'module.key'.tr()`, with the key added to ar/en/fr and the locale keys regenerated.
- Errors: map through the existing `error_handler.dart` and show them with `showGlobalToast` / `context.showSnackBar`. Never show raw server text for 5xx errors.
- Write the Dart doc comment for each public method so it names its endpoint (existing convention: ``/// `PATCH /weddings/:id` → …``).

## UX rules (all modules)
1. **Role-aware UI:** hide controls the caller's role can't use; don't show them disabled. The server still enforces (403 → toast).
2. **Forms:** prefill current values. Save is disabled until something changes and the form is valid. Validate inline as the user types. Asking for confirmation before back-navigation discards unsaved changes (`PopScope`). Send only changed fields.
3. **Busy state:** disable the triggering control and show progress inside it. No double submits.
4. **Destructive actions:** use an adaptive confirm dialog that names what is lost, with the destructive button styled in the error colour. Irreversible actions (`account-delete`) need extra friction (re-enter password).
5. **Feedback:** toast on success. On failure, keep the user's input and show the reason.
6. **Optimistic updates:** only for cheap, reversible toggles (notification switches, role change). Roll back and toast on failure.
7. **Accessibility:** tap targets of at least 48dp, semantic labels on icon buttons, and a layout that survives 1.3× text scale, in both RTL and LTR.
8. **Forms layout:** a short form (≤ 3 fields) opens as a bottom sheet; a longer form opens as a full-screen route.

## Testing Strategy
- **Unit** (`test/unit/`): every new or changed provider, tested with a hand-written fake repository (the `guest_detail_provider_test.dart` pattern). Cover success, failure, dirty-tracking, the diff payload, and rollback.
- **Widget** (`test/widget/`): each new form or sheet. Cover validation messages, Save enabled/disabled, role-gated visibility, and the confirm dialogs.
- **Backend** (backend modules only): a service unit test and a black-box integration test in `backend/test/`.
- Gate: `flutter analyze` is clean and `flutter test` is green before every commit.

## Boundaries
- **Always:** follow the service → repository → provider → screen layering. Add strings to all 3 locales. Write tests with each slice. Make small Conventional Commits on a feature branch, with no Claude co-author trailer. Run `graphify update .` after code edits.
- **Ask first:** adding a pub dependency. Any backend change beyond what `phone-contact` and `account-delete` specify. Dropping DB columns. Changing router guard logic.
- **Never:** call the API from widgets directly. Hardcode user-facing strings. Weaken the server-side role checks. Commit `.env` or secrets. Touch the unrelated working-tree changes (`ios/Podfile.lock`, `app_router.dart` WIP) without asking.
