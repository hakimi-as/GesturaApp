# Gestura UI Redesign — Design Spec

**Date:** 2026-04-12  
**Status:** Approved  
**Scope:** Visual-only — zero changes to features, logic, data models, or navigation structure

---

## 1. Design Goals

- Replace the current indigo/purple generic Material palette with a distinctive, top-notch visual identity
- Apply glassmorphism (Aurora Glass) throughout — dark void background, frosted cards, ambient glow
- Use exclusively custom SVG icons in the bottom navigation bar — no Material icon library icons
- Introduce asymmetric card corners as the app's signature shape motif
- Preserve every existing feature, screen, and navigation flow exactly as-is

---

## 2. Color System

### Primary Palette — Neon Teal

| Token | Hex | Usage |
|-------|-----|-------|
| `tealLight` | `#67E8F9` | Glow halos, highlights |
| `tealMid` | `#2DD4BF` | Gradient midpoint |
| `tealPrimary` | `#14B8A6` | Primary interactive color |
| `tealDeep` | `#0D9488` | Pressed states, shadows |
| `cyan` | `#06B6D4` | Icon gradients, accents |

### Accent Palette — Amber

| Token | Hex | Usage |
|-------|-----|-------|
| `amber` | `#F59E0B` | Streak counter, challenge cards only |

### Backgrounds

| Token | Hex | Usage |
|-------|-----|-------|
| `voidBlack` | `#060D0D` | App background |
| `surface` | `rgba(255,255,255,0.05)` | Glass card fill |
| `surfaceBorder` | `rgba(255,255,255,0.10)` | Glass card border |

### Replacing Current Palette

Current `theme.dart` values to replace:

| Old | New |
|-----|-----|
| Indigo `#6366F1` (primary) | Teal `#14B8A6` |
| Purple `#8B5CF6` (secondary) | Cyan `#06B6D4` |
| Pink `#EC4899` (accent) | Amber `#F59E0B` |
| Dark bg `#0F0F1A` | Void `#060D0D` |

---

## 3. Typography

- **Headings (H1/H2):** Inter, weight 800
- **Labels/captions:** Inter, weight 600, 9px, ALL-CAPS, letter-spacing 1.5px
- **Body:** Inter, weight 400–500 (Flutter default)
- No font change is required — Flutter's default `fontFamily` in `theme.dart` will be updated to `'Inter'`

---

## 4. Card Style — Aurora Glass

All cards use this decoration pattern:

```dart
BoxDecoration(
  color: Colors.white.withOpacity(0.05),
  borderRadius: BorderRadius.only(
    topLeft:     Radius.circular(20),
    topRight:    Radius.circular(6),
    bottomLeft:  Radius.circular(6),
    bottomRight: Radius.circular(20),
  ),
  border: Border.all(
    color: Colors.white.withOpacity(0.10),
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color: Color(0xFF14B8A6).withOpacity(0.08),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ],
)
```

### Asymmetric Corner Variants

| Variant | Corners (TL / TR / BL / BR) | Usage |
|---------|----------------------------|-------|
| Primary | 20 / 6 / 6 / 20 | Welcome card, stat cards |
| Alternate | 4 / 16 / 16 / 4 | Secondary cards, list items |
| Full pill | 100 / 100 / 100 / 100 | Bottom nav container, buttons |

---

## 5. Ambient Glow

Each screen has two radial gradient blobs behind all content (non-interactive, purely decorative):

- **Top-left blob:** `Color(0xFF14B8A6)` at 18% opacity, radius ~280px
- **Bottom-right blob:** `Color(0xFF06B6D4)` at 12% opacity, radius ~200px

Implemented as `Positioned` widgets inside a `Stack` at the root of each scaffold.

---

## 6. Bottom Navigation Bar

### Container

- Floating pill: `BorderRadius.circular(100)`
- Background: `rgba(6, 13, 13, 0.85)` with `BackdropFilter` blur 20px
- Border: `rgba(255,255,255,0.08)` 1px
- Margin: 16px from screen edges, 12px from bottom safe area
- Shadow: teal `#14B8A6` at 15% opacity, blur 32px

### Active Tab Indicator

- Teal gradient island behind active icon: `#2DD4BF` → `#0D9488`
- `BorderRadius.circular(16)` on the island
- Icon color: `#FFFFFF`

### Inactive Tab

- Icon color: `rgba(255,255,255,0.40)`
- No background

### Tab Order (unchanged from current)

1. Home
2. Sign (was: Translate)
3. Learn
4. Me (was: Settings)

> Note: The tab *labels* and *routes* are unchanged. Only the visual icons and active-state rendering change.

---

## 7. Custom SVG Nav Icons

All four icons use the Neon Teal gradient (`#67E8F9` → `#2DD4BF` → `#0D9488`) on active state, and flat `rgba(255,255,255,0.40)` on inactive.

### 7.1 Home Icon (House + Chimney)

```svg
<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="body-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#2DD4BF"/>
      <stop offset="100%" stop-color="#06B6D4"/>
    </linearGradient>
    <linearGradient id="chimney-gradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#67E8F9"/>
      <stop offset="100%" stop-color="#2DD4BF"/>
    </linearGradient>
  </defs>
  <!-- Chimney -->
  <rect x="25" y="7" width="5" height="9" rx="1.5" fill="url(#chimney-gradient)"/>
  <!-- House body -->
  <path d="M20 5L6 16.5V35H16V26C16 24.9 16.9 24 18 24H22C23.1 24 24 24.9 24 26V35H34V16.5L20 5Z"
        fill="url(#body-gradient)"/>
  <!-- Door shadow -->
  <path d="M18 35V28C18 26.9 18.9 26 20 26C21.1 26 22 26.9 22 28V35H18Z"
        fill="#060D0D" opacity="0.35"/>
</svg>
```

### 7.2 Sign Icon (Viewfinder / Scanner Frame)

```svg
<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#67E8F9"/>
      <stop offset="50%" stop-color="#2DD4BF"/>
      <stop offset="100%" stop-color="#0D9488"/>
    </linearGradient>
  </defs>
  <!-- Outer circle -->
  <circle cx="20" cy="20" r="14" stroke="url(#gradient)" stroke-width="2" fill="none"/>
  <!-- Corner brackets -->
  <path d="M8 14 L8 8 L14 8"   stroke="url(#gradient)" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <path d="M26 8 L32 8 L32 14" stroke="url(#gradient)" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <path d="M8 26 L8 32 L14 32" stroke="url(#gradient)" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <path d="M26 32 L32 32 L32 26" stroke="url(#gradient)" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <!-- Center dot -->
  <circle cx="20" cy="20" r="3.5" fill="url(#gradient)"/>
</svg>
```

### 7.3 Learn Icon (4-Quadrant Grid)

```svg
<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="full" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#67E8F9"/>
      <stop offset="100%" stop-color="#2DD4BF"/>
    </linearGradient>
    <linearGradient id="dim" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#67E8F9" stop-opacity="0.45"/>
      <stop offset="100%" stop-color="#2DD4BF" stop-opacity="0.45"/>
    </linearGradient>
  </defs>
  <!-- Diagonal full-opacity: top-left and bottom-right -->
  <rect x="4"  y="4"  width="14" height="14" rx="3.5" fill="url(#full)"/>
  <rect x="22" y="22" width="14" height="14" rx="3.5" fill="url(#full)"/>
  <!-- Diagonal dim: top-right and bottom-left -->
  <rect x="22" y="4"  width="14" height="14" rx="3.5" fill="url(#dim)"/>
  <rect x="4"  y="22" width="14" height="14" rx="3.5" fill="url(#dim)"/>
</svg>
```

### 7.4 Me Icon (Profile Silhouette)

```svg
<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#67E8F9"/>
      <stop offset="100%" stop-color="#2DD4BF"/>
    </linearGradient>
    <linearGradient id="dim-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#67E8F9" stop-opacity="0.6"/>
      <stop offset="100%" stop-color="#2DD4BF" stop-opacity="0.6"/>
    </linearGradient>
  </defs>
  <!-- Head -->
  <circle cx="20" cy="14" r="7" fill="url(#gradient)"/>
  <!-- Shoulders -->
  <path d="M6 38C6 29.2 12.3 22 20 22C27.7 22 34 29.2 34 38" fill="url(#dim-gradient)"/>
</svg>
```

---

## 8. Widget-Level Changes

### welcome_card.dart

- Background: Aurora glass (`rgba(255,255,255,0.05)`)
- Corner: Primary asymmetric (`20 / 6 / 6 / 20`)
- Gradient bar: Teal `#14B8A6` → `#06B6D4` (replace current indigo→purple)
- Glow shadow: teal at 12%

### stat_card.dart

- Background: Aurora glass
- Corner: Alternate asymmetric (`4 / 16 / 16 / 4`)
- Stat value text: gradient-clipped (`#67E8F9` → `#14B8A6`)
- Icon background: teal glow blob

### General Cards / List Items

- Apply Aurora glass decoration
- Use asymmetric corners (alternate between Primary and Alternate variants)

---

## 9. What Does NOT Change

The following are explicitly out of scope:

- All screen logic, state management, providers
- Firebase/Firestore integration
- Camera/MediaPipe sign detection
- Navigation routing and tab order
- All feature screens (challenges, progress, admin, social, etc.)
- Data models
- Notification/permission handling
- Any existing animation logic (e.g., `AnimatedContainer` in nav bar)

---

## 10. Files to Modify

| File | Change |
|------|--------|
| `lib/config/theme.dart` | Replace entire color palette + add Inter font |
| `lib/widgets/common/bottom_nav_bar.dart` | Pill container, custom SVG icons, active island |
| `lib/widgets/cards/welcome_card.dart` | Aurora glass + teal gradient + asymmetric corners |
| `lib/widgets/cards/stat_card.dart` | Aurora glass + gradient text + asymmetric corners |

No other files require modification for the visual redesign.

---

## 11. Out-of-Scope Items (Future Work)

- Per-screen ambient glow backgrounds (nice-to-have, not required for launch)
- Lottie/Rive animations for icon transitions
- Light mode variant (void-dark only for now)
