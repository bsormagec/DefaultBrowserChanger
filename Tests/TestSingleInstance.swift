import Foundation
import Darwin

print("Testing Single-Instance Flock Protection...")
let lockPath = "/tmp/com.bsormagec.TestSingleInstance.lock"
let fd1 = open(lockPath, O_CREAT | O_WRONLY, 0o644)
assert(fd1 >= 0, "Failed to open lock file")

// Acquire lock in instance 1
let lockResult1 = flock(fd1, LOCK_EX | LOCK_NB)
assert(lockResult1 == 0, "Instance 1 should acquire lock")

// Simulate instance 2 trying to acquire same lock
let fd2 = open(lockPath, O_CREAT | O_WRONLY, 0o644)
let lockResult2 = flock(fd2, LOCK_EX | LOCK_NB)
assert(lockResult2 != 0, "Instance 2 must be BLOCKED from acquiring lock")
close(fd2)

// Release lock
flock(fd1, LOCK_UN)
close(fd1)

print("✅ TestSingleInstance passed!")
