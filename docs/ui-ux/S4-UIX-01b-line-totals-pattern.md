# S4-UIX-01b — Line Totals Pattern

**Purpose:** Add Line Item form for sale details dialog — product picker, quantity, auto-filled unit price, line total, running order total, currency format, and error messages.

Worked example: **10 x 13.75 + 2 x 48.50 = 234.50**

---

## 1. Form Layout

```text
+--------------------------------------------------+
| [1] SALE DETAILS                               [2] X |
|                                                |
| [3] Product                [4] Choose product... |
|                                                |
| [4] Quantity                         [5] 1 |
|                                                |
| [5] Unit Price (as of sale date)   [6] $45.00 |
| ---                                            |
|   (read-only, computed from price history)     |
|                                                |
|                                               [7] Cancel |
|                                               [8] Add Line |
+--------------------------------------------------+
```

**Annotations:**
1. Dialog eyebrow "SALE DETAILS".
2. Close icon — closes without saving.
3. Dialog title: `"Add Line Item — T-001"` (includes sale Trans No).
4. **Product** — dropdown of active products with price history. Only products with a price effective on the sale date appear; if none, show **"no price for this date"** warning.
5. **Quantity** — number input, min 0.01, step 0.01, default 1. Shows **"quantity must be greater than 0"** if value <= 0.
6. **Unit Price** — read-only, latest effective-dated price whose effective date is on or before the sale date. If no qualifying price, show `"-"`. Does not alter price history.
7. Cancel — closes without saving.
8. **Add Line** — primary action; validates form and adds the line; refreshes details dialog, recalculating total and balance.

---

## 2. Line Item Row (in table)

```text
+------------------------------------------------------+
| P-001          | 3        | $45.00         | $135.00   | [Edit] [Delete] |
+------------------------------------------------------+
```

Columns: Product | Quantity | Unit Price (as of sale date) | **Line Total** = qty × unit price | Actions (right-aligned).

---

## 3. Running Order Total (below table)

```text
| Total: $1,250.00    |  Paid: $800.00    | Balance: $450.00 |
```

- **Total** = sum of all line totals.
- **Balance** = total minus total payments.
- Format: currency, two decimal places, thousands separator (`$1,250.00`).

---

## 4. Error Messages

### 4.1 "no price for this date"

**Trigger:** Add Line clicked, no active product has a price effective on the sale date.

**Message:** `"No active products have a price effective on this sale date. Add price to product catalog or select a different product."`

**Display:** Inline alert below product dropdown, or toast. Red-500 text with amber-500/10 background.

### 4.2 "quantity must be greater than 0"

**Trigger:** Form submitted with quantity <= 0.

**Message:** `"Quantity must be greater than 0."`

**Display:** Inline error below quantity input. Red-500 border (`border-red-500`) with red-500 focus ring (`focus:ring-2 focus:ring-red-500`). Uses `form-message` class: `border-red-500/25`, `color-red-500`, `text-sm`.

---

## 5. Tokens (S1-UIX-01)

| Token | Light | Dark | Usage |
|---|---|---|---|
| `brand-500` / `brand-600` | `#10b981` / `#059669` | Same | Primary actions, focus ring |
| `emerald-500` | `#10b981` | `#10b981` | Success states |
| `red-500` / `red-600` | `#ef4444` / `#dc2626` | Same | Error messages, error borders |
| `amber-500` | `#f59e0b` | `#f59e0b` | Warning icons |
| `gray-50` / `gray-200` / `gray-800` | `#f9fafb` / `#e5e7eb` / `#1f2937` | Same | Input bg, border |
| `rounded-xl` | `12px` | `12px` | Input corners |
| `rounded-full` | pills | pills | Badges, pill buttons |
| `focus:ring-2 focus:ring-brand-500` | focus ring | focus ring | Keyboard focus |
| `text-xs` / `text-sm` | 12px | 12px | Error message font |

---

## 6. Role/State Variants

| State | Superadmin/Admin | User |
|---|---|---|
| Add Line visible | Yes, with Sale Add right | No; view-only |
| "no price for this date" | Shown when no price on sale date | N/A |
| Quantity validation | Shown if qty <= 0 | N/A |
| Line item edit/delete | Per assigned rights | Hidden; view-only |
| Running total | Always visible | Always visible (active rows only) |

---

## 7. Gaps & Assumptions

| Topic | Source | Gap/Decision |
|---|---|---|
| Price history lookup | `sales-list.js` `updateSaleDetailPrice` | Latest active effective-dated price whose effectiveDate <= sale date; future-dated prices do not become current. |
| Product dropdown | `sales-list.js` `loadSaleOptions` | Populated from `/api/sales/options`; only active products with price history shown. |
| 36 rights matrix | `S2-UIX-05-usability-review.md` | Sale Add right gates Add Line; Sale Detail right gates Edit/Delete. |
| Effective date rule | `S4-UIX-01-wireframes-sales.md` | Sale lines use the price on the **SALE DATE** (not today's date). |
| Worked example | Task guide | `10 x 13.75 + 2 x 48.50 = 234.50` used for line-total validation. |