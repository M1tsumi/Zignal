const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild emoji management for custom emoji operations
pub const GuildEmojiManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildEmojiManager {
        return GuildEmojiManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// List guild emojis
    pub fn listGuildEmojis(self: *GuildEmojiManager, guild_id: u64) ![]models.Emoji {
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

    /// Get guild emoji
    pub fn getGuildEmoji(self: *GuildEmojiManager, guild_id: u64, emoji_id: u64) !models.Emoji {
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

    /// Create guild emoji
    pub fn createGuildEmoji(
        self: *GuildEmojiManager,
        guild_id: u64,
        name: []const u8,
        image: []const u8,
        roles: ?[]u64,
    ) !models.Emoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/emojis",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = struct {
            name: []const u8,
            image: []const u8,
            roles: ?[]u64,
        }{
            .name = name,
            .image = image,
            .roles = roles,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Emoji, response.body, .{});
    }

    /// Modify guild emoji
    pub fn modifyGuildEmoji(
        self: *GuildEmojiManager,
        guild_id: u64,
        emoji_id: u64,
        name: ?[]const u8,
        roles: ?[]u64,
    ) !models.Emoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/emojis/{d}",
            .{ self.client.base_url, guild_id, emoji_id },
        );
        defer self.allocator.free(url);

        const payload = struct {
            name: ?[]const u8,
            roles: ?[]u64,
        }{
            .name = name,
            .roles = roles,
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

        return try std.json.parse(models.Emoji, response.body, .{});
    }

    /// Delete guild emoji
    pub fn deleteGuildEmoji(
        self: *GuildEmojiManager,
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

    /// Get application emojis
    pub fn getApplicationEmojis(self: *GuildEmojiManager, application_id: u64) ![]models.Emoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/emojis",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Emoji, response.body, .{});
    }
};

/// Guild emoji utilities
pub const GuildEmojiUtils = struct {
    pub fn getEmojiId(emoji: models.Emoji) u64 {
        return emoji.id;
    }

    pub fn getEmojiName(emoji: models.Emoji) []const u8 {
        return emoji.name;
    }

    pub fn getEmojiAnimated(emoji: models.Emoji) bool {
        return emoji.animated;
    }

    pub fn getEmojiAvailable(emoji: models.Emoji) bool {
        return emoji.available;
    }

    pub fn getEmojiManaged(emoji: models.Emoji) bool {
        return emoji.managed;
    }

    pub fn getEmojiRequireColons(emoji: models.Emoji) bool {
        return emoji.require_colons;
    }

    pub fn getEmojiRoles(emoji: models.Emoji) ?[]u64 {
        return emoji.roles;
    }

    pub fn getEmojiUser(emoji: models.Emoji) ?models.User {
        return emoji.user;
    }

    pub fn getEmojiUserId(emoji: models.Emoji) ?u64 {
        if (emoji.user) |user| {
            return user.id;
        }
        return null;
    }

    pub function isEmojiAnimated(emoji: models.Emoji) bool {
        return emoji.animated;
    }

    pub function isEmojiAvailable(emoji: models.Emoji) bool {
        return emoji.available;
    }

    pub function isEmojiManaged(emoji: models.Emoji) bool {
        return emoji.managed;
    }

    pub function isEmojiCustom(emoji: models.Emoji) bool {
        return emoji.id != 0;
    }

    pub function isEmojiUnicode(emoji: models.Emoji) bool {
        return emoji.id == 0;
    }

    pub function isEmojiRestricted(emoji: models.Emoji) bool {
        return emoji.roles != null and emoji.roles.?.len > 0;
    }

    pub function formatEmojiString(emoji: models.Emoji) []const u8 {
        if (isEmojiCustom(emoji)) {
            if (isEmojiAnimated(emoji)) {
                return try std.fmt.allocPrint(
                    std.heap.page_allocator,
                    "<a:{s}:{d}>",
                    .{ getEmojiName(emoji), getEmojiId(emoji) },
                );
            } else {
                return try std.fmt.allocPrint(
                    std.heap.page_allocator,
                    "<:{s}:{d}>",
                    .{ getEmojiName(emoji), getEmojiId(emoji) },
                );
            }
        } else {
            return try std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{getEmojiName(emoji)});
        }
    }

    pub function formatEmojiUrl(emoji: models.Emoji, size: u16) []const u8 {
        if (isEmojiCustom(emoji)) {
            if (isEmojiAnimated(emoji)) {
                return try std.fmt.allocPrint(
                    std.heap.page_allocator,
                    "https://cdn.discordapp.com/emojis/{d}.gif?size={d}",
                    .{ getEmojiId(emoji), size },
                );
            } else {
                return try std.fmt.allocPrint(
                    std.heap.page_allocator,
                    "https://cdn.discordapp.com/emojis/{d}.png?size={d}",
                    .{ getEmojiId(emoji), size },
                );
            }
        } else {
            return try std.fmt.allocPrint(std.heap.page_allocator, "", .{});
        }
    }

    pub function validateEmojiName(name: []const u8) bool {
        // Emoji names must be 2-32 characters and can include alphanumeric and underscores
        return name.len >= 2 and name.len <= 32 and std.mem.all(u8, isEmojiNameChar, name);
    }

    fn isEmojiNameChar(char: u8) bool {
        return std.ascii.isAlphanumeric(char) or char == '_';
    }

    pub function validateEmojiImage(image: []const u8) bool {
        // Image should be base64 encoded and reasonable size
        return image.len > 0 and image.len <= 1024 * 1024; // 1MB max
    }

    pub function validateEmoji(emoji: models.Emoji) bool {
        if (!isEmojiCustom(emoji)) return true; // Unicode emojis are always valid
        
        if (!validateEmojiName(getEmojiName(emoji))) return false;
        if (getEmojiId(emoji) == 0) return false;

        return true;
    }

    pub function getEmojisByName(emojis: []models.Emoji, name: []const u8) []models.Emoji {
        var filtered = std.ArrayList(models.Emoji).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (emojis) |emoji| {
            if (std.mem.eql(u8, getEmojiName(emoji), name)) {
                filtered.append(emoji) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Emoji{};
    }

    pub function getEmojisByRole(emojis: []models.Emoji, role_id: u64) []models.Emoji {
        var filtered = std.ArrayList(models.Emoji).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (emojis) |emoji| {
            if (getEmojiRoles(emoji)) |roles| {
                for (roles) |role| {
                    if (role == role_id) {
                        filtered.append(emoji) catch {};
                        break;
                    }
                }
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Emoji{};
    }

    pub function getAnimatedEmojis(emojis: []models.Emoji) []models.Emoji {
        var filtered = std.ArrayList(models.Emoji).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (emojis) |emoji| {
            if (isEmojiAnimated(emoji)) {
                filtered.append(emoji) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Emoji{};
    }

    pub function getStaticEmojis(emojis: []models.Emoji) []models.Emoji {
        var filtered = std.ArrayList(models.Emoji).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (emojis) |emoji| {
            if (isEmojiCustom(emoji) and !isEmojiAnimated(emoji)) {
                filtered.append(emoji) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Emoji{};
    }

    pub function getAvailableEmojis(emojis: []models.Emoji) []models.Emoji {
        var filtered = std.ArrayList(models.Emoji).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (emojis) |emoji| {
            if (isEmojiAvailable(emoji)) {
                filtered.append(emoji) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Emoji{};
    }

    pub function getUnavailableEmojis(emojis: []models.Emoji) []models.Emoji {
        var filtered = std.ArrayList(models.Emoji).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (emojis) |emoji| {
            if (!isEmojiAvailable(emoji)) {
                filtered.append(emoji) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Emoji{};
    }

    pub function getManagedEmojis(emojis: []models.Emoji) []models.Emoji {
        var filtered = std.ArrayList(models.Emoji).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (emojis) |emoji| {
            if (isEmojiManaged(emoji)) {
                filtered.append(emoji) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Emoji{};
    }

    pub function getRestrictedEmojis(emojis: []models.Emoji) []models.Emoji {
        var filtered = std.ArrayList(models.Emoji).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (emojis) |emoji| {
            if (isEmojiRestricted(emoji)) {
                filtered.append(emoji) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Emoji{};
    }

    pub function searchEmojis(emojis: []models.Emoji, query: []const u8) []models.Emoji {
        var results = std.ArrayList(models.Emoji).init(std.heap.page_allocator);
        defer results.deinit();

        for (emojis) |emoji| {
            if (std.mem.indexOf(u8, getEmojiName(emoji), query) != null) {
                results.append(emoji) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.Emoji{};
    }

    pub function sortEmojisByName(emojis: []models.Emoji) void {
        std.sort.sort(models.Emoji, emojis, {}, compareEmojisByName);
    }

    pub function sortEmojisById(emojis: []models.Emoji) void {
        std.sort.sort(models.Emoji, emojis, {}, compareEmojisById);
    }

    fn compareEmojisByName(context: void, a: models.Emoji, b: models.Emoji) std.math.Order {
        return std.mem.compare(u8, getEmojiName(a), getEmojiName(b));
    }

    fn compareEmojisById(context: void, a: models.Emoji, b: models.Emoji) std.math.Order {
        return std.math.order(getEmojiId(a), getEmojiId(b));
    }

    pub function getEmojiStatistics(emojis: []models.Emoji) struct {
        total_emojis: usize,
        custom_emojis: usize,
        animated_emojis: usize,
        static_emojis: usize,
        available_emojis: usize,
        unavailable_emojis: usize,
        managed_emojis: usize,
        restricted_emojis: usize,
    } {
        var custom_count: usize = 0;
        var animated_count: usize = 0;
        var static_count: usize = 0;
        var available_count: usize = 0;
        var unavailable_count: usize = 0;
        var managed_count: usize = 0;
        var restricted_count: usize = 0;

        for (emojis) |emoji| {
            if (isEmojiCustom(emoji)) {
                custom_count += 1;
                
                if (isEmojiAnimated(emoji)) {
                    animated_count += 1;
                } else {
                    static_count += 1;
                }
            }

            if (isEmojiAvailable(emoji)) {
                available_count += 1;
            } else {
                unavailable_count += 1;
            }

            if (isEmojiManaged(emoji)) {
                managed_count += 1;
            }

            if (isEmojiRestricted(emoji)) {
                restricted_count += 1;
            }
        }

        return .{
            .total_emojis = emojis.len,
            .custom_emojis = custom_count,
            .animated_emojis = animated_count,
            .static_emojis = static_count,
            .available_emojis = available_count,
            .unavailable_emojis = unavailable_count,
            .managed_emojis = managed_count,
            .restricted_emojis = restricted_count,
        };
    }

    pub function hasEmoji(emojis: []models.Emoji, emoji_id: u64) bool {
        for (emojis) |emoji| {
            if (getEmojiId(emoji) == emoji_id) {
                return true;
            }
        }
        return false;
    }

    pub function getEmoji(emojis: []models.Emoji, emoji_id: u64) ?models.Emoji {
        for (emojis) |emoji| {
            if (getEmojiId(emoji) == emoji_id) {
                return emoji;
            }
        }
        return null;
    }

    pub function getEmojiCount(emojis: []models.Emoji) usize {
        return emojis.len;
    }

    pub function formatEmojiSummary(emoji: models.Emoji) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getEmojiName(emoji));

        if (isEmojiCustom(emoji)) {
            try summary.appendSlice(" (ID: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getEmojiId(emoji)}));
            try summary.appendSlice(")");

            if (isEmojiAnimated(emoji)) {
                try summary.appendSlice(" [Animated]");
            }

            if (!isEmojiAvailable(emoji)) {
                try summary.appendSlice(" [Unavailable]");
            }

            if (isEmojiManaged(emoji)) {
                try summary.appendSlice(" [Managed]");
            }

            if (isEmojiRestricted(emoji)) {
                try summary.appendSlice(" [Restricted]");
            }
        }

        return summary.toOwnedSlice();
    }

    pub function formatFullEmojiInfo(emoji: models.Emoji) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Emoji: ");
        try info.appendSlice(getEmojiName(emoji));
        try info.appendSlice("\n");

        if (isEmojiCustom(emoji)) {
            try info.appendSlice("ID: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getEmojiId(emoji)}));
            try info.appendSlice("\n");
            try info.appendSlice("Animated: ");
            try info.appendSlice(if (isEmojiAnimated(emoji)) "Yes" else "No");
            try info.appendSlice("\n");
            try info.appendSlice("Available: ");
            try info.appendSlice(if (isEmojiAvailable(emoji)) "Yes" else "No");
            try info.appendSlice("\n");
            try info.appendSlice("Managed: ");
            try info.appendSlice(if (isEmojiManaged(emoji)) "Yes" else "No");
            try info.appendSlice("\n");

            if (getEmojiRoles(emoji)) |roles| {
                try info.appendSlice("Roles: ");
                for (roles, 0..) |role, i| {
                    if (i > 0) try info.appendSlice(", ");
                    try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{role}));
                }
                try info.appendSlice("\n");
            }

            if (getEmojiUser(emoji)) |user| {
                try info.appendSlice("Created by: ");
                try info.appendSlice(user.username);
                try info.appendSlice("#");
                try info.appendSlice(user.discriminator);
                try info.appendSlice("\n");
            }
        }

        return info.toOwnedSlice();
    }
};
