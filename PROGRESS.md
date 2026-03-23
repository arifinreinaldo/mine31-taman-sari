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
| Auto-backup (>24h check) | Done | Triggers silently on cold start if signed in and >24h |
| Connectivity check | Done | Warns "No internet connection" before all Google operations |

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

## Testing (93 tests, all passing)

| Area | Status | Tests | Notes |
|---|---|---|---|
| Auth repository | Done | 5 | `authenticate()`, `isDeviceSupported()`, `canCheckBiometrics()` |
| Product repository | Done | 18+ | CRUD, soft-delete, search, upsert |
| Cart item model | Done | 6 | subtotal, copyWith, wouldCauseNegativeStock |
| Cart provider | Done | 8 | addItem, updateItem, removeItem, clear, totals |
| Transaction repository | Done | 8+ | Atomic saveSale, watchAll, getById, getItems |
| Core formatters | Done | 14 | formatIdr, formatDateTime, formatDate, formatTimeAgo |
| Database schema & transactions | Done | 6 | Products, Transactions, SyncMetadata, rollback |
| Google Drive service | Done | 5 | shouldAutoBackup() timestamp logic |
| UI / widget smoke tests | Done | 13 | ProductList, NewSale, SaleHistory, Settings screens |
| Routing / auth guard | Done | 5 | Auth redirect, bottom nav, tab navigation |

---

## Known Issues & TODOs

1. **Apps Script URL not configurable** (`settings_screen.dart:116, 145`)
   - Sheets export/import are non-functional until a config UI is added
   - Need: form screen + persist URL in `SyncMetadata` via `MetaKeys`
