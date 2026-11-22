# S3-UIX-03 — Job Timeline

**Purpose:** Employee career history job timeline, newest first with "Current" badge.

**Root:** `docs/ui-ux/mockups/s3/job-timeline.html` (light & dark)

---

## 1. Anatomy

Light: `<div class="job-timeline" aria-label="Employee job timeline"><ol class="job-timeline-list ..."><li class="job-timeline-item is-current"><article class="job-timeline-card"><header><h4 class="job-timeline-job-title">...</h4><p class="job-timeline-dept">...</p></header><div class="job-timeline-meta"><dt class="sr-only">Effective date</dt><dd>2023-01-01</dd><div class="job-timeline-badge"><span class="badge badge-current">Current</span></div></div></article></li>...</ol><p class="job-timeline-empty">No job history...</p></div>`

Dark: same structure, colors shift via `.dark` class and CSS vars (`--bg-main: #1c1917`, etc.)

---

## 2. Tokens (S1-UIX-01)

| Token | Light | Dark | Usage |
|---|---|---|---|
| `brand-500` | `#10b981` | `#10b981` | Job title text |
| `brand-600` | `#059669` | `#059669` | Current badge |
| `brand-500/10` | `rgba(16,185,129,0.1)` | `rgba(16,185,129,0.1)` | Badge overlay |
| `slate-50` | `#f5f5f4` | `#f5f5f4` | Light surface |
| `slate-600` | `#44403c` | `#44403c` | Muted text |
| `slate-800` | `#1c1917` | `#1c1917` | Dark surface |
| `gray-50` | `#f9fafb` | `#f9fafb` | List divider |
| `gray-400` | `#9ca3af` | `#9ca3af` | Muted labels |
| `rounded-xl` | `12px` | `12px` | Card corners |
| `rounded-full` | pills | pills | Badges |
| `p-3` / `p-4` / `p-6` | spacing | spacing | Cell padding |
| `focus:ring-2 focus:ring-brand-500` | focus ring | focus ring | Keyboard focus |

---

## 3. States

| State | Treatment |
|---|---|
| **Current** | `.badge-current` on newest entry; `font-semibold` on job title |
| **Promotion** | `fa-solid fa-arrow-up` + text "Promotion"; `aria-label` on icon |
| **Transfer** | `fa-solid fa-exchange-alt` + text "Transfer"; `aria-label` on icon |
| **Empty** | `job-timeline-empty` centered, `text-gray-500`, `p-6` |
| **Hidden salary** | Not rendered (RA 10173) |
| **Focus** | `focus:ring-2 focus:ring-brand-500` |
| **Dark mode** | `.dark` class shifts all tokens |

---

## 4. Accessibility

- `aria-label="Employee job timeline"` on container
- `aria-current="page"` on current entry
- `aria-hidden="true"` on decorative marker
- `sr-only` label for effective date
- `aria-label="Promotion"` / `aria-label="Transfer"` on icons
- `focus:ring-2 focus:ring-brand-500` on focus
- WCAG AA contrast via token palette

---

## 5. Data Fields

| Field | Type | Example |
|---|---|---|
| `jobTitle` | string | "Senior Software Engineer" |
| `departmentName` | string | "Engineering" |
| `effDate` | date | "2023-01-01" |
| `status` | enum | "Current" |
| `promotionTransfer` | enum | "promotion" / "transfer" |
| `salary` | decimal | **HIDDEN** per RA 10173 |

Sample: Maria Santos, 2020-03-01 $45,000 / 2023-01-01 $52,000

---

## 6. Mobile

- Stacks vertically below `sm` breakpoint
- Reduces padding to `p-3`
- Single column, no horizontal scroll
- Empty state full-width

---

## 7. Rights

User: active rows only, salary hidden. Admin/Superadmin: separate specs with tabs + stamp column.

---

## 8. Gaps & Assumptions

- Salary omitted entirely (RA 10173)
- Promotion/Transfer: icon + visible text, not colour alone
- Empty state reuses `table-message` pattern (`p-6`, muted)
- `sm` breakpoint for mobile
- No JS in static mockup