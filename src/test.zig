const std = @import("std");
const testing = std.testing;
const zignal = @import("root.zig");

test "Client initialization" {
    const allocator = testing.allocator;
    const token = "test_token";
    
    var client = zignal.Client.init(allocator, token);
    defer client.deinit();
    
    try testing.expect(std.mem.eql(u8, client.token, token));
}

test "Gateway initialization" {
    const allocator = testing.allocator;
    const token = "test_token";
    
    var gateway = try zignal.Gateway.init(allocator, token);
    defer gateway.deinit();
    
    try testing.expect(std.mem.eql(u8, gateway.token, token));
}

test "EventHandler initialization" {
    const allocator = testing.allocator;
    
    var event_handler = zignal.EventHandler.init(allocator);
    defer event_handler.deinit();
    
    try testing.expect(event_handler.handlers.count() == 0);
}

test "Model creation" {
    const allocator = testing.allocator;
    
    const user = zignal.models.User{
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
    
    try testing.expect(user.id == 12345);
    try testing.expect(std.mem.eql(u8, user.username, "testuser"));
    try testing.expect(user.bot == true);
}

test "Embed creation" {
    const allocator = testing.allocator;
    
    const embed = zignal.models.Embed{
        .title = null,
        .type = null,
        .description = null,
        .url = null,
        .timestamp = null,
        .color = 0xFF0000,
        .footer = null,
        .image = null,
        .thumbnail = null,
        .video = null,
        .provider = null,
        .author = null,
        .fields = &[_]zignal.models.EmbedField{},
    };
    
    try testing.expect(embed.color == 0xFF0000);
    try testing.expect(embed.fields.len == 0);
}
