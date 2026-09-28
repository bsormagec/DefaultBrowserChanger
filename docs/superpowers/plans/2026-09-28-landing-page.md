# Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a lightweight, responsive, Apple-native landing page for DefaultBrowserChanger in `docs/index.html` and verify all assets, links, and interactions for GitHub Pages deployment.

**Architecture:** Single-file static HTML5/CSS/Vanilla JS architecture served directly from `/docs` on the `main` branch. References local static images in `docs/assets/` without external CDN dependencies. Includes sticky navigation, hero with Sequoia menubar showcase, 6-feature grid, 3-step setup walkthrough, Gatekeeper quarantine copy widget, interactive FAQ accordion, and footer with author credits to `bsormagec`.

**Tech Stack:** Semantic HTML5, Modern CSS (custom properties, flexbox, CSS grid, backdrop-filter, glassmorphism), Vanilla JavaScript (<30 lines for accordion and clipboard API), Python for automated HTML verification tests.

---

### Task 1: Asset Preparation

**Files:**
- Copy: `Resources/AppIcon.png` -> `docs/assets/AppIcon.png`

- [ ] **Step 1: Copy AppIcon to docs/assets**

Copy `Resources/AppIcon.png` to `docs/assets/AppIcon.png` so the landing page can reference all icons and screenshots locally within `docs/assets/`.

Run:
```bash
cp Resources/AppIcon.png docs/assets/AppIcon.png
```

- [ ] **Step 2: Verify asset presence**

Verify that all 5 required images exist in `docs/assets/`:
- `AppIcon.png`
- `dropdown_menu.png`
- `step1_open_settings.png`
- `step2_search_browser.png`
- `step3_select_browser.png`

Run:
```bash
ls -la docs/assets/
```
Expected: All 5 files listed with nonzero file size.

- [ ] **Step 3: Commit asset**

```bash
git add docs/assets/AppIcon.png
git commit -m "docs: add AppIcon to assets directory for GitHub Pages"
```

---

### Task 2: Automated Verification Test Suite

**Files:**
- Create: `tests/test_landing_page.py`

- [ ] **Step 1: Write verification test suite**

Write a Python automated test script that validates:
1. `docs/index.html` exists and is readable.
2. Contains required metadata (`<title>`, `<meta name="description">`, `<link rel="icon">`).
3. Contains all section anchors matching nav links (`#features`, `#setup`, `#faq`).
4. References only existing local assets in `docs/assets/` and validates they exist on disk.
5. Contains the Gatekeeper command `xattr -cr /Applications/DefaultBrowserChanger.app`.
6. Contains the footer credit `"bsormagec"` (and NOT full name).
7. Validates primary download link points to `https://github.com/bsormagec/DefaultBrowserChanger/releases/latest/download/DefaultBrowserChanger.zip`.

```python
import os
import re
import sys

def test_landing_page():
    index_path = "docs/index.html"
    assert os.path.exists(index_path), f"File {index_path} not found"
    
    with open(index_path, "r", encoding="utf-8") as f:
        html = f.read()

    # 1. Basic Structure
    assert "<!DOCTYPE html>" in html, "Missing <!DOCTYPE html>"
    assert "<title>" in html and "DefaultBrowserChanger" in html, "Missing proper title"
    assert 'meta name="description"' in html, "Missing meta description"
    assert 'link rel="icon"' in html, "Missing favicon"

    # 2. Section IDs
    for section_id in ["features", "setup", "faq"]:
        assert f'id="{section_id}"' in html, f"Missing section id: {section_id}"

    # 3. Nav Anchors
    for href in ["#features", "#setup", "#faq"]:
        assert f'href="{href}"' in html, f"Missing nav link to: {href}"

    # 4. Download Link & GitHub Link
    assert "https://github.com/bsormagec/DefaultBrowserChanger/releases/latest/download/DefaultBrowserChanger.zip" in html, "Missing latest release download URL"
    assert "https://github.com/bsormagec/DefaultBrowserChanger" in html, "Missing GitHub repository URL"

    # 5. Gatekeeper Command
    assert "xattr -cr /Applications/DefaultBrowserChanger.app" in html, "Missing xattr Gatekeeper command"

    # 6. Author credit
    assert "bsormagec" in html, "Missing bsormagec in footer"
    assert "Burak Ormagec" not in html, "Full name should not appear in footer"

    # 7. Local assets existence
    local_img_srcs = re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', html)
    for src in local_img_srcs:
        if not src.startswith("http") and not src.startswith("data:"):
            # Resolve relative to docs/
            cleaned = src.lstrip("/")
            if cleaned.startswith("files/"):
                cleaned = "assets/" + cleaned[6:]
            elif not cleaned.startswith("assets/"):
                cleaned = "assets/" + cleaned
            disk_path = os.path.join("docs", cleaned)
            assert os.path.exists(disk_path), f"Image source {src} resolved to {disk_path} does not exist"

    print("All landing page verification tests passed successfully!")

if __name__ == "__main__":
    test_landing_page()
```

- [ ] **Step 2: Run test to verify it fails before `docs/index.html` is created**

Run:
```bash
python3 tests/test_landing_page.py
```
Expected: FAIL with `AssertionError: File docs/index.html not found`.

---

### Task 3: Implement Landing Page (`docs/index.html`)

**Files:**
- Create: `docs/index.html`

- [ ] **Step 1: Write `docs/index.html`**

Generate `docs/index.html` using the validated Apple Minimalist Glassmorphic design. All asset paths must point to relative paths `assets/<filename>` so GitHub Pages serves them properly without domain mismatches:
- `assets/AppIcon.png`
- `assets/dropdown_menu.png`
- `assets/step1_open_settings.png`
- `assets/step2_search_browser.png`
- `assets/step3_select_browser.png`

Footer author credit must strictly be `bsormagec`.

- [ ] **Step 2: Run verification test suite**

Run:
```bash
python3 tests/test_landing_page.py
```
Expected: PASS with "All landing page verification tests passed successfully!".

- [ ] **Step 3: Commit `docs/index.html` and test suite**

```bash
git add docs/index.html tests/test_landing_page.py
git commit -m "feat: add modern GitHub Pages landing page for DefaultBrowserChanger"
```

---

### Task 4: Push to Remote & Verify Live Repository Status

**Files:**
- Push: `main` branch to `origin/main`

- [ ] **Step 1: Push changes to GitHub**

Run:
```bash
git push origin main
```
Expected: Successfully pushed to `origin/main`.

- [ ] **Step 2: Verify git status is clean**

Run:
```bash
git status -s
```
Expected: Empty output (clean working tree).
