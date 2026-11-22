# S3-UIX-03b — HR Tabs Responsive

**Purpose:** Employees / Jobs / Departments tab bar with responsive tables, dark-mode contrast, modal sizing, and sidebar collapse. Based on built `employee_profile.html` shell and reference classes.

---

## 1. Tab Bar

### Markup

```html
<nav class="record-tabs" aria-label="Human Resources lists">
  <a class="record-tab is-active" href="/human-resources/employees" role="tab" aria-selected="true" aria-label="Employees">Employees <span data-count="active">0</span></a>
  <a class="record-tab" href="/human-resources/jobs" role="tab" aria-selected="false" aria-label="Jobs">Jobs <span data-count="inactive">0</span></a>
  <a class="record-tab" href="/human-resources" role="tab" aria-selected="false" aria-label="Departments">Departments <span data-count="all">0</span></a>
</nav>
```

### Active state (`.is-active`)

- `background: linear-gradient(110deg, #059669, #c2410c)` (brand-600 → indigo-600)
- `color: #fff`
- `border-color: transparent`
- `font-weight: 800`, `font-size: 0.68rem`, `uppercase tracking-wider`
- `min-height: 2.2rem`, `padding: 0.45rem 0.8rem`, `gap: 0.45rem`

### Keyboard

- `role="tab"`, `aria-selected`, `aria-label` on each `<a>`
- `aria-label="Human Resources lists"` on `<nav>`
- Focus ring: `focus:ring-2 focus-ring-brand-500`

### Rights hiding

- Tab `<a>` simply not rendered if user lacks right — no `hidden` attribute
- If all HR tabs hidden, `<nav>` omitted entirely

### Count chips

- `data-count="active"` / `data-count="inactive"` / `data-count="all"`
- `text-[10px] font-bold uppercase tracking-wider`
- `brand-500/10` / `brand-500` light; `amber-500/10` / `amber-500` dark
- Hidden when count is 0

---

## 2. Responsive Tables

| Breakpoint | Behavior |
|---|---|
| **lg / md** | `<table>` inside `<div class="table-wrap overflow-x-auto">` — horizontal scroll if needed |
| **sm / xs** | Stacked cards: each row → `.glass-panel` card with vertical key-value pairs |

**Card (sm/xs):** `<article class="glass-panel p-4 mb-3 rounded-2xl border border-gray-200/60 dark:border-gray-800/60">...</article>`

---

## 3. Modal Sizing

| Breakpoint | Width | Max-Height |
|---|---|---|
| **lg+** | `max-w-3xl` | `max-h-[80vh]` |
| **md** | `max-w-2xl` | `max-h-[70vh]` |
| **sm** | `max-w-md` | `max-h-[60vh]` |
| **xs** | `max-w-sm` | `max-h-[50vh]` |

All: `rounded-3xl`, `p-8`, overlay `rgba(28,25,23,0.65)`, `backdrop-filter: blur(4px)`.

---

## 4. Sidebar Collapse

| State | Width | Aria-label |
|---|---|---|
| **Expanded** | `w-64` | `Main navigation` |
| **Collapsed** | `w-16` | `Sidebar collapsed` |
| **Minimized** | `w-20` | `Sidebar minimized` |

- **lg+**: Collapse button visible in sidebar; toggles `w-16`
- **md**: Auto-collapses to `w-16` on load
- **sm / xs**: Hidden; header ☰ toggles full-screen modal

**Focus ring:** `focus:ring-2 focus-brand-500` on nav links.

---

## 5. Dark-Mode Contrast

| Element | Light | Dark |
|---|---|---|
| Active tab | `gradient #059669 → #c2410c`, white text | `gradient`, `dark:text-brand-400` on `bg-brand-500/10` |
| Inactive tab | `border-gray-200`, `text-gray-600` | `border-gray-700/60`, `text-gray-300` |
| Table wrapper | default | `dark:border-gray-800/50` |
| Card | `bg-white`, `border-gray-200/60` | `bg-slate-900/80`, `dark:border-gray-800/60` |
| Focus ring | `focus-brand-500` | same (visible) |
| Modal overlay | `rgba(28,25,23,0.65)` | `rgba(28,25,23,0.7)` |

---

## 6. Gaps & Assumptions

- Tab right-conditionality is **Developer-owned** — UI designer cannot modify .py, routes, form actions, field names, IDs, or CSRF tokens. This spec documents the visual behavior when tabs are absent.
- Table → card transition at `sm` (640px) is breakpoint-driven; JS may supplement.
- Modal interactivity (focus trap, escape key) is developer-wired; spec documents markup & sizing.
- Sidebar collapse JS (class toggling, `aria-pressed`) is outside UI designer scope; spec defines CSS tokens & class names.
- Count chips populated by backend; UI specifies token sizes and opacity backgrounds.
- Built `employee_profile.html` already has tab navigation; this spec documents responsive/dark behavior.