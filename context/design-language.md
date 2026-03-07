# Radical Concepts — Design Language

Extracted from `radical-concepts-all-pitches.html`. All Brett-facing HTML deliverables must follow this system.

## Fonts
```html
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&family=DM+Serif+Display&display=swap" rel="stylesheet">
```
- **Headlines:** `'DM Serif Display', serif` — weight 400 only
- **Body:** `'DM Sans', sans-serif` — weights 300-700

## Typography Scale (CSS Custom Properties)
All use `clamp()` for fluid responsive sizing — no fixed px, no breakpoints for type.

| Token | Value |
|-------|-------|
| `--text-xs` | `clamp(0.65rem, 0.55rem + 0.25vw, 0.78rem)` |
| `--text-sm` | `clamp(0.78rem, 0.65rem + 0.35vw, 0.92rem)` |
| `--text-base` | `clamp(0.9rem, 0.75rem + 0.4vw, 1.1rem)` |
| `--text-lg` | `clamp(1rem, 0.8rem + 0.55vw, 1.3rem)` |
| `--text-xl` | `clamp(1.1rem, 0.85rem + 0.7vw, 1.5rem)` |
| `--text-2xl` | `clamp(1.6rem, 1.2rem + 1.2vw, 2.5rem)` |
| `--text-3xl` | `clamp(2rem, 1.4rem + 1.8vw, 3.2rem)` |
| `--text-hero` | `clamp(3rem, 2rem + 3vw, 6rem)` |
| `--text-stat` | `clamp(4rem, 2.5rem + 5vw, 9rem)` |
| `--space-slide` | `clamp(2.5rem, 2rem + 3vw, 6rem)` |

## Colors

- **Background:** `#111827`
- **Text on dark:** `#fff`
- **Text on light:** `#1A1A2E`

### Concept Colors
| Concept | Primary | Label/Accent |
|---------|---------|-------------|
| C1 — Daily Podcast | `#4682B4` (Steel Blue) | `#2D6A9F` |
| C2 — Curiosity Game | `#FF6B6B` (Coral) | `#E85555` |
| C3 — Dinner Table Drop | `#C9A96E` (Gold) | `#C9A96E` |

## Glassmorphism Cards (on dark backgrounds)
```css
background: rgba(255,255,255,0.06);
border: 1px solid rgba(255,255,255,0.1);
border-radius: 12px;
padding: clamp(1rem, 0.75rem + 0.75vw, 1.75rem);
```
Hover: `transform: translateY(-2px)` to `translateY(-6px)`, `box-shadow: 0 16px 48px rgba(0,0,0,0.4)`

## Layout
- **Max-width:** `1100px`, centered with `margin: 0 auto`
- **Page padding:** `var(--space-slide)` — responsive via clamp
- **Responsive breakpoint:** `900px` — grids collapse to single column

## Header Bar
```css
display: flex; justify-content: space-between; align-items: center;
/* Left: */ "Team Radical · I2P 2026"
/* Right: */ RC logo-mark (34x34px, rgba bg, 6px radius) + "Radical Concepts"
```

## SVG Icons
- Stroke-based, 24x24, `stroke-width: 2`, `stroke-linecap: round`, `stroke-linejoin: round`
- No fill — use `fill: none; stroke: currentColor`

## Maturity Dots (Score Visual)
```css
.dot { width: clamp(12px, 0.8vw + 6px, 18px); height: same; border-radius: 50%; }
.dot (unfilled): concept bg at 20% opacity
.dot.filled: concept primary color
```

## Decorative Characters (NO emojis)
Use: `&middot;` `&rarr;` `&mdash;` `&times;` `&darr;` `&bull;`

## Print
```css
@page { margin: 1.5cm; size: A4; }
@media print {
  -webkit-print-color-adjust: exact; print-color-adjust: exact;
}
```
