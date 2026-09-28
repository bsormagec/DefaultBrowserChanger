# 🧭 DefaultBrowserChanger — Setup Guide & User Manual

Welcome to **DefaultBrowserChanger**! This guide walks you through the 1-minute, one-time setup to enable instant default browser switching across macOS with **zero permission popups** and **zero system dialogs**.

---

## ⚡ 1-Minute One-Time Setup

To allow DefaultBrowserChanger to intercept and instantly route your web links to your preferred browser, macOS simply needs DefaultBrowserChanger designated as your system's default web browser.

### Step 1: Open System Settings
- Press <kbd>⌘ Command</kbd> + <kbd>Space</kbd>, type **System Settings**, and press <kbd>Return</kbd> (or click  > **System Settings...**).

<p align="center">
  <img src="assets/step1_open_settings.png" width="600" alt="Step 1: Open macOS System Settings">
</p>

### Step 2: Search "Default web browser"
- In the search bar at the top-left of System Settings, type **`Default web browser`**.
- Click the **Default web browser — Desktop & Dock** search result.

<p align="center">
  <img src="assets/step2_search_browser.png" width="600" alt="Step 2: Search Default web browser in System Settings">
</p>

### Step 3: Open the Dropdown & Choose `DefaultBrowserChanger.app`
- In the **Default web browser** setting row, click the dropdown menu showing all installed browsers.
- Select **`DefaultBrowserChanger.app`**.
- If macOS displays a one-time confirmation sheet, click **Use "DefaultBrowserChanger"**.

<p align="center">
  <img src="assets/step3_select_browser.png" width="600" alt="Step 3: Select DefaultBrowserChanger from the dropdown">
</p>

✅ **You're all set!** From this moment forward, you will never see another macOS default browser confirmation dialog. Switch browsers anytime from your menu bar or using <kbd>⌃</kbd>+<kbd>⌥</kbd>+<kbd>B</kbd>.

---

## 🚀 How to Use DefaultBrowserChanger

### 1. Menu Bar Dropdown
- Click the **Globe (🌐)** icon in the macOS menu bar at the top-right of your screen.
- A menu will show all your installed browsers (Safari, Chrome, Arc, Brave, Firefox, Edge, etc.) with crisp native icons.
- Click any browser. It instantly becomes your active target browser with sound feedback.

### 2. Global Hotkey (`Control + Option + B` / `⌃⌥B`)
- Press <kbd>⌃ Control</kbd> + <kbd>⌥ Option</kbd> + <kbd>B</kbd> anywhere on your Mac.
- DefaultBrowserChanger will instantly cycle to your next installed browser with an audio click.
- No need to take your hands off the keyboard or open the menu bar!

### 3. Launch at Login
- Open the Globe menu and ensure **Launch at Login** is checked.
- DefaultBrowserChanger will silently start in your menu bar when you boot your Mac, consuming under 15MB RAM and 0% CPU.

---

## 🧠 Why the Link Interceptor Architecture is Superior

| Feature | Legacy AppleScript Method | DefaultBrowserChanger Proxy |
| :--- | :--- | :--- |
| **Switching Speed** | 0.5 – 1.0 second (UI delay) | **0.001 second (Instant)** |
| **macOS Popups** | Confirmation alert on every switch | **Zero popups (100% silent)** |
| **Accessibility Permissions** | Required (`AXIsProcessTrusted`) | **Zero permissions needed** |
| **macOS Updates** | Fragile (UI button changes break it) | **Bulletproof native Swift (`NSWorkspace`)** |
| **Single-Instance Guard** | None (can spawn duplicates) | **Strict PID & POSIX flock locks** |

---

## ❓ Frequently Asked Questions (FAQ)

### What happens if I quit the app from the menu bar?
If DefaultBrowserChanger is your default browser and is not currently running, clicking any link in Mail, Slack, or Terminal will cause macOS to **automatically launch** DefaultBrowserChanger in the background, route your link instantly to your active browser, and remain ready in the menu bar.

### Does DefaultBrowserChanger inspect or log my URLs?
**No.** DefaultBrowserChanger runs 100% locally and offline. It does not contain any networking code, analytics, or telemetry. It simply receives the URL from macOS and passes it to your selected browser using `NSWorkspace.shared.open`.

### Can I reopen this guide from the app?
Yes! Click the Globe icon in the menu bar and select **Welcome Guide...** at any time.
