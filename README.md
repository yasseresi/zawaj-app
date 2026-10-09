# Zawaj App

A Flutter mobile application for the Zawaj wedding management platform. Works alongside the [Zawaj API](../backend/) (Go + Gin).

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [State Management](#state-management)
- [Navigation](#navigation)
- [Localization](#localization)
- [Environment Variables](#environment-variables)
- [Running Tests](#running-tests)
- [Code Generation](#code-generation)
- [Related Docs](#related-docs)

---

## Overview

Zawaj App is the mobile client for the Zawaj platform — a wedding planning and coordination tool. It connects to the Zawaj REST API and supports Arabic, English, and French.

---

## Tech Stack

| Area | Choice |
|---|---|
| Language | Dart 3 / Flutter |
| Architecture | MVVM (Model–View–ViewModel) |
| State management | `provider` |
| Navigation | `go_router` |
| Networking | `dio` |
| Local storage | `shared_preferences` + `flutter_secure_storage` |
| Localization | `easy_localization` (ar, en, fr) |
| UI utilities | `flutter_screenutil`, `flutter_animate` |
| Push notifications | Firebase Cloud Messaging |
| Environment | `flutter_dotenv` |

---

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | ≥ 3.24 |
| Dart SDK | ≥ 3.5.0 < 4.0.0 |
| Xcode (iOS) | ≥ 15 |
| Android Studio / SDK | API 21+ |
| Firebase CLI | latest |

---

## Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Copy and fill in environment variables
cp .env.example .env

# 3. Run on a connected device / emulator
flutter run

# 4. Run in release mode
flutter run --release
```



---

## Project Structure

```text
lib/
└── src/
    ├── core/
    │   ├── api/          # Dio client, interceptors, API service
    │   ├── i18n/         # Generated locale keys
    │   ├── utils/        # Error handler, helpers
    │   └── widgets/      # Shared/reusable widgets
    ├── data/
    │   ├── models/       # DTOs and entity models
    │   └── repositories/ # Repository implementations
    ├── routing/          # go_router configuration
    ├── services/         # App-level services (auth, push, …)
    ├── theme/            # Material 3 theme, colors, typography
    └── ui/
        ├── views/        # Screen widgets
        └── view_models/  # ChangeNotifier ViewModels
```

Assets:

```text
assets/
├── images/
├── icons/
└── translations/   # ar.json, en.json, fr.json
```

---

## Architecture

The app follows **MVVM** (Model–View–ViewModel):

```
View (Widget) → ViewModel (ChangeNotifier) → Repository → API / Local Storage
```

Rules:
- No business logic inside `build()` methods.
- Widgets bind to ViewModels via `context.watch` (in `build`) and `context.read` (in callbacks).
- Data access is always through a repository — never call the API directly from a widget or ViewModel.
- Errors are mapped to typed `Failure` subclasses at the data boundary; the UI only sees `Failure`, never raw `DioException`.



---

## State Management

Provider is used for reactive state:

```dart
// Expose
ChangeNotifierProvider(create: (_) => MyViewModel())

// Consume in build()
context.watch<MyViewModel>().someState

// Consume in callbacks
context.read<MyViewModel>().doSomething()
```

---

## Navigation

Routing is handled by `go_router`. All routes are defined in `lib/src/routing/`. Named routes are used throughout — avoid hardcoded path strings.

---

## Localization

The app supports **Arabic (ar)**, **English (en)**, and **French (fr)** via `easy_localization`.

Translation files live in `assets/translations/*.json`.

After editing translations, regenerate the keys file:

```bash
flutter pub run easy_localization:generate \
  -S assets/translations \
  -O lib/src/core/i18n \
  -o locale_keys.g.dart -f keys
```

Arabic is the primary language; the UI is **RTL-first**.

---

## Environment Variables

Copy `.env.example` to `.env` and fill in the values:

```env
API_BASE_URL=https://api.example.com
```

Never commit `.env` files containing production secrets.

---

## Running Tests

```bash
# All tests
flutter test

# Single file
flutter test test/path/to/test_file.dart

# With coverage
flutter test --coverage
```

---

## Code Generation

```bash
# Restore packages
flutter pub get

# Regenerate locale keys (after editing translations)
flutter pub run easy_localization:generate \
  -S assets/translations \
  -O lib/src/core/i18n \
  -o locale_keys.g.dart -f keys
```

---

## Related Docs

| Doc | Purpose |
|---|---|
| [../backend/](../backend/) | Zawaj Go API |
