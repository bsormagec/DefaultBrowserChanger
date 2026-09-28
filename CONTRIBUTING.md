# Contributing to DefaultBrowserChanger 🌐

First off, thank you for considering contributing to **DefaultBrowserChanger**! It's people like you who make open source such a fantastic environment for building delightful tools.

Following these guidelines helps keep the codebase clean, tests reliable, and PR reviews fast.

---

## 🛠️ Development Setup

### Prerequisites
- macOS 13.0 (Ventura) or newer (tested through macOS Sequoia & macOS 27).
- Xcode Command Line Tools:
  ```bash
  xcode-select --install
  ```
- Swift 5.10+ (included with Xcode / command line tools).

### Getting the Code
```bash
git clone https://github.com/bsormagec/DefaultBrowserChanger.git
cd DefaultBrowserChanger
```

### Building & Running Locally
We maintain an automated build script:
```bash
# Build standalone .app bundle in ./build
./build.sh

# Or build and install directly to /Applications
./build.sh --install

# Launch the app
open build/DefaultBrowserChanger.app
```

### Running Tests
To run the automated browser discovery test:
```bash
swift Tests/TestBrowserDetection.swift
```

---

## 📂 Project Architecture

The project is structured cleanly around single-responsibility modules:

- **`Sources/Models/`**:
  - `BrowserApp.swift`: Data model representing an installed browser (ID, display name, bundle path, icon, default status).
- **`Sources/Services/`**:
  - `BrowserManager.swift`: Discovers installed browsers using `LaunchServices` and `NSWorkspace`, performs default browser switching, and handles macOS confirmation prompts.
  - `SystemHelper.swift`: Handles Launch at Login via `SMAppService`, notification dispatching, audio feedback, and system preferences URLs.
- **`Sources/UI/`**:
  - `MenuBarController.swift`: Manages the `NSStatusItem`, template Globe icon, dynamic `NSMenu`, and user interaction.
- **`Sources/AppDelegate.swift` & `Sources/main.swift`**:
  - Lifecycle initialization and accessory app activation (`LSUIElement = true`).
- **`Resources/`**:
  - `Info.plist`: App configuration, permissions descriptions, and metadata.
  - `AppIcon.icns` & `AppIcon.png`: High-resolution app assets.

---

## 💡 How Can I Contribute?

### Reporting Bugs
- Check the [Issues tab](https://github.com/bsormagec/DefaultBrowserChanger/issues) to ensure your issue hasn't already been reported.
- Use the **Bug Report** template. Include your macOS version, installed browsers, and reproduction steps.

### Suggesting Enhancements
- Feature suggestions are very welcome! Open an issue using the **Feature Request** template explaining the use case and expected user experience.

### Submitting Pull Requests
1. Fork the repo and create your feature branch from `main`:
   ```bash
   git checkout -b feature/my-amazing-feature
   ```
2. Follow standard Swift formatting and naming conventions.
3. Ensure the project builds cleanly without warnings:
   ```bash
   ./build.sh
   swift Tests/TestBrowserDetection.swift
   ```
4. Write clear, conventional commit messages:
   - `feat: add support for custom hotkey`
   - `fix: resolve icon scaling on external display`
   - `docs: update installation instructions`
5. Open a Pull Request against the `main` branch.

---

## 📜 Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.
