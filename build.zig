// Minimal build.zig that should work with Zig 0.16.0
const std = @import("std");

pub fn build(b: *std.Build) void {
    // Create the executable using the modern API
    const exe = b.addExecutable("localtunnel", "src/main.zig");
    // Set build options
    exe.setBuildMode(.Debug);
}