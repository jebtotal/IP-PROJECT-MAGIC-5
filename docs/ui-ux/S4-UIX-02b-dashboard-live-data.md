# S4-UIX-02b — Dashboard Live Data

**Purpose:** Specify live data dashboard behavior per role, card meanings, states, and right-gated visibility. Uses the existing PentadERP design-system tokens (S1-UIX-01) and the reference dashboard layout from `PentadERP_index (FINAL).html`.

## 1. Overview

The dashboard is the home page after login. It shows four executive summary cards, a revenue performance chart, and quick-navigation links. All data is live-fetched or computed from the current user's accessible data. Card content and quick-action links are right-gated by the 36-permission matrix (Customer 3; Product 6 incl. prices; HR 13 incl. View/Add/Edit/Delete Job History; Sales 7 incl. Sale Detail; Reports 7).

The reference dashboard (lines 1248-1271 of the HTML) uses `.glass-panel` stat cards, a `<canvas>` revenue chart, and pill-styled quick-navigation buttons. This document specifies how each element adapts per role (Superadmin / Admin / User) and defines loading, zero-data, and error states.



Each stat card uses the `.glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80 glow-hover` pattern. The grid is `sm:grid-cols-2 lg:grid-cols-4` (four cards on large screens, two on medium).

| Card | Meaning (what it counts) | Superadmin | Admin | User |
|------|--------------------------|------------|-------|------|
| **Total Customers** | Number of non-deleted customers (active only). Inactive count shown in parentheses alongside the value. | ✅ Visible with full count + inactive count. | ✅ Visible with full count + inactive count. | ✅ Visible with **active-only count** (deleted rows hidden); no inactive count shown. |
| **Products** | Number of active (non-deleted) products in the catalog. Current price = latest effective date not in the future. | ✅ Visible with count. Current price shown per product elsewhere. | ✅ Visible with count. | ✅ Visible with **active-only count**; price info hidden without `products.view` right. |
| **Open Orders** | Number of non-deleted sales (open sales pipeline). Total = Σ(qty × price where price is the price on the SALE DATE). | ✅ Visible with count. | ✅ Visible with count. | ✅ Visible with **open-only count**; no price breakdown shown without `sales.view` right. |
| **Revenue (MTD)** | Month-to-date revenue total. In the reference: `$84,250.00` with `↑ +18.4% growth`. Computed from completed sale lines where the sale date falls in the current month and the price on that date is used. | ✅ Visible with value + growth arrow. | ✅ Visible with value + growth arrow. | ✅ Visible with value + growth arrow **only if `reports.view` right is held**; otherwise shown as `"—"` with a note that reports access is restricted. |

> **Note:** User role sees active-only counts on the Customers, Products, and Open Orders cards, and sees "—" only on the Revenue (MTD) card, and on price/total details when the matching `.view` right is missing.

## 3. Quick Actions Per Role

Below the card grid is a secondary column (on `lg:grid-cols-3`) with quick-navigation pills. Each pill uses the `qn()` helper pattern from the reference: `<button class="w-full p-3.5 rounded-2xl ..."><span>...</span><i class="fa-solid fa-chevron-right"></i></button>`.

| Quick Action | Superadmin | Admin | User |
|---|---|---|---|
| **View Customers** | ✅ Visible | ✅ Visible | ✅ Visible if `customers.view` right; otherwise **hidden** (button not rendered). |
| **Manage Products** | ✅ Visible | ✅ Visible | ✅ Visible if `products.view` right; otherwise **hidden**. |
| **Human Resources** | ✅ Visible | ✅ Visible | ✅ Visible if `hr.view` right; otherwise **hidden**. Note: salary and job history are masked without `hr.jobHistory` right (Data Privacy Act RA 10173). |
| **Sales Pipeline** | ✅ Visible | ✅ Visible | ✅ Visible if `sales.view` right; otherwise **hidden**. |
| **Reports** | ✅ Visible | ✅ Visible | ✅ Visible if `reports.view` right; otherwise **hidden**. 7 report types with date-range + Top N filters; Print/Save as PDF per-report. |
| **Manage Users** | ✅ Visible (Superadmin only) | ❌ Hidden | ❌ Hidden |

> **What a User sees for modules they lack rights to:** When a user opens the dashboard without a required right, the corresponding quick-action button simply does not render. Navigating to the module via the sidebar shows a "Coming soon" state or an informational toast: "You do not have permission to view this module. Contact an Admin to assign rights."

## 4. Loading / Zero-Data / Error States

| State | Description | UI Pattern |
|---|---|---|
| **Loading** | Dashboard data is being fetched. Skeleton placeholders (animate-pulse) inside each card while data loads, for at most 500ms or until data arrives. | Skeleton placeholders (animate-pulse) inside each card for at most 500ms or until data arrives. |
| **Zero-Data** | No records match the role's accessible set. | Card shows `"—"` centered with `text-gray-500 dark:text-gray-400 text-xs font-medium` and caption: `"No active records."` (per S1-UIX-01 empty-state pattern). |
| **Error** | Data fetch failed (network or auth). | Toast error (`bg-red-600 text-white`) surface: `"Unable to load dashboard data. Try again."`. Cards remain in last-known state or show `"—"`. |
## 5. Role-Based Visibility Rules

The dashboard uses the existing `can()` and `canModule()` permission checks from the reference JS (`lines 1061-1069`). The sidebar `renderSidebar()` function already gates module navigation; the dashboard home follows the same logic.

| Element | Superadmin | Admin | User |
|---|---|---|---|
| **Total Customers card** | ✅ Visible | ✅ Visible | ✅ Visible (active-only) |
| **Products card** | ✅ Visible | ✅ Visible | ✅ Visible (active-only) |
| **Open Orders card** | ✅ Visible | ✅ Visible | ✅ Visible (open-only) |
| **Revenue (MTD) card** | ✅ Visible | ✅ Visible | ✅ Visible if `reports.view`; otherwise `"—"` |
| **Revenue chart** | ✅ Visible with full data | ✅ Visible with full data | ✅ Visible if `reports.view`; otherwise `"—"` placeholder |
| **Quick-View Customers button** | ✅ Visible | ✅ Visible | ✅ if `customers.view` else ❌ |
| **Quick-View Products button** | ✅ Visible | ✅ Visible | ✅ if `products.view` else ❌ |
| **Quick-View HR button** | ✅ Visible | ✅ Visible | ✅ if `hr.view` else ❌ |
| **Quick-View Sales button** | ✅ Visible | ✅ Visible | ✅ if `sales.view` else ❌ |
| **Quick-View Reports button** | ✅ Visible | ✅ Visible | ✅ if `reports.view` else ❌ |
| **Quick-View Manage Users button** | ✅ Visible | ❌ Hidden (Admin cannot manage users) | ❌ Hidden |
## 6. Design Tokens (S1-UIX-01)

All card styling uses the reference's existing tokens:

| Token | Light | Dark | Usage |
|---|---|---|---|
| `bg-card` / `--bg-card` | `#ffffff` | `#292524` | `.glass-panel` background |
| `text-main` / `--text-main` | `#292524` | `#f5f5f4` | Card values (large numeric text) |
| `text-muted` / `--text-muted` | `#78716c` | `#a8a29e` | Card captions ("inactive", "Active-only") |
| `brand-500` / `brand-600` | `#10b981` / `#059669` | Same | Primary actions, growth arrow color |
| `emerald-500` | `#10b981` | `#10b981` | Success states, active indicators |
| `amber-500` | `#f59e0b` | `#f59e0b` | Warning indicators |
| `red-500` | `#ef4444` | `#dc2626` | Error states |
| `gray-50` / `gray-100` / `gray-800` | `#f9fafb` / `#e5e7eb` / `#1f2937` | Same | Table headers, borders |
| `rounded-3xl` | `24px` | `24px` | Card corners |
| `p-6` | `24px` | `24px` | Card padding |
| `glow-hover` | Emerald-tinted shadow on hover | Dark emerald-tinted shadow on hover | Card hover transition |
| `sm:grid-cols-2 lg:grid-cols-4` | 2-column mobile, 4-column desktop | Same | Card grid layout |
| `text-xs` / `text-sm` | 12px / 14px | Same | Captions and small text |

The revenue chart uses hard-coded `#6366f1` → `#4338ca` (indigo scale) bars per the reference inconsistency noted in S1-UIX-01 §9; this is preserved as `"as-in-reference"` and not remapped to the brand palette.
## 7. Gaps & Assumptions

- **Live data not yet wired:** The reference dashboard uses sample numbers (`$84,250.00`, `94 Sales`, `↑ +18.4% growth`). This document describes the live-data spec; actual data fetching (`/api/dashboard`, `/api/revenue-mtd`, etc.) is backend work. Frontend readiness is marked per the token and state patterns above.
- **Price effective-date rule:** Current price = latest effective date not in the future; a sale line uses the price on the SALE DATE. This rule governs the Products and Revenue cards but is not implemented in the reference's static sample values.
- **User-rights gating:** The `can()` / `canModule()` JS functions exist in the reference; this document assumes they are functional and documents the visual result of their outcomes.
- **Seven reports:** Per the guide facts, there are 7 reports with date-range + Top N filters and per-report rights. The dashboard quick-action links to these; individual report specs are outside this document's scope.
- **Audit stamp:** Admin/Superadmin views include CREATED/EDITED/DELETED/RESTORED + user + datetime stamps on data rows; the dashboard cards themselves do not display stamps (they are summary counts).
- **Dark mode:** All tokens have dark-mode pairings via the `.dark` class on `<html>`, as documented in S1-UIX-01 §70-82. The dashboard adapts automatically.
## 8. Version

S4-UIX-02b — Draft (Sprint 4). Follows S1-UIX-01 design-system tokens and the PentadERP reference dashboard layout.