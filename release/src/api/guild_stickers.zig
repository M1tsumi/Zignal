const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild sticker management for custom sticker operations
pub const GuildStickerManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildStickerManager {
        return GuildStickerManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get sticker
    pub fn getSticker(self: *GuildStickerManager, sticker_id: u64) !models.Sticker {
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

    /// List sticker packs
    pub fn listStickerPacks(self: *GuildStickerManager) !struct {
        sticker_packs: []models.StickerPack,
    } {
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

        return try std.json.parse(struct {
            sticker_packs: []models.StickerPack,
        }, response.body, .{});
    }

    /// List guild stickers
    pub fn listGuildStickers(self: *GuildStickerManager, guild_id: u64) ![]models.Sticker {
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

    /// Get guild sticker
    pub fn getGuildSticker(self: *GuildStickerManager, guild_id: u64, sticker_id: u64) !models.Sticker {
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

    /// Create guild sticker
    pub fn createGuildSticker(
        self: *GuildStickerManager,
        guild_id: u64,
        name: []const u8,
        description: []const u8,
        tags: []const u8,
        file_data: []const u8,
    ) !models.Sticker {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/stickers",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        // Create multipart form data
        var form_data = std.http.MultipartForm.init(self.allocator);
        defer form_data.deinit();

        try form_data.addFormData("name", name);
        try form_data.addFormData("description", description);
        try form_data.addFormData("tags", tags);
        try form_data.addFileData("file", "sticker.png", file_data);

        const response = try self.client.http.postMultipart(url, form_data);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Sticker, response.body, .{});
    }

    /// Modify guild sticker
    pub fn modifyGuildSticker(
        self: *GuildStickerManager,
        guild_id: u64,
        sticker_id: u64,
        name: ?[]const u8,
        description: ?[]const u8,
        tags: ?[]const u8,
    ) !models.Sticker {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/stickers/{d}",
            .{ self.client.base_url, guild_id, sticker_id },
        );
        defer self.allocator.free(url);

        const payload = struct {
            name: ?[]const u8,
            description: ?[]const u8,
            tags: ?[]const u8,
        }{
            .name = name,
            .description = description,
            .tags = tags,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Sticker, response.body, .{});
    }

    /// Delete guild sticker
    pub fn deleteGuildSticker(
        self: *GuildStickerManager,
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
};

/// Guild sticker utilities
pub const GuildStickerUtils = struct {
    pub fn getStickerId(sticker: models.Sticker) u64 {
        return sticker.id;
    }

    pub fn getStickerName(sticker: models.Sticker) []const u8 {
        return sticker.name;
    }

    pub fn getStickerDescription(sticker: models.Sticker) []const u8 {
        return sticker.description;
    }

    pub fn getStickerTags(sticker: models.Sticker) []const u8 {
        return sticker.tags;
    }

    pub fn getStickerType(sticker: models.Sticker) u8 {
        return sticker.type;
    }

    pub fn getStickerFormatType(sticker: models.Sticker) u8 {
        return sticker.format_type;
    }

    pub fn getStickerAvailable(sticker: models.Sticker) bool {
        return sticker.available;
    }

    pub fn getStickerSortValue(sticker: models.Sticker) u64 {
        return sticker.sort_value;
    }

    pub fn getStickerUser(sticker: models.Sticker) ?models.User {
        return sticker.user;
    }

    pub fn getStickerUserId(sticker: models.Sticker) ?u64 {
        if (sticker.user) |user| {
            return user.id;
        }
        return null;
    }

    pub fn getStickerPackId(sticker: models.Sticker) ?u64 {
        return sticker.pack_id;
    }

    pub fn isStickerAvailable(sticker: models.Sticker) bool {
        return sticker.available;
    }

    pub fn isStickerGuild(sticker: models.Sticker) bool {
        return getStickerType(sticker) == 1; // GUILD type
    }

    pub fn isStickerStandard(sticker: models.Sticker) bool {
        return getStickerType(sticker) == 2; // STANDARD type
    }

    pub fn isStickerPNG(sticker: models.Sticker) bool {
        return getStickerFormatType(sticker) == 1; // PNG format
    }

    pub fn isStickerAPNG(sticker: models.Sticker) bool {
        return getStickerFormatType(sticker) == 2; // APNG format
    }

    pub fn isStickerLottie(sticker: models.Sticker) bool {
        return getStickerFormatType(sticker) == 3; // Lottie format
    }

    pub fn isStickerGIF(sticker: models.Sticker) bool {
        return getStickerFormatType(sticker) == 4; // GIF format
    }

    pub fn formatStickerString(sticker: models.Sticker) []const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "<:{s}:{d}>",
            .{ getStickerName(sticker), getStickerId(sticker) },
        );
    }

    pub fn formatStickerUrl(sticker: models.Sticker, size: u16) []const u8 {
        const format = switch (getStickerFormatType(sticker)) {
            1 => "png",
            2 => "png",
            3 => "json",
            4 => "gif",
            else => "png",
        };

        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "https://cdn.discordapp.com/stickers/{d}.{s}?size={d}",
            .{ getStickerId(sticker), format, size },
        );
    }

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

    pub fn validateSticker(sticker: models.Sticker) bool {
        if (!validateStickerName(getStickerName(sticker))) return false;
        if (!validateStickerDescription(getStickerDescription(sticker))) return false;
        if (!validateStickerTags(getStickerTags(sticker))) return false;
        if (getStickerId(sticker) == 0) return false;

        return true;
    }

    pub fn getStickersByName(stickers: []models.Sticker, name: []const u8) []models.Sticker {
        var filtered = std.ArrayList(models.Sticker).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (stickers) |sticker| {
            if (std.mem.eql(u8, getStickerName(sticker), name)) {
                filtered.append(sticker) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Sticker{};
    }

    pub fn getStickersByTag(stickers: []models.Sticker, tag: []const u8) []models.Sticker {
        var filtered = std.ArrayList(models.Sticker).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (stickers) |sticker| {
            if (std.mem.indexOf(u8, getStickerTags(sticker), tag) != null) {
                filtered.append(sticker) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Sticker{};
    }

    pub fn getAvailableStickers(stickers: []models.Sticker) []models.Sticker {
        var filtered = std.ArrayList(models.Sticker).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (stickers) |sticker| {
            if (isStickerAvailable(sticker)) {
                filtered.append(sticker) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Sticker{};
    }

    pub fn getUnavailableStickers(stickers: []models.Sticker) []models.Sticker {
        var filtered = std.ArrayList(models.Sticker).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (stickers) |sticker| {
            if (!isStickerAvailable(sticker)) {
                filtered.append(sticker) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Sticker{};
    }

    pub fn getGuildStickers(stickers: []models.Sticker) []models.Sticker {
        var filtered = std.ArrayList(models.Sticker).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (stickers) |sticker| {
            if (isStickerGuild(sticker)) {
                filtered.append(sticker) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Sticker{};
    }

    pub fn getStandardStickers(stickers: []models.Sticker) []models.Sticker {
        var filtered = std.ArrayList(models.Sticker).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (stickers) |sticker| {
            if (isStickerStandard(sticker)) {
                filtered.append(sticker) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Sticker{};
    }

    pub fn getStickersByFormat(stickers: []models.Sticker, format_type: u8) []models.Sticker {
        var filtered = std.ArrayList(models.Sticker).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (stickers) |sticker| {
            if (getStickerFormatType(sticker) == format_type) {
                filtered.append(sticker) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Sticker{};
    }

    pub fn searchStickers(stickers: []models.Sticker, query: []const u8) []models.Sticker {
        var results = std.ArrayList(models.Sticker).init(std.heap.page_allocator);
        defer results.deinit();

        for (stickers) |sticker| {
            if (std.mem.indexOf(u8, getStickerName(sticker), query) != null or
                std.mem.indexOf(u8, getStickerDescription(sticker), query) != null or
                std.mem.indexOf(u8, getStickerTags(sticker), query) != null)
            {
                results.append(sticker) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.Sticker{};
    }

    pub fn sortStickersByName(stickers: []models.Sticker) void {
        std.sort.sort(models.Sticker, stickers, {}, compareStickersByName);
    }

    pub fn sortStickersById(stickers: []models.Sticker) void {
        std.sort.sort(models.Sticker, stickers, {}, compareStickersById);
    }

    pub fn sortStickersBySortValue(stickers: []models.Sticker) void {
        std.sort.sort(models.Sticker, stickers, {}, compareStickersBySortValue);
    }

    fn compareStickersByName(_: void, a: models.Sticker, b: models.Sticker) std.math.Order {
        return std.mem.compare(u8, getStickerName(a), getStickerName(b));
    }

    fn compareStickersById(_: void, a: models.Sticker, b: models.Sticker) std.math.Order {
        return std.math.order(getStickerId(a), getStickerId(b));
    }

    fn compareStickersBySortValue(_: void, a: models.Sticker, b: models.Sticker) std.math.Order {
        return std.math.order(getStickerSortValue(a), getStickerSortValue(b));
    }

    pub fn getStickerStatistics(stickers: []models.Sticker) struct {
        total_stickers: usize,
        available_stickers: usize,
        unavailable_stickers: usize,
        guild_stickers: usize,
        standard_stickers: usize,
        png_stickers: usize,
        apng_stickers: usize,
        lottie_stickers: usize,
        gif_stickers: usize,
    } {
        var available_count: usize = 0;
        var guild_count: usize = 0;
        var standard_count: usize = 0;
        var png_count: usize = 0;
        var apng_count: usize = 0;
        var lottie_count: usize = 0;
        var gif_count: usize = 0;

        for (stickers) |sticker| {
            if (isStickerAvailable(sticker)) {
                available_count += 1;
            }

            if (isStickerGuild(sticker)) {
                guild_count += 1;
            } else {
                standard_count += 1;
            }

            if (isStickerPNG(sticker)) {
                png_count += 1;
            } else if (isStickerAPNG(sticker)) {
                apng_count += 1;
            } else if (isStickerLottie(sticker)) {
                lottie_count += 1;
            } else if (isStickerGIF(sticker)) {
                gif_count += 1;
            }
        }

        return .{
            .total_stickers = stickers.len,
            .available_stickers = available_count,
            .unavailable_stickers = stickers.len - available_count,
            .guild_stickers = guild_count,
            .standard_stickers = standard_count,
            .png_stickers = png_count,
            .apng_stickers = apng_count,
            .lottie_stickers = lottie_count,
            .gif_stickers = gif_count,
        };
    }

    pub fn hasSticker(stickers: []models.Sticker, sticker_id: u64) bool {
        for (stickers) |sticker| {
            if (getStickerId(sticker) == sticker_id) {
                return true;
            }
        }
        return false;
    }

    pub fn getSticker(stickers: []models.Sticker, sticker_id: u64) ?models.Sticker {
        for (stickers) |sticker| {
            if (getStickerId(sticker) == sticker_id) {
                return sticker;
            }
        }
        return null;
    }

    pub fn getStickerCount(stickers: []models.Sticker) usize {
        return stickers.len;
    }

    pub fn getStickerTagsAsArray(sticker: models.Sticker) []const u8 {
        const tags = getStickerTags(sticker);
        var tag_list = std.ArrayList([]const u8).init(std.heap.page_allocator);
        defer tag_list.deinit();

        var start: usize = 0;
        for (tags, 0..) |char, i| {
            if (char == ',') {
                const tag = tags[start..i];
                if (tag.len > 0) {
                    tag_list.append(tag) catch {};
                }
                start = i + 1;
            }
        }

        // Add the last tag
        if (start < tags.len) {
            const tag = tags[start..];
            if (tag.len > 0) {
                tag_list.append(tag) catch {};
            }
        }

        return tag_list.toOwnedSlice() catch &[_][]const u8{};
    }

    pub fn formatStickerSummary(sticker: models.Sticker) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getStickerName(sticker));
        try summary.appendSlice(" (ID: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getStickerId(sticker)}));
        try summary.appendSlice(")");

        if (!isStickerAvailable(sticker)) {
            try summary.appendSlice(" [Unavailable]");
        }

        const format_name = switch (getStickerFormatType(sticker)) {
            1 => "PNG",
            2 => "APNG",
            3 => "Lottie",
            4 => "GIF",
            else => "Unknown",
        };

        try summary.appendSlice(" [");
        try summary.appendSlice(format_name);
        try summary.appendSlice("]");

        return summary.toOwnedSlice();
    }

    pub fn formatFullStickerInfo(sticker: models.Sticker) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Sticker: ");
        try info.appendSlice(getStickerName(sticker));
        try info.appendSlice("\n");
        try info.appendSlice("ID: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getStickerId(sticker)}));
        try info.appendSlice("\n");
        try info.appendSlice("Description: ");
        try info.appendSlice(getStickerDescription(sticker));
        try info.appendSlice("\n");
        try info.appendSlice("Tags: ");
        try info.appendSlice(getStickerTags(sticker));
        try info.appendSlice("\n");
        try info.appendSlice("Type: ");
        try info.appendSlice(if (isStickerGuild(sticker)) "Guild" else "Standard");
        try info.appendSlice("\n");
        try info.appendSlice("Format: ");

        const format_name = switch (getStickerFormatType(sticker)) {
            1 => "PNG",
            2 => "APNG",
            3 => "Lottie",
            4 => "GIF",
            else => "Unknown",
        };

        try info.appendSlice(format_name);
        try info.appendSlice("\n");
        try info.appendSlice("Available: ");
        try info.appendSlice(if (isStickerAvailable(sticker)) "Yes" else "No");

        if (getStickerUser(sticker)) |user| {
            try info.appendSlice("\n");
            try info.appendSlice("Created by: ");
            try info.appendSlice(user.username);
            try info.appendSlice("#");
            try info.appendSlice(user.discriminator);
        }

        return info.toOwnedSlice();
    }
};
