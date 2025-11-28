const std = @import("std");
const Client = @import("../src/Client.zig").Client;
const Gateway = @import("../src/Gateway.zig").Gateway;
const EventHandler = @import("../src/events.zig").EventHandler;
const models = @import("../src/models.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const token = "YOUR_BOT_TOKEN_HERE";
    
    var client = Client.init(allocator, token);
    defer client.deinit();

    var gateway = try Gateway.init(allocator, token);
    defer gateway.deinit();

    var event_handler = EventHandler.init(allocator);
    defer event_handler.deinit();

    try event_handler.onReady(struct {
        fn handler(session_id: []const u8, application_id: u64) void {
            std.log.info("Bot ready! Session ID: {s}, Application ID: {d}", .{ session_id, application_id });
        }
    }.handler);

    try event_handler.onMessageCreate(struct {
        fn handler(message: *const models.Message, client_ptr: *Client, alloc: std.mem.Allocator) void {
            if (std.mem.startsWith(u8, message.content, "!ping")) {
                std.log.info("Received ping command from {s}", .{message.author.username});
                
                const response_content = "Pong!";
                const response = client_ptr.createMessage(message.channel_id, response_content, null) catch |err| {
                    std.log.err("Failed to send response: {}", .{err});
                    return;
                };
                defer {
                    alloc.free(response.content);
                    alloc.free(response.timestamp);
                    if (response.edited_timestamp) |et| alloc.free(et);
                }
                
                std.log.info("Sent pong response to channel {d}", .{message.channel_id});
            }
            
            if (std.mem.startsWith(u8, message.content, "!info")) {
                std.log.info("Received info command from {s}", .{message.author.username});
                
                var embed = models.Embed{
                    .title = alloc.dupe(u8, "Bot Information") catch return,
                    .description = alloc.dupe(u8, "This is a basic Discord bot built with Zignal - a zero-dependency Discord API wrapper for Zig!") catch return,
                    .color = 0x00ff00,
                    .footer = models.EmbedFooter{
                        .text = alloc.dupe(u8, "Powered by Zignal") catch return,
                        .icon_url = null,
                        .proxy_icon_url = null,
                    },
                    .fields = alloc.alloc(models.EmbedField, 2) catch return,
                    .image = null,
                    .thumbnail = null,
                    .video = null,
                    .provider = null,
                    .author = null,
                    .timestamp = null,
                    .url = null,
                    .type = null,
                };
                
                embed.fields[0] = models.EmbedField{
                    .name = alloc.dupe(u8, "Language") catch return,
                    .value = alloc.dupe(u8, "Zig") catch return,
                    .is_inline = false,
                };
                
                embed.fields[1] = models.EmbedField{
                    .name = alloc.dupe(u8, "Dependencies") catch return,
                    .value = alloc.dupe(u8, "Zero! 🚀") catch return,
                    .is_inline = false,
                };
                
                var embeds = alloc.alloc(models.Embed, 1) catch return;
                embeds[0] = embed;
                
                const response = client_ptr.createMessage(message.channel_id, "", embeds) catch |err| {
                    std.log.err("Failed to send embed response: {}", .{err});
                    return;
                };
                defer {
                    alloc.free(response.content);
                    alloc.free(response.timestamp);
                    if (response.edited_timestamp) |et| alloc.free(et);
                    if (response.sticker_items) |items| alloc.free(items);
                }
                
                std.log.info("Sent info embed response");
            }
        }
    }.handler);

    try gateway.connect();
    std.log.info("Connected to Discord Gateway");
    
    try gateway.startEventLoop();
}
