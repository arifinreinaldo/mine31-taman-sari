# Progress — Taman Sari POS

## Features

### Auth
| Feature | Status | Notes |
|---|---|---|
| Biometric / device lock screen | Done | `local_auth` with fallback to device PIN/pattern |
| Session state management | Done | Riverpod `isAuthenticatedProvider` |
| Route guard (redirect to PIN) | Done | GoRouter redirect logic |

### Products
| Feature | Status | Notes |
|---|---|---|
| Product list with search | Done | Real-time stream via Drift `watchAll` |
| Create / edit product | Done | Name, suggested price, cost price, initial stock |
| Stock adjustment | Done | Direct quantity override screen |
| Soft-delete / restore | Done | `active` flag preserves transaction history |
| Show/hide inactive toggle | Done | Filter on product list screen |

### Sales
| Feature | Status | Notes |
|---|---|---|
| New sale with cart | Done | In-memory cart, merge duplicate products |
| Negative stock warning | Done | Confirm dialog, does not block sale |
| Atomic transaction save | Done | Insert transaction + items + deduct stock in single DB transaction |
| Sale history (paginated) | Done | Newest first |
| Sale detail view | Done | Transaction info + line items breakdown |

### Settings — Google Drive
| Feature | Status | Notes |
|---|---|---|
| Backup DB to Google Drive | Done | Uploads/updates `taman_sari_backup.db` |
| Restore DB from Google Drive | Done | Downloads to temp file, safe swap, app restart required |
| Show signed-in Google account | Done | `signInSilently()`, displays email + sign-out button |
| Auto-backup (>24h check) | Not Started | `shouldAutoBackup()` exists but is never called |

### Settings — Google Sheets
| Feature | Status | Notes |
|---|---|---|
| Export to Google Sheets | Blocked | Code ready, but Apps Script URL is hardcoded as `''` |
| Import from Google Sheets | Blocked | Code ready, but Apps Script URL is hardcoded as `''` |
| Apps Script URL config UI | Not Started | Need form to persist URL in SyncMetadata |

### Navigation
| Feature | Status | Notes |
|---|---|---|
| Bottom nav (4 tabs) | Done | Products, New Sale, History, Settings |
| Nested routes per tab | Done | `StatefulShellRoute` preserves branch state |
| Auth route guard | Done | Redirects to `/pin` if unauthenticated |

---

## Testing

| Area | Status | Notes |
|---|---|---|
| Auth repository | Done | 5 tests |
| Product repository | Done | 18+ tests |
| Cart item model | Done | 6 tests |
| Cart provider | Done | 8 tests |
| Transaction repository | Done | 8+ tests |
| Core formatters | Done | 10 tests |
| Database schema & transactions | Done | 6 tests |
| UI / widget tests | Not Started | No screen tests |
| Google services tests | Not Started | Backup/restore/export/import untested |
| Routing tests | Not Started | No navigation tests |

---

## Known Issues & TODOs

1. **Apps Script URL not configurable** (`settings_screen.dart:114, 143`)
   - Sheets export/import are non-functional until a config UI is added
   - Need: form screen + persist URL in `SyncMetadata` via `MetaKeys`

2. **Auto-backup never triggered**
   - `shouldAutoBackup()` exists in `GoogleDriveService` but nothing calls it
   - Need: trigger check on app start or home screen load

3. **`connectivity_plus` unused**
   - Dependency in `pubspec.yaml` but never imported
   - Could warn user before Google operations on bad network

4. **`app_scaffold.dart` unused**
   - `lib/shared/widgets/app_scaffold.dart` — not referenced anywhere
   - Can be removed or repurposed

5. **Deprecation warnings**
   - `withOpacity` usage in `stock_badge.dart:22` and `cart_summary.dart:29`
   - Should migrate to `.withValues()`
