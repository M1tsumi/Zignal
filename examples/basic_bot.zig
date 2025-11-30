const std = @import("std");
const zignal = @import("zignal");
const Client = zignal.Client;
const Gateway = zignal.Gateway;
const models = zignal.models;

const BotHandler = struct {
    allocator: std.mem.Allocator,
    client: *Client,

    pub fn init(allocator: std.mem.Allocator, client: *Client) BotHandler {
        return BotHandler{
            .allocator = allocator,
            .client = client,
        };
    }

    pub fn onReady(self: BotHandler, user: models.User, guilds: []models.Guild) !void {
        _ = self; // TODO: implement ready event handling
        _ = user;
        _ = guilds;
        std.log.info("Bot ready!", .{});
    }

    pub fn onMessageCreate(self: BotHandler, message: models.Message) !void {
        if (std.mem.startsWith(u8, message.content, "!ping")) {
            std.log.info("Received ping command from {s}", .{message.author.username});
            
            const response_content = "Pong!";
            const response = try self.client.createMessage(message.channel_id, response_content, null);
            defer {
                self.allocator.free(response.content);
                self.allocator.free(response.timestamp);
                if (response.edited_timestamp) |et| self.allocator.free(et);
            }
            
            std.log.info("Sent pong response to channel {d}", .{message.channel_id});
        }
        
        if (std.mem.startsWith(u8, message.content, "!info")) {
            std.log.info("Received info command from {s}", .{message.author.username});
            
            var embed = models.Embed{
                .title = try self.allocator.dupe(u8, "Bot Information"),
                .description = try self.allocator.dupe(u8, "This is a basic Discord bot built with Zignal - a zero-dependency Discord API wrapper for Zig!"),
                .color = 0x00ff00,
                .footer = models.EmbedFooter{
                    .text = try self.allocator.dupe(u8, "Powered by Zignal"),
                    .icon_url = null,
                    .proxy_icon_url = null,
                },
                .fields = try self.allocator.alloc(models.EmbedField, 2),
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
                .name = try self.allocator.dupe(u8, "Language"),
                .value = try self.allocator.dupe(u8, "Zig"),
                .is_inline = false,
            };
            
            embed.fields[1] = models.EmbedField{
                .name = try self.allocator.dupe(u8, "Dependencies"),
                .value = try self.allocator.dupe(u8, "Zero! 🚀"),
                .is_inline = false,
            };
            
            var embeds = try self.allocator.alloc(models.Embed, 1);
            embeds[0] = embed;
            
            const response = try self.client.createMessage(message.channel_id, "", embeds);
            defer {
                self.allocator.free(response.content);
                self.allocator.free(response.timestamp);
                if (response.edited_timestamp) |et| self.allocator.free(et);
                // sticker_items is a slice, not optional
            }
            
            std.log.info("Sent info embed response", .{});
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const token = "YOUR_BOT_TOKEN_HERE";
    
    var client = Client.init(allocator, token);
    defer client.deinit();

    var gateway = try Gateway.init(allocator, token);
    defer gateway.deinit();

    const bot_handler = BotHandler.init(allocator, &client);

    try gateway.connect();
    std.log.info("Connected to Discord Gateway", .{});
    
    try gateway.startEventLoop(bot_handler);
}
