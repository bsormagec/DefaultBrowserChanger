# Design Spec: GitHub Pages Landing Page for DefaultBrowserChanger

**Date:** 2026-09-28  
**Author:** Pair programming with Burak Ormagec  
**Status:** Validated & Ready for Implementation Plan  
**Target File:** `docs/index.html` (served via GitHub Pages from `/docs` on `main`)

---

## 1. Overview & Objectives

DefaultBrowserChanger is an open-source, lightweight macOS menu bar utility that enables 1-click and global hotkey (`⌃⌥B`) default browser switching with a 0.001s Link Interceptor (URL proxy).

This specification details the design and implementation of a sleek, high-conversion, Apple-native landing page hosted via **GitHub Pages**. The landing page serves as the official public face of the project, replacing raw README browsing with an elegant, responsive product showroom.

### Core Objectives:
1. **Drive Downloads & Stars:** Provide instant, frictionless 1-click download access to the latest release (`v1.1.1 .zip`) and prominent GitHub star CTAs.
2. **Apple Native Visual Language:** Match modern macOS Sequoia/Sonoma glassmorphic aesthetics (`backdrop-filter: blur`, SF Pro typography, dark charcoal palette with subtle Apple blue accents).
3. **Clarity & Education:** Clearly communicate the core value proposition (0.001s Link Interceptor, global hotkey `⌃⌥B`, zero permissions, privacy-first architecture).
4. **Visual Onboarding:** Walk users through the 3-step setup in macOS System Settings with real cropped screenshots.
5. **Gatekeeper Support:** Provide a clear explanation of macOS Gatekeeper / Quarantine behavior with a 1-click terminal command copy widget (`xattr -cr /Applications/DefaultBrowserChanger.app`).
6. **Zero-Dependency Architecture:** Single-file static HTML5/CSS/vanilla JS in `docs/index.html` referencing local assets in `docs/assets/`, with zero build steps and 100% static hosting on GitHub Pages.

---

## 2. Visual Design & Theme System

The design follows Apple's Human Interface Guidelines for modern macOS dark mode utilities.

### Design Tokens & Variables:
```css
:root {
  --bg: #090d16;
  --bg-card: rgba(255, 255, 255, 0.035);
  --bg-card-hover: rgba(255, 255, 255, 0.06);
  --border: rgba(255, 255, 255, 0.08);
  --border-hover: rgba(255, 255, 255, 0.18);
  --accent: #0a84ff;
  --accent-hover: #409cff;
  --accent-glow: rgba(10, 132, 255, 0.28);
  --text: #f5f5f7;
  --text-muted: #86868b;
  --text-dim: #636366;
  --radius-sm: 8px;
  --radius-md: 14px;
  --radius-lg: 20px;
  --font-sans: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", system-ui, sans-serif;
  --font-mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
}
```

### Background Lighting & Atmosphere:
- Subtle ambient radial gradients at the top and bottom of the viewport for depth:
  `radial-gradient(ellipse 80% 50% at 50% -20%, rgba(10, 132, 255, 0.18), transparent 70%)`
- High-contrast typography with smooth gradient clipping on hero headline.
- Frosted glass sticky navigation bar (`backdrop-filter: blur(20px)`).

---

## 3. Page Structure & Components

The landing page consists of 7 structured sections:

### 1. Sticky Navigation Bar (`<nav class="navbar">`)
- **Brand:** 32x32 `AppIcon.png` + "DefaultBrowserChanger" title link.
- **Nav Links:** Smooth-scrolling anchors to `#features`, `#setup`, `#faq`, and external link to GitHub repository (`https://github.com/bsormagec/DefaultBrowserChanger`).
- **Quick Action CTA:** Pill button linking directly to `DefaultBrowserChanger.zip` download.

### 2. Hero Section (`<header class="hero">`)
- **Release Badge:** Pill badge linking to GitHub Release v1.1.1: `"✨ v1.1.1 Released • macOS 12 Monterey or newer"`.
- **Headline:** `"Switch Browsers at the Speed of Thought."`
- **Subheadline:** Clear explanation of 1-click switching, 0.001s Link Interceptor, and the `⌃⌥B` hotkey.
- **Primary CTA:** `"⬇ Download for macOS (v1.1.1 .zip)"` pointing to `https://github.com/bsormagec/DefaultBrowserChanger/releases/latest/download/DefaultBrowserChanger.zip`.
- **Secondary CTA:** `"★ Star on GitHub"` pointing to repo root.
- **Showcase Card:**
  - Realistic simulated macOS Sequoia menu bar with Apple logo, Finder menus, active browser pill (`🌐 Arc`), and hotkey pill (`⌃⌥B`).
  - Dropdown preview embedding `assets/dropdown_menu.png`.
  - Feature highlights bullet points: Single-click switch, Global hotkey, Instant dispatch.

### 3. Capabilities / Features Grid (`<section id="features">`)
Six card grid (3x2 on desktop, 2x3 on tablet, 1x6 on mobile):
1. **0.001s Link Interceptor:** High-speed URL proxy routing.
2. **Global Hotkey (⌃⌥B):** Universal hotkey for instant menu summon without mouse movement.
3. **Auto Browser Discovery:** Dynamic discovery of all HTTP/HTTPS registered browser apps (Safari, Arc, Chrome, Brave, Firefox, Edge, Orion, Zen, Vivaldi).
4. **Lightweight & LSUIElement:** Pure menu bar residency with no Dock clutter, <12MB RAM, 0% idle CPU.
5. **Zero Permissions Required:** No Accessibility APIs, no Screen Recording, no root/sudo privileges.
6. **100% Private & Open Source:** Zero telemetry, zero analytics, zero external network connections. Fully auditable Swift code.

### 4. 3-Step Setup Guide (`<section id="setup">`)
Three visual cards with screenshots:
- **Step 1:** Open System Settings ➔ Desktop & Dock (`assets/step1_open_settings.png`).
- **Step 2:** Locate Default Web Browser dropdown (`assets/step2_search_browser.png`).
- **Step 3:** Select DefaultBrowserChanger (`assets/step3_select_browser.png`).
- **Gatekeeper / Quarantine Callout Box:**
  - Explains the open-source unsigned developer gatekeeper prompt on first launch.
  - Interactive Terminal Command Widget:
    `xattr -cr /Applications/DefaultBrowserChanger.app`
  - 1-click **"Copy Command"** button with visual feedback ("Copied! ✓").

### 5. Frequently Asked Questions (`<section id="faq">`)
Interactive accordion component:
- Q1: *Why do I need to set DefaultBrowserChanger as the macOS default?*
- Q2: *Why does macOS show a Gatekeeper warning on first launch?*
- Q3: *Which web browsers are supported?*
- Q4: *Does it slow down link opening?*
- Q5: *How do I uninstall DefaultBrowserChanger completely?*

### 6. Bottom Call to Action Banner
- High-visibility conversion container encouraging immediate download of v1.1.1.

### 7. Footer (`<footer>`)
- Author credits: "DefaultBrowserChanger © 2026. Built with ❤️ by Burak Ormagec."
- Links: MIT License, GitHub Repository, Releases.

---

## 4. File Layout & Assets

All landing page files reside in `docs/`:
```
docs/
├── index.html                     # Complete landing page
├── assets/
│   ├── dropdown_menu.png          # Cropped menu bar dropdown showcase
│   ├── step1_open_settings.png    # Setup step 1 screenshot
│   ├── step2_search_browser.png   # Setup step 2 screenshot
│   ├── step3_select_browser.png   # Setup step 3 screenshot
│   ├── system_settings_browser.png # System settings overview
│   └── AppIcon.png                # App icon copied from Resources/AppIcon.png
├── SETUP_GUIDE.md                 # Existing markdown documentation
└── superpowers/
    └── specs/
        └── 2026-09-28-landing-page-design.md # This specification
```

---

## 5. Technical Requirements & Best Practices

1. **Pure Vanilla Implementation:**
   - Single static `index.html` file combining clean semantic HTML5, embedded scoped CSS, and minimal vanilla JavaScript (<30 lines).
   - Zero external CDN dependencies (no jQuery, no Tailwind CDN, no external font fonts.googleapis.com) to guarantee instant offline loading, privacy, and zero latency.
2. **Responsive Design:**
   - Mobile-first flexible layouts using CSS Grid and Flexbox (`clamp()`, `minmax()`).
   - Breakpoints at `900px`, `768px`, and `600px` for phone and tablet viewing.
3. **Accessibility (a11y):**
   - High color contrast ratios exceeding WCAG AA standards.
   - Descriptive `alt` attributes on all images.
   - Semantic tags (`<nav>`, `<header>`, `<main>`, `<section>`, `<footer>`).
4. **Copy-to-Clipboard Functionality:**
   - Uses `navigator.clipboard.writeText` with graceful visual state update.
5. **SEO & Social Metadata:**
   - Meta title, description, viewport, favicon link (`AppIcon.png`), and OpenGraph tags.

---

## 6. GitHub Pages Deployment

- Repository: `bsormagec/DefaultBrowserChanger`
- Publishing Source: Branch `main`, Directory `/docs`
- URL: `https://bsormagec.github.io/DefaultBrowserChanger/`

---

## 7. Spec Self-Review Checklist

- [x] **Placeholder scan:** No TBDs or TODOs; exact copy, commands, and links specified.
- [x] **Internal consistency:** Matches existing app features (v1.1.1, `LSUIElement`, `⌃⌥B`, `xattr -cr`).
- [x] **Scope check:** Strictly focused on the static GitHub Pages landing page.
- [x] **Ambiguity check:** Asset paths, styling architecture, and interaction handlers explicitly detailed.
