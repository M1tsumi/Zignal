const std = @import("std");
const zignal = @import("../src/root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test basic compilation and initialization
    const token = "YOUR_BOT_TOKEN_HERE";
    
    var client = zignal.Client.init(allocator, token);
    defer client.deinit();

    std.log.info("Zignal client initialized successfully!", .{});
    std.log.info("Library is working - all core components compiled!", .{});
}
