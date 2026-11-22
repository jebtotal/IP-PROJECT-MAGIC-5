# S3-UIX-02b — Status and Privacy Rules

*Visual rules that separate Status = Inactive from separation date, and what a user WITH and WITHOUT View Job History sees regarding salary and job history.*

---

## 1. Status = Inactive vs. Separation Date (Left the Company)

### Visual Separation Rules

| Concept | Description | Badge | Row Shading | Tooltip |
|---|---|---|---|---|
| **Inactive (soft-deleted)** | Row is soft-deleted; Status column shows "Inactive" badge. | `slate-600/10` bg with `slate-400` text, rounded-pill, uppercase `text-[10px] font-bold uppercase tracking-wider` | `bg-gray-100/50` (light) / `dark:bg-slate-950/50` (dark) | "Inactive — employee separated from company" |
| **Separation date** | Employee has a separation date on record but row remains Active. | Shown as a subtle inline label or tooltip, **not** as a status badge. No badge coloring. | No special shading (row is white/normal) | "Separation date: YYYY-MM-DD — employee left the company on this date" |
| **Both (Inactive + separation date)** | Employee is soft-deleted AND has a separation date recorded. | **Inactive badge** takes visual priority at the top of the row (red-aligned). | Row shading applies (inactive shading). | tooltip combines both: "Inactive. Separation date: YYYY-MM-DD — employee left the company on this date." |

### Example: Employee Who Is Both Inactive and Has a Separation Date

```
[E001] Maria Santos  [ Inactive ]  ← slate-600/10 badge, uppercase tracking-wider
Sep. Date: 2024-03-15  ← inline label, no badge styling, normal text color
[Actions]
```

- The **Inactive badge** is visually distinct (colored pill) and appears before the separation date.
- The **separation date** appears as a plain inline text label with a tooltip on hover.
- If the user hovers over the separation date, a tooltip reveals the full meaning: *"Separation date: 2024-03-15 — employee left the company on this date."*
- Row has inactive shading (`bg-gray-100/50` / `dark:bg-slate-950/50`).

### Badge & Tooltip Specifications

- **Badge class pattern** (from design system): `inline-flex items-center gap-1 px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ...`
- **Active badge**: `brand-500/10` bg with `brand-500` text
- **Inactive badge**: `slate-600/10` bg with `slate-400` text
- **Tooltip**: `tooltip-text` using absolute positioning or `title` attribute; consistent with other tooltips in the system (emerald/amber/red info styling)

### Guide Fact: Data Privacy Act (RA 10173)

> Salary and job history are **hidden** from users without the `View Job History` right. The exact "no access" message references RA 10173.

### User WITH View Job History Right

| Element | Visibility | Notes |
|---|---|---|
| **Salary field** | Fully visible as numeric currency value | No masking or redaction |
| **Job History section** | Full chronological timeline visible | Includes job titles, departments, effective dates, salary history |
| **Stamp History** | CREATED/EDITED/DELETED/RESTORED + user + datetime | Visible for all entries |
| **Job History button** (on profile) | Enabled, opens add/edit/delete dialog | |

### User WITHOUT View Job History Right

| Element | Visibility | Exact "no access" message |
|---|---|---|
| **Salary field** | **Masked / redacted** — shows `*****` or `---` placeholder | `"Salary data is confidential per RA 10173 (Data Privacy Act). You do not have permission to view salary information."` |
| **Job History section** | **Collapsed/hidden** — section is not rendered, or shows placeholder | `"Job History is not available per RA 10173 (Data Privacy Act). You do not have permission to view job history."` |
| **Stamp History** | Shows `"—"` placeholder only | No user/datetime details exposed |
| **Job History button** (on profile) | Disabled/hidden | No access to open the job history form |
| **Salary edit capability** | Not applicable — field not visible | — |

### "No Access" Message Format (PROPOSED, not in reference)

```
<span class="text-[10px] text-red-500 font-medium mt-2">
  Salary data is confidential per RA 10173 (Data Privacy Act). You do not have permission to view salary information.
</span>
```

or for job history section:

```
<div class="pt-4 text-[10px] text-gray-500">
  Job History is not available per RA 10173 (Data Privacy Act). You do not have permission to view job history.
</div>
```

### Visual Differences per Role

| Role | Salary visible? | Job History visible? | Stamp history detail? | Job History button? |
|---|---|---|---|---|
| **Superadmin** | Yes | Yes | Full (CREATED/EDITED/DELETED/RESTORED) | Yes, enabled |
| **Admin** (with right) | Yes | Yes | Most entries (restricted from User rows) | Yes, enabled |
| **Admin** (without right) | Masked | Hidden | `"—"` placeholder | Hidden |
## Gaps & Assumptions

- All color tokens and badge patterns follow the S1-UIX-01 design system (emerald `brand-500`/`emerald-500`, slate `slate-600`/`slate-400`, red `red-500`).
- The "no access" messages referencing RA 10173 are **PROPOSED** (not in the reference HTML).
- Tooltip behavior for separation date vs. inactive badge follows the existing toast/tooltip patterns from the reference (small, dismissable, or `title` attribute).
- Row shading for deleted/inactive rows follows the `bg-gray-100/50` / `dark:bg-slate-950/50` pattern from S2UX status badge rules.
- Effective date "current price = latest effective date not in the future" and "a sale line uses the price on the SALE DATE" are orthogonal to this document and not addressed here.

---
| **User** | Masked | Hidden | `"—"` placeholder | Hidden |

### Masking Pattern for Salary (PROPOSED)

When salary is hidden without the right:

- **Input/Display field**: `value="***"` or `value="---"` (three placeholder characters)
- **Container**: grayed-out or muted appearance, `opacity-50`/`dark:opacity-50`, `not-allowed` cursor
- **Tooltip on hover**: `"Salary data is confidential per RA 10173 (Data Privacy Act)."`### Guide Fact: Data Privacy Act (RA 10173) 

---
*Visual rules that separate Status = Inactive from separation date, and what a user WITH and WITHOUT View Job History sees regarding salary and job history.*

---