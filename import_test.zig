const std = @import("std");
const zignal = @import("src/root.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const token = "YOUR_BOT_TOKEN_HERE";
    
    // Test Client initialization through module import
    var client = zignal.Client.init(allocator, token);
    defer client.deinit();
    std.log.info("Client initialized successfully through module import!", .{});
    
    // Test Gateway initialization through module import
    var gateway = try zignal.Gateway.init(allocator, token);
    defer gateway.deinit();
    std.log.info("Gateway initialized successfully through module import!", .{});
    
    // Test EventHandler initialization through module import
    var event_handler = zignal.events.EventHandler.init(allocator);
    defer event_handler.deinit();
    std.log.info("EventHandler initialized successfully through module import!", .{});
    
    // Test basic model creation
    const test_user = zignal.models.User{
        .id = 12345,
        .username = "testuser",
        .discriminator = "0001",
        .global_name = null,
        .avatar = null,
        .bot = true,
        .system = false,
        .mfa_enabled = false,
        .locale = null,
        .verified = false,
        .email = null,
        .flags = null,
        .premium_type = null,
        .public_flags = null,
        .avatar_decoration = null,
    };
    std.log.info("Test user created successfully!", .{});
    _ = test_user;
    
    // Test embed creation
    const test_embed = zignal.models.Embed{
        .title = null,
        .type = null,
        .description = "Test embed description",
        .url = null,
        .timestamp = null,
        .color = 0x00FF00,
        .footer = null,
        .image = null,
        .thumbnail = null,
        .video = null,
        .provider = null,
        .author = null,
        .fields = &[_]zignal.models.EmbedField{},
    };
    std.log.info("Test embed created successfully!", .{});
    _ = test_embed;
    
    std.log.info("All module import tests completed successfully!", .{});
}
