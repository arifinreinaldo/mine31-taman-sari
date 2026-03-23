# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Taman Sari POS — an offline-first point-of-sale and inventory management Flutter app for a spare parts shop (single user, single device). Local SQLite via Drift ORM, with optional Google Drive backup and Google Sheets export/import.

## Common Commands

```bash
# Run the app
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/features/sales/transaction_repository_test.dart

# Static analysis (uses flutter_lints)
flutter analyze

# Regenerate Drift database code after schema changes
flutter pub run build_runner build

# Auto-rebuild on schema changes
flutter pub run build_runner watch
```

## Architecture

**Feature-based structure** under `lib/features/` with four domains: `auth`, `products`, `sales`, `settings`. Each feature follows the pattern: `screens/`, `providers/`, `repositories/`, optionally `models/`, `widgets/`, `services/`.

**Stack:** Flutter + Riverpod (state) + Drift (SQLite ORM) + GoRouter (routing).

**Data flow:** UI Screen → Riverpod Providers → Repositories → Drift ORM → SQLite

**Key patterns:**
- **Repository pattern** — all DB access goes through repository classes, injected as Riverpod providers
- **StreamProvider** for reactive Drift watch queries; **NotifierProvider** for complex state (cart)
- **Atomic transactions** — `saveSale()` inserts transaction + items + deducts stock in a single Drift transaction
- **Soft-delete** on products (`active` flag) to preserve transaction history references
- **In-memory testing** — tests use `AppDatabase.forTesting(NativeDatabase.memory())`

**Routing:** GoRouter with nested shell routes (bottom nav: Products, New Sale, History, Settings). Route guards redirect to PIN screen if unauthenticated.

## Database

All tables use TEXT UUIDs for IDs. Prices are INTEGER (IDR, no decimals). Schema defined in `lib/database/tables/`. Generated code in `app_database.g.dart` — never edit manually.

**SyncMetadata** is a key-value table storing PIN hash, last backup/export/import timestamps (keys defined in `core/constants.dart` → `MetaKeys`).

## Google Integration

- **Google Drive backup:** uploads/restores raw `.db` file as `taman_sari_backup.db`. Restore closes DB and requires app restart.
- **Google Drive restore:** downloads backup from Drive, writes to temp file first (safe swap), closes DB, replaces local file. App must restart after restore.
- **Sheets export/import:** uses an Apps Script URL (user-configured) to POST JSON payloads. Import upserts products only.
- **Account display:** Settings screen shows signed-in Google account with sign-out option via `signInSilently()`.
- Both are optional; the app is fully functional offline.

## Conventions

- Currency formatting: `formatIdr()` from `core/formatters.dart`
- Negative stock is allowed (shows warning, doesn't block sales)
- PIN auth uses SHA256 hashing stored in SyncMetadata
