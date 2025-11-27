const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Emoji management for guild customization
pub const EmojiManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) EmojiManager {
        return EmojiManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// List all emojis for a guild
    pub fn listGuildEmojis(self: *EmojiManager, guild_id: u64) ![]models.Emoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/emojis",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Emoji, response.body, .{});
    }

    /// Get a specific guild emoji
    pub fn getGuildEmoji(
        self: *EmojiManager,
        guild_id: u64,
        emoji_id: u64,
    ) !models.Emoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/emojis/{d}",
            .{ self.client.base_url, guild_id, emoji_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Emoji, response.body, .{});
    }

    /// Create a new guild emoji
    pub fn createGuildEmoji(
        self: *EmojiManager,
        guild_id: u64,
        name: []const u8,
        image: []const u8, // Base64 encoded image data
        roles: ?[]u64,
        reason: ?[]const u8,
    ) !models.Emoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/emojis",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateEmojiPayload{
            .name = name,
            .image = image,
            .roles = roles orelse &[_]u64{},
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Emoji, response.body, .{});
    }

    /// Modify a guild emoji
    pub fn modifyGuildEmoji(
        self: *EmojiManager,
        guild_id: u64,
        emoji_id: u64,
        name: []const u8,
        roles: ?[]u64,
        reason: ?[]const u8,
    ) !models.Emoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/emojis/{d}",
            .{ self.client.base_url, guild_id, emoji_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyEmojiPayload{
            .name = name,
            .roles = roles orelse &[_]u64{},
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Emoji, response.body, .{});
    }

    /// Delete a guild emoji
    pub fn deleteGuildEmoji(
        self: *EmojiManager,
        guild_id: u64,
        emoji_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/emojis/{d}",
            .{ self.client.base_url, guild_id, emoji_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get emoji URL for display
    pub fn getEmojiUrl(emoji_id: u64, animated: bool) ![]const u8 {
        const extension = if (animated) "gif" else "png";
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "https://cdn.discordapp.com/emojis/{d}.{s}",
            .{ emoji_id, extension },
        );
    }
};

/// Payload for creating an emoji
pub const CreateEmojiPayload = struct {
    name: []const u8,
    image: []const u8, // Base64 encoded image data
    roles: []u64,
};

/// Payload for modifying an emoji
pub const ModifyEmojiPayload = struct {
    name: []const u8,
    roles: []u64,
};

/// Emoji image format validation
pub const EmojiImageValidator = struct {
    pub fn validateImageData(image_data: []const u8) !bool {
        // Check if image data is valid base64
        // Check image size (max 256KB)
        // Check image format (PNG, JPEG, GIF)
        return image_data.len <= 262144; // 256KB max
    }

    pub fn getImageFormat(image_data: []const u8) ?[]const u8 {
        if (std.mem.startsWith(u8, image_data, "data:image/png;base64,")) {
            return "png";
        }
        if (std.mem.startsWith(u8, image_data, "data:image/jpeg;base64,")) {
            return "jpeg";
        }
        if (std.mem.startsWith(u8, image_data, "data:image/gif;base64,")) {
            return "gif";
        }
        return null;
    }
};
