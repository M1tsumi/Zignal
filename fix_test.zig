const std = @import("std");

// Test different import approaches
const ClientDirect = @import("src/Client.zig").Client;
const zignal = @import("src/root.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const token = "test_token";
    
    // Test direct import first
    var client1 = ClientDirect.init(allocator, token);
    defer client1.deinit();
    std.log.info("Direct import works!", .{});
    
    // Test root import
    var client2 = zignal.Client.init(allocator, token);
    defer client2.deinit();
    std.log.info("Root import works!", .{});
}
