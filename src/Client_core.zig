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
            .http_client = std.http.Client{ 
                .allocator = allocator,
                .default_port = 443,
            },
        };
    }

    pub fn deinit(self: *Client) void {
        // Wait for all requests to complete before deinit
        self.http_client.deinit();
    }

    pub fn makeRequest(self: *Client, method: std.http.Method, path: []const u8, headers: ?std.json.ObjectMap, body: ?[]const u8) !*std.http.Client.Request {
        const url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ DISCORD_API_BASE, path });
        defer self.allocator.free(url);

        var header_buffer: [4096]u8 = undefined;
        var request = try self.allocator.create(std.http.Client.Request);
        request.* = try self.http_client.open(method, try std.Uri.parse(url), .{
            .server_header_buffer = &header_buffer,
        });

        // Set default headers
        request.headers.authorization = .{ .override = try std.fmt.allocPrint(self.allocator, "Bot {s}", .{self.token}) };
        request.headers.content_type = .{ .override = "application/json" };

        // Set additional headers if provided
        if (headers) |h| {
            var iter = h.iterator();
            while (iter.next()) |entry| {
                if (entry.value_ptr.* == .string) {
                    // This is a simplified header handling
                    // In a full implementation, we'd need to handle different header types properly
                    _ = entry.key_ptr.*;
                    _ = entry.value_ptr.*.string;
                }
            }
        }

        if (body) |b| {
            try request.writeAll(b);
        } else {
            try request.writeAll("");
        }

        // Send the request and wait for response
        try request.finish();
        
        // Wait for response headers
        try request.wait();

        return request;
    }

    pub fn getCurrentUser(self: *Client) !models.User {
        const request = try self.makeRequest(.GET, "/users/@me", null, null);
        defer {
            request.deinit();
            self.allocator.destroy(request);
        }

        const body = try request.reader().readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        const parsed = try std.json.parseFromSlice(models.User, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return parsed.value;
    }

    pub fn getGuilds(self: *Client) ![]models.Guild {
        const request = try self.makeRequest(.GET, "/users/@me/guilds", null, null);
        defer {
            request.deinit();
            self.allocator.destroy(request);
        }

        const body = try request.reader().readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        const parsed = try std.json.parseFromSlice([]models.Guild, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return parsed.value;
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
        defer {
            request.deinit();
            self.allocator.destroy(request);
        }

        const body = try request.reader().readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        const parsed = try std.json.parseFromSlice(models.Message, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return parsed.value;
    }

    pub fn deleteMessage(self: *Client, channel_id: u64, message_id: u64) !void {
        const message_path = try std.fmt.allocPrint(self.allocator, "/channels/{d}/messages/{d}", .{ channel_id, message_id });
        defer self.allocator.free(message_path);

        const request = try self.makeRequest(.DELETE, message_path, null, null);
        defer request.deinit();
        defer self.allocator.destroy(request);

        // DELETE requests return 204 No Content on success
        // We don't need to read the response body
    }

    pub fn getChannels(self: *Client, guild_id: u64) ![]models.Channel {
        const guild_path = try std.fmt.allocPrint(self.allocator, "/guilds/{d}/channels", .{guild_id});
        defer self.allocator.free(guild_path);

        const request = try self.makeRequest(.GET, guild_path, null, null);
        defer {
            request.deinit();
            self.allocator.destroy(request);
        }

        const body = try request.reader().readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        const parsed = try std.json.parseFromSlice([]models.Channel, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        const channels = try self.allocator.dupe(models.Channel, parsed.value);
        return channels;
    }
};
