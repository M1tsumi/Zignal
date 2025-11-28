const std = @import("std");
const models = @import("models.zig");

const DISCORD_API_BASE = "https://discord.com/api/v10";

pub const Client = struct {
    allocator: std.mem.Allocator,
    token: []const u8,
    http_client: std.http.Client,

    pub fn init(allocator: std.mem.Allocator, token: []const u8) Client {
        return Client{
            .allocator = allocator,
            .token = token,
            .http_client = std.http.Client{ .allocator = allocator },
        };
    }

    pub fn deinit(self: *Client) void {
        self.http_client.deinit();
    }

    fn makeRequest(self: *Client, method: std.http.Method, path: []const u8, headers: ?std.json.ObjectMap, body: ?[]const u8) !std.http.Client.Request {
        _ = headers; // TODO: implement headers support
        const url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ DISCORD_API_BASE, path });
        defer self.allocator.free(url);

        var request = try self.http_client.open(method, try std.Uri.parse(url), .{
            .max_redirects = 5,
            .headers = .{
                .authorization = try std.fmt.allocPrint(self.allocator, "Bot {s}", .{self.token}),
                .content_type = "application/json",
            },
        });
        defer request.deinit();

        if (body) |b| {
            try request.send(.{}, b);
        } else {
            try request.send(.{}, "");
        }

        return request;
    }

    pub fn getCurrentUser(self: *Client) !models.User {
        const request = try self.makeRequest(.GET, "/users/@me", null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        const parsed = try std.json.parseFromSlice(models.User, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return parsed.value;
    }

    pub fn getGuilds(self: *Client) ![]models.Guild {
        const request = try self.makeRequest(.GET, "/users/@me/guilds", null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        const parsed = try std.json.parseFromSlice([]models.Guild, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        const guilds = try self.allocator.dupe(models.Guild, parsed.value);
        return guilds;
    }

    pub fn createMessage(self: *Client, channel_id: u64, content: []const u8, embeds: ?[]models.Embed) !models.Message {
        const MessagePayload = struct {
            content: ?[]const u8 = null,
            embeds: ?[]models.Embed = null,
        };

        const payload = MessagePayload{
            .content = if (content.len > 0) content else null,
            .embeds = embeds,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        const channel_path = try std.fmt.allocPrint(self.allocator, "/channels/{d}/messages", .{channel_id});
        defer self.allocator.free(channel_path);

        const request = try self.makeRequest(.POST, channel_path, null, json_payload);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        const parsed = try std.json.parseFromSlice(models.Message, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return parsed.value;
    }

    pub fn getChannels(self: *Client, guild_id: u64) ![]models.Channel {
        const guild_path = try std.fmt.allocPrint(self.allocator, "/guilds/{d}/channels", .{guild_id});
        defer self.allocator.free(guild_path);

        const request = try self.makeRequest(.GET, guild_path, null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        const parsed = try std.json.parseFromSlice([]models.Channel, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        const channels = try self.allocator.dupe(models.Channel, parsed.value);
        return channels;
    }
};
