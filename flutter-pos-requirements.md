# Spare Parts Shop POS & Inventory App — Flutter MVP Plan

## 1. Overview

Mobile-first Flutter app for a single-user spare parts shop to:

- Record sales (multi-item cart, flexible pricing)
- Track inventory with direct stock editing
- Work **offline-first** with local Drift (SQLite) database
- Auto-backup DB to Google Drive daily
- On-demand export to Google Sheet for review
- One-time import from Google Sheet for initial product seeding

---

## 2. User & Device

- **Single user**, single device (phone)
- **Access control:** Simple PIN/password lock on app launch
- **Internet:** Available but unstable — app must work fully offline

---

## 3. MVP Scope

### In MVP

| Feature | Detail |
|---------|--------|
| Product catalog | Add/edit products in-app, ~50-100 items |
| Product search | Search by name |
| Multi-item sales | Cart with 3-4 items per transaction, flexible per-item pricing |
| Stock deduction | Automatic on sale completion |
| Stock adjustment | Direct edit of quantity, no audit log |
| PIN lock | Simple password on app launch |
| Google Drive backup | Automatic daily `.db` file upload |
| Export to Sheet | On-demand button, pushes current data to Google Sheet |
| Import from Sheet | One-time button, pulls products for initial setup |

### Deferred (Phase 2+)

| Feature | Phase |
|---------|-------|
| Full Google Sheets bidirectional sync | 2 |
| Reports (monthly sales, stock summary) | 2 |
| Commission tracking | 2 |
| Low-stock alerts | 2 |
| Receipt printing | 3 |
| Barcode scanning | 3 |
| Price history tracking | 3 |
| Analytics dashboard | 3 |
| Multi-user / roles | 3 |

---

## 4. Data Model (Drift / SQLite)

### products

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT (UUID) | Primary key, generated in-app |
| name | TEXT | Product name |
| suggested_price | INTEGER | IDR, no decimals |
| cost_price | INTEGER | Optional |
| stock_qty | INTEGER | Current stock |
| active | INTEGER | 1/0 boolean |
| created_at | INTEGER | Unix timestamp |
| updated_at | INTEGER | Unix timestamp |

### transactions

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT (UUID) | Primary key |
| date_time | INTEGER | Unix timestamp |
| total_price | INTEGER | Sum of line items |
| notes | TEXT | Optional |
| created_at | INTEGER | Unix timestamp |

### transaction_items

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT (UUID) | Primary key |
| transaction_id | TEXT | FK → transactions.id |
| product_id | TEXT | FK → products.id |
| product_name | TEXT | Snapshot at time of sale |
| quantity | INTEGER | Quantity sold |
| unit_price | INTEGER | Actual price charged (IDR) |
| subtotal | INTEGER | quantity × unit_price |

### sync_metadata

| Column | Type | Notes |
|--------|------|-------|
| key | TEXT | e.g. "last_backup", "last_export" |
| value | TEXT | Timestamp or status |

---

## 5. Google Sheets Structure

Used for **export/import only** — not a live backend.

### Sheet: `products`

| Column | Maps to |
|--------|---------|
| product_id | products.id |
| name | products.name |
| suggested_price | products.suggested_price |
| cost_price | products.cost_price |
| stock_qty | products.stock_qty |
| active | products.active |

### Sheet: `transactions`

| Column | Maps to |
|--------|---------|
| transaction_id | transactions.id |
| date_time | transactions.date_time |
| total_price | transactions.total_price |
| notes | transactions.notes |

### Sheet: `transaction_items`

| Column | Maps to |
|--------|---------|
| item_id | transaction_items.id |
| transaction_id | transaction_items.transaction_id |
| product_id | transaction_items.product_id |
| product_name | transaction_items.product_name |
| quantity | transaction_items.quantity |
| unit_price | transaction_items.unit_price |
| subtotal | transaction_items.subtotal |

---

## 6. Architecture

### Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter |
| Local DB | Drift (SQLite ORM) |
| State management | Riverpod |
| Connectivity | connectivity_plus |
| IDs | uuid (v4) |
| Google Drive backup | googleapis / google_sign_in |
| Google Sheets export/import | Google Apps Script endpoint |
| Currency | IDR, stored as INTEGER (no decimals) |

### Data Flow

```
Google Sheet ──[Import button]──► App (Drift DB) ──[Export button]──► Google Sheet
                                       │
                               [auto daily backup]
                                       │
                                       ▼
                                  Google Drive (.db)
```

### App Layers

```
UI (Screens)
    │
    ▼
Riverpod Providers (state + business logic)
    │
    ▼
Repositories (data access)
    │
    ▼
Drift Database (local SQLite)
    │
    ├── Google Drive API (auto backup)
    └── Apps Script API (export/import)
```

---

## 7. Screens (MVP)

### 7.1 PIN Lock Screen

- Enter password to access app
- Stored locally (hashed)

### 7.2 Product List (Home)

- Search bar
- List: name, stock qty, suggested price
- Tap → edit product
- FAB → add new product
- Bottom nav or drawer for navigation

### 7.3 Add/Edit Product

- Fields: name, suggested price, cost price (optional), stock qty
- Save → insert/update in Drift

### 7.4 New Sale (Cart)

- Search/select product
- Enter quantity
- Edit unit price (pre-filled with suggested price)
- Add to cart
- Cart summary: list of items, subtotals, total
- Confirm → save transaction + deduct stock

### 7.5 Sales History

- List of past transactions (date, total, item count)
- Tap → view line items

### 7.6 Stock Adjustment

- Select product → edit stock quantity directly
- Save → update Drift

### 7.7 Settings

- Export to Sheet button
- Import from Sheet button
- Last backup status
- Change PIN

---

## 8. Backup & Export

### Auto Backup (Google Drive)

- Trigger: daily, or on app open if >24h since last backup
- Action: upload Drift `.db` file to Google Drive folder
- Auth: Google Sign-In (one-time setup)
- Track: last backup timestamp in sync_metadata

### Export to Sheet (On-demand)

- User taps "Export to Sheet"
- App reads all Drift tables
- Sends data to Apps Script endpoint → writes to Google Sheet
- Overwrites previous Sheet data (full export, not incremental)

### Import from Sheet (On-demand)

- User taps "Import from Sheet"
- App calls Apps Script endpoint → reads `products` sheet
- Upserts products by product_id into Drift
- Used for initial seeding or bulk product updates from computer

---

## 9. Implementation Phases

### Phase 1: MVP (ship ASAP)

1. Flutter project setup + Drift schema
2. PIN lock screen
3. Product CRUD (add, edit, list, search)
4. Cart-based sales flow
5. Stock deduction on sale
6. Direct stock editing
7. Sales history view
8. Google Drive auto-backup
9. Export to Sheet button
10. Import from Sheet button

### Phase 2: Reporting & Sync

- Monthly sales summary report
- Stock report
- Low-stock alerts
- Commission tracking
- Full bidirectional Google Sheets sync

### Phase 3: Hardware & Analytics

- Receipt printing (Bluetooth thermal printer)
- Barcode scanning
- Price history tracking
- Analytics dashboard
- Multi-user support with roles

---

## 10. Key Business Rules

- All prices in IDR (integer, no decimals)
- Final price is always editable per sale line item
- Stock reduces automatically on completed sale
- Stock can be directly edited (no formal adjustment log in MVP)
- Products identified by UUID, never by name in references
- Product name snapshotted in transaction_items (survives product rename)
- Single user, single device
- Negative stock allowed (shop may sell before restocking — show warning, don't block)
- Product deletion is soft-delete (set active = 0), never hard-delete (past transactions reference products)
- Inactive products hidden from sale search, visible in product list with filter
- Offline-first: all features work without internet
- Backup and export require internet (show clear status to user)
