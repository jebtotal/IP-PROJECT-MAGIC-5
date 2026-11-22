# S4-UIX-03b — Print Layout Specification

Print stylesheet spec for the 7 PentadERP reports. Based on the reference's `@media print` blocks and guide facts.

**Base design:** Reference contains two `@media print` blocks:
1. **Block A:** Hides non-print elements using `visibility: hidden` or `display: none`
2. **Block B:** Resets colors to forced black text, white background, transparent borders (`#ddd` override)

**Recommendation:** Use **Block B** (colour reset) as the base print stylesheet. This ensures consistent black-text/white-page output across all reports and avoids unexpected color inheritance from the light/dark theme.

---

## 1. Print Stylesheet Rules

### Base Rules (from Block B - recommended)

```css
@media print {
  /* Force light theme - hide dark mode indicators */
  .dark { display: none !important; }
  html { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
  
  /* Hide sidebar, tabs, and action buttons */
  .sidebar, .tabs, .btn, .action-column, .glass-panel:not(#reportPrintArea) {
    display: none !important;
  }
  
  /* Force white background and black text on body and table elements */
  body, #reportPrintArea {
    background: #fff !important;
    color: #000 !important;
  }
  
  /* Transparent descendants/borders (per reference #ddd override) */
  *,
  *::before,
  *::after {
    background: transparent !important;
    color: #000 !important;
    box-shadow: none !important;
    text-shadow: none !important;
  }
  
  /* Override border color */
  border-color: #000 !important;
  
  /* Hide skip links and non-report navigation */
  a[href^="#"], .skip-link { display: none !important; }
}
```

### Report-Specific Print Rules

Each of the 7 reports will print as a standalone page with:

- **Header:** Report title, date range filters (if applicable), generated date, user role
- **Table:** Full table data with headers; table header repeats on each page
- **No sidebar:** Navigation sidebar hidden
- **No tabs:** Report selection tabs hidden
- **No print button:** Print button not included on printed page (already triggered the print)
- **Forced light theme:** `.dark` hidden, color adjustments forced

---

## 2. Per-Report Print Header Specification

### Format: `Report Title | Date Range | Generated: YYYY-MM-DD | User: [role]`

| Report | Header Elements |
|--------|----------------|
| **Product Master List** | "Product Master List · Generated: 2024-01-15 · User: Superadmin" |
| **Active Employees** | "Active Employees · Generated: 2024-01-15 · User: Admin" |
| **All Employees** | "All Employees · Generated: 2024-01-15 · User: Admin" |
| **Employee Job History** | "Employee Job History: [Employee Name] · Generated: 2024-01-15 · User: Admin" |
| **Top Customers** | "Top Customers · From: 2024-01-01 · To: 2024-12-31 · Top N: 10 · Generated: 2024-01-15 · User: Admin" |
| **Top Products** | "Top Products · From: 2024-01-01 · To: 2024-12-31 · Top N: 10 · Generated: 2024-01-15 · User: Admin" |
| **Top Sales** | "Top Sales · From: 2024-01-01 · To: 2024-12-31 · Top N: 10 · Generated: 2024-01-15 · User: Admin" |

**Header styling:**
- `text-lg font-bold tracking-wider uppercase mb-4`
- Print color: `text-black`
- Background: `bg-white`
- Margin: `py-3 border-b border-gray-200` (light mode) / `border-gray-800` (dark mode, but forced light)

---

## 3. Margins and Page Layout

- **Page margins:** `sm:pr-6 pl-6` (side margins for printer-friendly width)
- **Container max-width:** `max-w-7xl mx-auto` (centers print output)
- **Table layout:** Full-width table with `overflow-x-auto` wrapper hidden (table fits page width)
- **Header repetition:** `<thead>` repeats on each page via `page-break-inside: avoid` on `<tbody>`
- **No row splits:** `<tr>` not split across pages; use `page-break-inside: avoid`
- **Force light theme:** `.dark` hidden, theme toggle not printed

---

## 4. Print Button Trigger

- **Button:** `#report-print` with text "Print / Save as PDF"
- **Action:** On click, runs `window.print()` which applies the `@media print` stylesheet
- **Print area:** `#reportPrintArea` element is the only visible content; all other page content is hidden
- **Save as PDF:** User browser's "Save as PDF" option available after print dialog

**Print CSS activates when:**
- `window.print()` is called
- OR browser prints from `Ctrl+P` / `Cmd+P`
- The `#reportPrintArea` becomes the sole printed content

---

## 5. Changes PROPOSED (vs Reference)

The reference HTML has a single `@media print` block that:
- Hides all page content except `#reportPrintArea`
- Positions `#reportPrintArea` at top-left at full width
- Forces `color: black`, `background: white`, `border-color: transparent`

**Proposed enhancements:**
1. **Forced light theme:** `.dark` hidden explicitly; `print-color-adjust: exact` ensures consistent output
2. **Sidebar/tabs/buttons hidden:** Additional `display: none` rules for print consistency
3. **Header with title/filters/date/user:** Added header block on each printed report
4. **Table header repeats per page:** CSS rule for `page-break-after: header` on `<thead>`
5. **No row splits:** `page-break-inside: avoid` on all `<tr>` elements
6. **Transparent descendant borders:** `* { background: transparent !important; }` per reference's `#ddd` override, but enhanced to `#000` for clarity

**Base recommendation:** Use the reference's Block B (colour reset) as the foundation, then add the proposed enhancements on top.

---