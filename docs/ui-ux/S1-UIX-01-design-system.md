# S1-UIX-01 — PentadERP Design System

This document records the design as implemented in `PentadERP_index (FINAL).html`, including its Tailwind CDN configuration, global CSS, component classes, and inline JavaScript-rendered views. It describes the reference; it does not normalize or correct its inconsistencies.

> **Reference location:** The expected `Private-Design-Reference` folder was not present in the workspace. The exact named HTML file was available read-only at `reference_html/PentadERP_index (FINAL).html` and was used as the source. No pre-existing `docs/ui-ux/` token document was present.

## 1. Color palette

Tailwind is loaded from its CDN and extended in `tailwind.config`. The `indigo`, `sky`, and `slate` scales below are explicitly remapped; their class names do **not** mean Tailwind's stock colors. `gray`, `red`, `amber`, and `emerald` are not remapped in this configuration and retain the standard Tailwind values shown below.

### Configured Tailwind color values

| Tailwind class name | Real HEX | Where it is used |
|---|---:|---|
| `brand-50` | `#ecfdf5` | Configured emerald tint; no specific use identified in the reference markup. |
| `brand-100` | `#d1fae5` | Configured emerald tint; no specific use identified in the reference markup. |
| `brand-200` | `#a7f3d0` | Configured emerald tint; no specific use identified in the reference markup. |
| `brand-500` | `#10b981` | Emerald accent, links, soft backgrounds, focus rings, chart/status labels, and hover state for primary buttons. |
| `brand-600` | `#059669` | Main emerald action color; primary buttons, toast info, active tabs/nav gradients, and the brand end of gradients. |
| `brand-700` | `#047857` | Welcome banner gradient start. |
| `brand-800` | `#065f46` | Configured emerald shade; no specific use identified in the reference markup. |
| `brand-900` | `#064e3b` | Configured emerald shade; no specific use identified in the reference markup. |
| `indigo-400` | `#f97316` | Terracotta/orange stop in the hero gradient text. |
| `indigo-500` | `#ea580c` | Terracotta/orange in gradients, avatar gradient, quick-navigation/stat accents. |
| `indigo-600` | `#c2410c` | Terracotta/orange gradient stop paired with `brand-600` in buttons and active navigation. |
| `sky-400` | `#fb923c` | Warm-orange stop in hero gradient text. |
| `sky-500` | `#f97316` | Configured warm-orange shade; no distinct use identified in the reference markup. |
| `slate-50` | `#f5f5f4` | Warm stone shade; used as an application-surface utility. |
| `slate-100` | `#e7e5e4` | Warm stone shade; also the light `--border-color` value. |
| `slate-200` | `#d6d3d1` | Configured warm stone shade; no specific use identified in the reference markup. |
| `slate-300` | `#a8a29e` | Warm gray/stone shade; same HEX as the dark `--text-muted` value. |
| `slate-400` | `#78716c` | Muted warm gray/stone text shade; also the light `--text-muted` value. |
| `slate-500` | `#57534e` | Configured warm charcoal shade; no specific use identified in the reference markup. |
| `slate-600` | `#44403c` | Configured warm charcoal shade; no specific use identified in the reference markup. |
| `slate-700` | `#292524` | Warm charcoal surface and light `--text-main`. |
| `slate-800` | `#1c1917` | Deep charcoal; dark `--bg-main`. |
| `slate-850` | `#171412` | Custom charcoal hover surface. |
| `slate-900` | `#0c0a09` | Very dark charcoal; used by selected near-black surfaces. |
| `slate-950` | `#000000` | Black; sidebar and deep dark surfaces. |

The selected neutral and semantic utilities below are unmodified Tailwind colors:

| Tailwind class name | Real HEX | Where it is used |
|---|---:|---|
| `gray-50` | `#f9fafb` | Light table headers, quick-navigation surfaces, and soft section backgrounds. |
| `gray-100` | `#f3f4f6` | Table headers, inactive tabs, and read-only input background. |
| `gray-200` | `#e5e7eb` | Light borders and dividers. |
| `gray-300` | `#d1d5db` | Light-mode outline border on secondary controls. |
| `gray-400` | `#9ca3af` | Muted labels, captions, and empty-state text. |
| `gray-500` | `#6b7280` | Muted body copy and inactive controls. |
| `gray-600` | `#4b5563` | Secondary body text and table headings. |
| `gray-700` | `#374151` | Secondary/outline button text. |
| `gray-800` | `#1f2937` | Dark-mode borders and dividers. |
| `gray-900` | `#111827` | Strong text on light surfaces. |
| `red-500` | `#ef4444` | Error text, tinted delete actions, and error message treatment. |
| `red-600` | `#dc2626` | Error toast and confirm-modal danger action. |
| `red-700` | `#b91c1c` | Hover state for the confirm-modal danger action. |
| `amber-400` | `#fbbf24` | Dark-mode sun icon and warning icon. |
| `amber-500` | `#f59e0b` | Warning toast, warning badges, and Superadmin role badge. |
| `amber-600` | `#d97706` | Superadmin quick-login hover state. |
| `emerald-400` | `#34d399` | Positive/check accents. |
| `emerald-500` | `#10b981` | Success and active-status text/tints, User role badge, revenue accents. |
| `emerald-600` | `#059669` | Success toast and User quick-login button. |
| `white` | `#ffffff` | Light surfaces, button text, and text on dark/colored controls. |

Opacity modifiers preserve the base color while applying the listed alpha (for example `bg-brand-500/10` is `#10b981` at 10% opacity). They appear on tinted badges, alert blocks, borders, and soft action buttons.

### Theme variables

The HTML starts with `.dark` on the root `<html>` element; the theme toggle changes that class. It drives the following CSS variables. Tailwind's `darkMode` is configured as `class`.

| CSS variable | Light (`:root`) | Dark (`.dark`) | Primary use |
|---|---|---|---|
| `--bg-main` | `#fafaf9` | `#1c1917` | Page/application background. |
| `--bg-surface` | `#ffffff` | `#292524` | General surface token. |
| `--bg-card` | `#ffffff` | `#292524` | `.glass-panel` card background. |
| `--border-color` | `#e7e5e4` | `rgba(255, 255, 255, 0.05)` | `.glass-panel` border. |
| `--text-main` | `#292524` | `#f5f5f4` | Body text. |
| `--text-muted` | `#78716c` | `#a8a29e` | Muted text token. |
| `--accent-glow` | `rgba(5, 150, 105, 0.1)` | `rgba(5, 150, 105, 0.2)` | Emerald glow token. |

Most individual components also use explicit Tailwind `gray-*`, `slate-*`, and semantic color classes rather than these variables, so those elements switch themes through paired `dark:` utilities.

### Status and role colors

| State / role | Treatment in the reference |
|---|---|
| Success / active | Emerald: `emerald-500` text (`#10b981`) on `emerald-500/10`; success toasts use `emerald-600` (`#059669`) with white text. |
| Error / destructive | Red: `red-500` text (`#ef4444`) on `red-500/10`; error toasts and the confirm action use `red-600` (`#dc2626`), with confirm hover `red-700` (`#b91c1c`). |
| Warning / pending / blocked | Amber: `amber-500` (`#f59e0b`), usually on `amber-500/10`; warning toasts use a solid amber background. Pending and blocked user statuses share the same non-active amber treatment. |
| Info | `brand-600` (`#059669`) solid toast with white text. |
| Superadmin | Amber `amber-500/10` background and `amber-500` text. |
| Admin | Brand `brand-500/10` background and `brand-500` text (`#10b981`). |
| User | Emerald `emerald-500/10` background and `emerald-500` text (`#10b981`). |

The marketing role cards use the role-specific badge colors above. The application header's dynamic role badge instead always declares the brand tint/text treatment.

## 2. Typography

- **Family:** DM Sans, loaded from Google Fonts with an italic and variable-weight range of 100–1000. Tailwind's `font-sans` is set to `"DM Sans", system-ui, sans-serif`; `body` also declares `'DM Sans', system-ui, sans-serif`.
- **Hierarchy and sizes:** Common text uses Tailwind `text-xs` (12px). Labels and badges use `text-[10px]`; some small values/captions use `text-[11px]`. Body copy also uses `text-sm` (14px), `text-base` (16px), and marketing copy scales to `sm:text-lg` (18px). Application page titles use `text-lg` (18px); dashboard welcome and modal headings use `text-2xl` (24px); section headings scale from `text-2xl` (24px) to `sm:text-3xl` (30px). Hero display text scales through `text-4xl` to `lg:text-6xl` (36–60px).
- **Weights:** `font-medium` (500) for supporting emphasis, `font-semibold` (600), `font-bold` (700), `font-extrabold` (800), and `font-black` (900) for strong headings, values, and prominent badges.
- **Tracking/case:** `tracking-tight` (`-0.025em`) on headings and wordmarks; `tracking-wider` (`0.05em`) on uppercase labels, buttons, and badges; `tracking-widest` (`0.1em`) on selected micro-labels. Uppercase is common for labels and controls.
- **Roles in the hierarchy:** Page titles are compact and bold; section/modal titles are larger and black-weight; table headers are small uppercase bold; field labels are 10px uppercase bold; body copy is generally 12–14px; captions and badges are 10–11px.

## 3. Buttons

The global CSS rule `button { border-radius: 9999px !important; }` overrides Tailwind's per-button `rounded-xl`, `rounded-2xl`, etc. All actual `<button>` elements render as pills, while non-button elements retain their declared radius.

- **Primary:** Solid `brand-600` (`#059669`) with white text; hover commonly changes to `brand-500` (`#10b981`). Forms use full-width `py-3`, bold 12px uppercase tracking, and often an emerald-tinted shadow.
- **Secondary / outline:** Transparent or white/dark surface, neutral border (`gray-200` / `gray-800`), gray text, and a light or charcoal hover fill. Some text-only controls have no border and change text color on hover.
- **Danger:** Confirm action uses solid `red-600` with `red-700` hover and a red shadow. Table delete actions use soft `red-500/10` with `red-500` text.
- **Soft/tinted actions:** Small table actions use brand-tinted or red-tinted fills; typical compact padding is `px-2 py-1` to `px-3 py-1.5`, with 10–12px bold text.
- **Icon controls:** Theme and mobile-menu controls use padded neutral outlines or transparent hover fills; Font Awesome icons are centered and sized with text utilities. The password visibility control is a small, unfilled icon button positioned inside the field.
- **Pill controls and tabs:** Billing and HR/report tabs have compact padding; selected tabs use solid `brand-600` and white text, while unselected tabs use a gray/near-black fill and muted text.
- **Gradient buttons:** The hero CTA and active sidebar use `brand-600`→`indigo-600`, which resolves to emerald `#059669`→terracotta `#c2410c`. The hero CTA has a lift-on-hover treatment; selected primary controls use shadows.
- **Quick login:** Superadmin is amber (`amber-500`); Admin is brand green (`brand-600`); User is emerald (`emerald-600`). Each has white bold compact text and a darker hover shade where specified.
- **Hover, active, disabled:** Hover styling and transitions are present, including background/text changes, shadow, and occasional `-translate-y-0.5`. Selected tabs/nav items represent an active selection state. No shared `:active` or disabled-button visual treatment is defined in the reference.

## 4. Input fields

- **Supported controls:** Text, email, password, date, number, and select elements use a common full-width treatment; checkboxes appear in the permissions matrix.
- **Labels:** Above fields, `text-[10px] font-bold uppercase tracking-wider`, usually muted gray and spaced with `mb-1`.
- **Text/email/password/date/number/select:** Usually `px-3.5` or `px-4`, `py-2.5`, rounded-xl, a light `gray-200` / dark `gray-800` border, translucent white or `slate-950` background, and 12px text. Placeholder text appears where supplied (e.g. email, password, amount, and employee code).
- **Password visibility:** An eye icon button is positioned at the right inside the password field; the input reserves right padding for it.
- **Focus:** `outline-none focus:ring-2 focus:ring-brand-500` (2px emerald ring, base color `#10b981`) is used on most editable fields. Some email/password fields apply the focus ring without an explicit `outline-none`.
- **Read-only:** Uses a muted gray-on-gray treatment (`bg-gray-100`, `dark:bg-slate-950`, `text-gray-400`, bold 12px) while retaining a border.
- **Checkbox:** Permission checkboxes use native checkbox rendering and checked state; no custom checkbox color, shape, or focus treatment is specified.
- **Validation/error:** Forms use HTML `required`, email/date/number types, and numeric `min`/`step` attributes where applicable. The reference does not define a shared invalid-field border/ring style or a custom validation system. Login has a dedicated hidden red-tinted error message block; other feedback is surfaced with toasts.
- **Dark mode:** Editable controls pair `dark:border-gray-800`, `dark:bg-slate-950/50`, and light text with the light-mode counterparts.

## 5. Tables

- **Container:** Tables are full-width, left-aligned, 12px text inside an `overflow-x-auto` wrapper with rounded-2xl corners and a neutral border. Some history/detail tables also cap height at `max-h-72` and scroll vertically.
- **Header:** Uppercase bold text on `gray-50`/`gray-100` in light mode and `slate-950`/`slate-900` in dark mode. Text is muted gray; history headers can be sticky at the top.
- **Rows and dividers:** Body rows use `divide-y` with `gray-200` and `gray-800` in dark mode, sometimes at 60% opacity. Cells commonly use `p-3` or `p-4`; identifiers and key values are bold. Actions are aligned to the right.
- **Empty state:** A centered, muted “No records found.” row uses `p-6`.
- **Actions:** A right-aligned Actions column contains compact soft brand/red actions or outline buttons. Row-level hover fills are not part of the common table markup.
- **Responsive behavior:** The outer `overflow-x-auto` wrapper allows wide tables to scroll horizontally rather than forcing a narrow table layout.

## 6. Reusable components

- **`.glass-panel` card:** Despite its name, this is a flat surface: `background: var(--bg-card)`, a 1px token border, and a soft shadow. Light shadow is `0 4px 20px -2px rgba(0,0,0,.03)`; dark shadow uses `.25` opacity. No backdrop blur is applied to this component.
- **Stat cards:** Dashboard stats are individual `.glass-panel` cards with `p-6`, rounded-3xl, `bg-white/80` / `dark:bg-slate-900/80`, and `.glow-hover`. Each combines a tiny uppercase label, icon/accent, large value, and short caption; the grid is two columns at `sm` and four at `lg`.
- **Navbar:** Landing navigation is sticky at the top with `z-50`, `h-20`, a translucent surface and border, and a centered `max-w-7xl` inner container. Links are hidden below `md`; theme, sign-in, and gradient register controls sit at the right.
- **Sidebar and navigation:** Dashboard sidebar is `w-72`, near-black (`slate-950`), fixed/relative by breakpoint and translated off-canvas on small screens. Inactive nav buttons use muted gray text, charcoal hover, and white hover text. The active item uses the green-to-terracotta gradient with white text and shadow. User/account footer is a bordered dark surface with avatar and logout affordance.
- **Application header:** `h-20`, glass-panel/translucent white or dark surface, bottom border, page title on the left, and role/theme controls on the right.
- **Modals:** `.modal-overlay` fills the viewport, centers content, pads by `1.25rem`, uses a charcoal `rgba(28,25,23,.65)` overlay with 4px backdrop blur, and sits at z-index 200. It transitions opacity/visibility over `.25s` with `cubic-bezier(.16,1,.3,1)`. Content begins at `translateY(20px) scale(.96)` and animates to its natural position/scale. Common widths are `max-w-md`, `max-w-lg`, `max-w-2xl`, and `max-w-3xl`; content uses rounded-3xl, `p-8`, and a large shadow.
- **Confirm modal:** Uses the same overlay/animation, `max-w-md`, rounded-3xl, `p-7`; an amber icon/title area contrasts with a red Proceed action and neutral Cancel.
- **Toasts:** Fixed at top-right (`top-24 right-6`, z-index 300), stacked with a gap, and initially translated/faded. Toasts use rounded-2xl, `px-4 py-3`, bold 12px tracked text, a large shadow, and 500ms transition. Success is emerald, error red, info brand green, warning amber.
- **Badges/pills:** Small uppercase bold text with rounded-full treatment is used for role, status, plan, and operational labels. Role/status colors are detailed above; soft tints generally use 10% background and 20% border opacity.
- **Welcome banner:** Dashboard banner uses `p-7`, rounded-3xl, `mb-8`, white text, and a `brand-700`→`indigo-600` gradient (green to terracotta) with an emerald shadow. It contains a 24px black-weight welcome heading and a supporting 14px line.
- **Tabs:** Billing cycle, HR, and report selection use compact pill buttons. The selected item is brand green with white text; inactive options are muted on gray/dark surfaces.
- **Theme toggle:** Moon/sun icons switch visibility according to the root `.dark` class. Sun uses amber; the button uses a neutral border and hover surface.
- **Scrollbar:** WebKit scrollbar is 6px wide/high with a transparent track and pill thumb. Light thumb is `rgba(120,113,108,.3)`; dark thumb is white at `.15`.
- **Print:** Print rules hide all page content except `#reportPrintArea`, position that area at the top-left at full width, and force black text, white background, and transparent descendants/borders (`#ddd` border override).
- **Icons and logo:** Font Awesome Free 6.5.1 is loaded from CDN; the reference uses `fa-solid` icons. The `.pentad-logo` class displays an embedded PNG; its base64 data is intentionally not reproduced here.

## 7. Layout, spacing, and motion

- **Containers:** Landing sections commonly use `max-w-7xl mx-auto px-6`; hero content uses `max-w-4xl`, and narrower copy uses `max-w-xl`/`max-w-2xl`. The application main area uses `p-6 sm:p-8`.
- **Grid patterns:** Feature cards use `sm:grid-cols-2 lg:grid-cols-4`; plans use `md:grid-cols-3`; dashboard stats use `sm:grid-cols-2 lg:grid-cols-4`; dashboard content uses `lg:grid-cols-3` with a two-column chart panel.
- **Breakpoints used:** `sm` (640px), `md` (768px), and `lg` (1024px) Tailwind defaults; examples include nav visibility, sidebar behavior, grid changes, and responsive type sizes.
- **Spacing rhythm:** Common gaps/padding use 3/4/6/8 Tailwind spacing steps; sections use `py-20`, hero uses `py-24 lg:py-32`, and cards commonly use `p-6`, `p-7`, or `p-8`.
- **Radii:** Non-button surfaces use `rounded-xl` (12px), `rounded-2xl` (16px), `rounded-3xl` (24px), `rounded-full` (pill/circle), and occasional `rounded` (4px). The global button override makes buttons fully pill-shaped regardless of their utility class.
- **Shadows and transitions:** Cards use a light/dark custom shadow; prominent cards and actions use Tailwind shadow sizes and emerald-tinted shadows. `.glow-hover` transitions all properties over `.25s ease`; on hover it adds an emerald-tinted shadow/border and lifts by 2px. Body color/background transitions use `.3s cubic-bezier(.16,1,.3,1)`. Modal transitions use `.25s`; toasts use `.5s`. The hero indicator uses Tailwind `animate-pulse`.
- **Scroll behavior:** Smooth document scrolling is enabled; section anchors use a 5rem scroll margin.

## 8. Inconsistencies in the reference

- **Revenue chart bypasses the remapped palette:** Canvas bars use hard-coded indigo `#6366f1` → `#4338ca`, rather than the configured terracotta `indigo` scale or brand gradient. Grid lines are hard-coded to `#1e293b` in dark mode and `#e2e8f0` in light mode; axis labels use `#64748b` / `#94a3b8`.
- **Revenue chart font differs from the loaded font:** Canvas labels set `ctx.font` to `10px Plus Jakarta Sans, sans-serif`, but the page only loads DM Sans. Plus Jakarta Sans is not loaded in the reference.
- **Undefined brand shade is referenced:** `text-brand-400` appears in multiple areas, including the hero, dashboard, sidebar, and dark-mode utility classes, but `brand.400` is not present in the Tailwind configuration. The requested class therefore has no configured brand HEX value.
- **Accent glow token is not consumed:** `--accent-glow` is defined for both themes, but `.glow-hover` instead hard-codes emerald `rgba(5,150,105,.08)` shadow and `rgba(5,150,105,.3)` border values.
- **Embedded Google mark uses provider colors:** The inline Google sign-in SVG contains `#EA4335`, `#4285F4`, `#FBBC05`, and `#34A853`. These are provider-mark colors rather than the application's semantic palette.
- **“Glass” naming does not indicate blur:** `.glass-panel` itself is an opaque token-based surface with border and shadow; only the modal overlay has a backdrop blur.
- **Global button radius overrides local shape utilities:** Button markup frequently declares rounded-xl/2xl, but the global `!important` rule makes every button a full pill.

These are reported as implemented; this document does not silently change them.

## 9. Gaps & Assumptions

- The prescribed `Private-Design-Reference` directory was unavailable in the workspace. The exact-named HTML file at `reference_html/PentadERP_index (FINAL).html` was treated as the supplied reference; confirm the mount location if that is not the intended copy.
- No separate pre-existing design-system token document was present under `docs/ui-ux/`; this document records the tokens directly from the HTML configuration and CSS.
- No proposed components or values were added. Where the reference has no custom treatment (for example disabled buttons, checkbox styling, or a general invalid-field state), the absence is documented rather than filled in.

## 10. Rules for developers

- Use DM Sans and the reference hierarchy: strong compact headings, small uppercase tracked labels, and readable 12–14px supporting copy.
- Use the CSS theme variables for shared surfaces, borders, and body text; pair Tailwind colors with `dark:` variants for component-specific themes.
- Treat `brand` as emerald, `indigo` as terracotta, `sky` as warm orange, and `slate` as warm stone/charcoal. Never rely on the stock Tailwind interpretation of those remapped class names.
- Use `brand-500`/`brand-600` for primary accents and actions, neutral outlines for secondary actions, red for destructive actions, amber for warnings, and emerald for success. Do not use the unconfigured `brand-400` utility.
- Build cards with `.glass-panel` plus the reference padding/radius; remember it is a flat card treatment, not a blurred glass surface.
- Keep forms consistent: uppercase 10px labels, rounded-xl fields, neutral borders, translucent light/dark fills, and a 2px brand focus ring. Do not imply a custom validation style that the reference does not provide.
- Put wide tables in an `overflow-x-auto` wrapper; use compact uppercase headers, padded cells, divided rows, and a right-aligned actions column.
- Follow the observed `sm`/`md`/`lg` grid and visibility patterns, preserve spacing and radii, and test both light and dark modes.
- Keep this document's identified chart/font and missing-token exceptions visible when extending the design; do not silently treat them as palette tokens.
