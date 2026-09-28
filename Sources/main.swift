import AppKit
import Darwin

// MARK: - Single Instance Enforcement

// 1. Bundle ID check (prevents multiple instances with the same bundle ID)
let bundleID = Bundle.main.bundleIdentifier ?? "com.bsormagec.DefaultBrowserChanger"
let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
let currentPID = NSRunningApplication.current.processIdentifier

if runningApps.contains(where: { $0.processIdentifier != currentPID }) {
    NSLog("DefaultBrowserChanger: Another instance is already running (PID match). Exiting.")
    exit(0)
}

// 2. POSIX file lock (prevents duplicate runs across different paths or unbundled binaries)
let lockPath = "/tmp/com.bsormagec.DefaultBrowserChanger.lock"
let lockFd = open(lockPath, O_CREAT | O_WRONLY, 0o644)
if lockFd >= 0 {
    if flock(lockFd, LOCK_EX | LOCK_NB) != 0 {
        NSLog("DefaultBrowserChanger: Lock file held by another process. Exiting.")
        exit(0)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate.shared
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
