const std = @import("std");
const testing = std.testing;

// Import modules directly
const client_module = @import("Client.zig");
const Client = client_module.Client;

const gateway_module = @import("Gateway.zig");
const Gateway = gateway_module.Gateway;

const events_module = @import("events.zig");
const EventHandler = events_module.EventHandler;

const models = @import("models.zig");

test "Client initialization" {
    const allocator = testing.allocator;
    const token = "test_token";

    var client = Client.init(allocator, token);
    defer client.deinit();

    try testing.expect(std.mem.eql(u8, client.token, token));
}

test "Gateway initialization" {
    const allocator = testing.allocator;
    const token = "test_token";

    var gateway = try Gateway.init(allocator, token);
    defer gateway.deinit();

    try testing.expect(std.mem.eql(u8, gateway.token, token));
}

test "EventHandler initialization" {
    const allocator = testing.allocator;

    var event_handler = EventHandler.init(allocator);
    defer event_handler.deinit();

    try testing.expect(event_handler.handlers.count() == 0);
}

test "Model creation" {
    const user = models.User{
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
    const embed = models.Embed{
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
        .fields = &[_]models.EmbedField{},
    };

    try testing.expect(embed.color == 0xFF0000);
    try testing.expect(embed.fields.len == 0);
}
