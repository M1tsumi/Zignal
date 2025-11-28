const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Sticker management for guild customization
pub const StickerManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) StickerManager {
        return StickerManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get a sticker by ID
    pub fn getSticker(
        self: *StickerManager,
        sticker_id: u64,
    ) !models.Sticker {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/stickers/{d}",
            .{ self.client.base_url, sticker_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Sticker, response.body, .{});
    }

    /// List all sticker packs
    pub fn listStickerPacks(self: *StickerManager) ![]models.StickerPack {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/sticker-packs",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.StickerPack, response.body, .{});
    }

    /// List all guild stickers
    pub fn listGuildStickers(self: *StickerManager, guild_id: u64) ![]models.Sticker {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/stickers",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Sticker, response.body, .{});
    }

    /// Get a guild sticker
    pub fn getGuildSticker(
        self: *StickerManager,
        guild_id: u64,
        sticker_id: u64,
    ) !models.Sticker {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/stickers/{d}",
            .{ self.client.base_url, guild_id, sticker_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Sticker, response.body, .{});
    }

    /// Create a new guild sticker
    pub fn createGuildSticker(
        self: *StickerManager,
        guild_id: u64,
        name: []const u8,
        description: []const u8,
        tags: []const u8,
        file_data: []const u8, // PNG file data
        reason: ?[]const u8,
    ) !models.Sticker {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/stickers",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        // Create multipart form data
        var boundary = std.ArrayList(u8).init(self.allocator);
        defer boundary.deinit();
        try boundary.appendSlice("----WebKitFormBoundary");

        // Generate random boundary
        var rng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
        const random = rng.random();
        for (0..16) |_| {
            const char = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"[random.intRangeAtMost(u8, 61)];
            try boundary.append(char);
        }

        var form_data = std.ArrayList(u8).init(self.allocator);
        defer form_data.deinit();

        // Add name field
        try form_data.appendSlice("--");
        try form_data.appendSlice(boundary.items);
        try form_data.appendSlice("\r\n");
        try form_data.appendSlice("Content-Disposition: form-data; name=\"name\"\r\n\r\n");
        try form_data.appendSlice(name);
        try form_data.appendSlice("\r\n");

        // Add description field
        try form_data.appendSlice("--");
        try form_data.appendSlice(boundary.items);
        try form_data.appendSlice("\r\n");
        try form_data.appendSlice("Content-Disposition: form-data; name=\"description\"\r\n\r\n");
        try form_data.appendSlice(description);
        try form_data.appendSlice("\r\n");

        // Add tags field
        try form_data.appendSlice("--");
        try form_data.appendSlice(boundary.items);
        try form_data.appendSlice("\r\n");
        try form_data.appendSlice("Content-Disposition: form-data; name=\"tags\"\r\n\r\n");
        try form_data.appendSlice(tags);
        try form_data.appendSlice("\r\n");

        // Add file field
        try form_data.appendSlice("--");
        try form_data.appendSlice(boundary.items);
        try form_data.appendSlice("\r\n");
        try form_data.appendSlice("Content-Disposition: form-data; name=\"file\"; filename=\"sticker.png\"\r\n");
        try form_data.appendSlice("Content-Type: image/png\r\n\r\n");
        try form_data.appendSlice(file_data);
        try form_data.appendSlice("\r\n");

        // End boundary
        try form_data.appendSlice("--");
        try form_data.appendSlice(boundary.items);
        try form_data.appendSlice("--\r\n");

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", try std.fmt.allocPrint(self.allocator, "multipart/form-data; boundary={s}", .{boundary.items}));
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, form_data.items);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Sticker, response.body, .{});
    }

    /// Modify a guild sticker
    pub fn modifyGuildSticker(
        self: *StickerManager,
        guild_id: u64,
        sticker_id: u64,
        name: ?[]const u8,
        description: ?[]const u8,
        tags: ?[]const u8,
        reason: ?[]const u8,
    ) !models.Sticker {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/stickers/{d}",
            .{ self.client.base_url, guild_id, sticker_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyStickerPayload{
            .name = name,
            .description = description,
            .tags = tags,
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

        return try std.json.parse(models.Sticker, response.body, .{});
    }

    /// Delete a guild sticker
    pub fn deleteGuildSticker(
        self: *StickerManager,
        guild_id: u64,
        sticker_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/stickers/{d}",
            .{ self.client.base_url, guild_id, sticker_id },
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

    /// Get sticker URL for display
    pub fn getStickerUrl(sticker_id: u64, format: []const u8) ![]const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "https://cdn.discordapp.com/stickers/{d}.{s}",
            .{ sticker_id, format },
        );
    }

    /// Get sticker format from sticker object
    pub fn getStickerFormat(sticker: models.Sticker) []const u8 {
        return switch (sticker.format_type) {
            1 => "png",
            2 => "apng",
            3 => "lottie",
            else => "png",
        };
    }
};

/// Payload for modifying a sticker
pub const ModifyStickerPayload = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    tags: ?[]const u8 = null,
};

/// Sticker format types
pub const StickerFormatType = enum(u8) {
    png = 1,
    apng = 2,
    lottie = 3,
};

/// Sticker validation utilities
pub const StickerValidator = struct {
    pub fn validateStickerName(name: []const u8) bool {
        // Sticker names must be 2-30 characters
        return name.len >= 2 and name.len <= 30;
    }

    pub fn validateStickerDescription(description: []const u8) bool {
        // Sticker descriptions must be 2-100 characters
        return description.len >= 2 and description.len <= 100;
    }

    pub fn validateStickerTags(tags: []const u8) bool {
        // Sticker tags must be 2-200 characters
        return tags.len >= 2 and tags.len <= 200;
    }

    pub fn validateStickerFile(file_data: []const u8) bool {
        // Sticker files must be PNG, APNG, or Lottie
        // Max size is 320KB for standard, 512KB for Nitro
        return file_data.len <= 512 * 1024; // 512KB max
    }

    pub fn detectStickerFormat(file_data: []const u8) ?StickerFormatType {
        // Detect file format from magic bytes
        if (file_data.len >= 8) {
            // PNG signature: 89 50 4E 47 0D 0A 1A 0A
            if (std.mem.eql(u8, file_data[0..8], "\x89PNG\r\n\x1a\n")) {
                return .png;
            }
        }

        if (file_data.len >= 6) {
            // APNG starts with PNG signature
            if (std.mem.eql(u8, file_data[0..6], "\x89PNG")) {
                return .apng;
            }
        }

        // Lottie JSON files start with {
        if (file_data.len > 0 and file_data[0] == '{') {
            return .lottie;
        }

        return null;
    }
};
