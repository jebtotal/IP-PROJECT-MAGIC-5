# S1-UIX-01 — Design System

This guide summarizes the styles implemented in the supplied `PentadERP_index (FINAL).html` reference. The page uses Tailwind CSS, inline theme settings, and starts in dark mode with a theme toggle.

## Colors

| Purpose | Values | Use |
|---|---|---|
| Primary brand | `#059669` (brand-600); hover/accent `#10b981` (brand-500) | Primary actions, focus rings, highlights. |
| Warm gradient accents | `#f97316`, `#ea580c`, `#c2410c`; light accent `#fb923c` | Custom `indigo` and `sky` gradient colors; these are not standard Tailwind hues. |
| Page and surfaces | Light: `#fafaf9` background, `#fff` surface. Dark: `#1c1917` background, `#292524` surface. | Page background and cards. |
| Text | Light: `#292524` primary, `#78716c` muted. Dark: `#f5f5f4` primary, `#a8a29e` muted. | Main and secondary text. |
| Borders | Light: `#e7e5e4`; dark: `rgba(255,255,255,0.05)` | Theme-based panel outlines. Other components also use Tailwind gray borders. |
| Status | Emerald `#10b981` / `#059669`; amber `#f59e0b`; red `#ef4444` / `#dc2626` | Success and active, warning, and error/destructive states. |

The custom `slate` scale uses warm stone and charcoal colors: `#f5f5f4`, `#e7e5e4`, `#d6d3d1`, `#a8a29e`, `#78716c`, `#57534e`, `#44403c`, `#292524`, `#1c1917`, `#171412`, `#0c0a09`, and `#000000` (`slate-50` through `slate-950`, including `slate-850`). Tailwind `gray-*` utilities remain their default colors and are also used for text, borders, and table headers.

## Typography

- **Font:** DM Sans, with `system-ui, sans-serif` fallbacks. Chart canvas labels specify Plus Jakarta Sans, which is not imported.
- **Sizes:** 10px and 11px labels; 12px controls and table text; body copy 16–18px; titles 18–60px depending on component and viewport.
- **Weights:** medium (500), semibold (600), bold (700), extrabold (800), and black (900).
- Labels, navigation, and badges commonly use bold uppercase text with wider letter spacing. The hero title scales responsively from 36px to 60px.

## Buttons

- The global CSS rule makes all buttons pill-shaped (`border-radius: 9999px !important`), overriding button-specific radius utilities.
- Primary buttons use brand green with white text, often changing to brighter green on hover. Neutral buttons use a light/dark surface with a gray border; destructive actions use red. Amber and emerald are used for warning and success-related actions.
- Typical padding is `px-4 py-2.5` for compact actions and `px-6 py-3.5` for prominent actions. Buttons use color transitions and occasional shadows; prominent landing actions lift 2px on hover.
- No shared disabled or pressed style is defined.

## Inputs

- Labels are 10px bold uppercase, muted, and separated from the field by 4px.
- Inputs and selects are full width, typically `px-4 py-2.5`, 12px text, 1px gray border, rounded corners, and light/dark translucent surfaces. Placeholders show examples such as `you@company.com` and `C-001`.
- Focus uses a 2px brand-green ring. Required fields use native validation; the login error message uses red text on a lightly tinted red panel. Read-only fields use muted text and a subdued background.
- No general invalid-field style or custom dropdown is present.

## Tables

- Full-width, left-aligned tables use 12px text and scroll horizontally when needed.
- Headers use uppercase bold gray text on a light gray or dark slate background. Some modal tables have sticky headers.
- Rows are separated by subtle horizontal borders. Cells typically use 16px padding, or 12px in compact tables; action columns align right.
- Identifiers and names may be bold; secondary details use muted text. Status and role values may appear as small colored badges.

## Reusable components

- **Cards:** `.glass-panel` uses the themed card surface, a 1px border, and a soft shadow. Despite its name, it is not backdrop-blurred. `.glow-hover` adds a subtle green border/shadow and 2px lift on hover.
- **Navigation:** the landing navbar and dashboard header are 80px tall. The 288px dark sidebar becomes a slide-in panel on small screens; main content has 24px padding, increasing to 32px at the `sm` breakpoint.
- **Badges:** compact rounded pills use brand, amber, or emerald tints for roles and statuses.
- **Modals:** centered over a dark, blurred overlay; they fade and scale into view over 0.25s. Common widths are `max-w-md` and `max-w-2xl`.
- **Toasts:** top-right notifications use semantic success, error, information, or warning colors and animate into view.
- **Other:** Font Awesome supplies icons; custom WebKit scrollbars are 6px wide/high.

## Consistency guidance

Use the existing brand and status colors, DM Sans typography, compact uppercase labels, and light/dark surface patterns. Reuse the documented button, input, table, card, badge, modal, and toast treatments. Preserve responsive navigation and table overflow. If a state or component is not shown in the reference, define it explicitly rather than assuming an existing style.
