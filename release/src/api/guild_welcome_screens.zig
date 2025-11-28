const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild welcome screen management for server customization
pub const GuildWelcomeScreenManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildWelcomeScreenManager {
        return GuildWelcomeScreenManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild welcome screen
    pub fn getGuildWelcomeScreen(self: *GuildWelcomeScreenManager, guild_id: u64) !models.WelcomeScreen {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/welcome-screen",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.WelcomeScreen, response.body, .{});
    }

    /// Modify guild welcome screen
    pub fn modifyGuildWelcomeScreen(
        self: *GuildWelcomeScreenManager,
        guild_id: u64,
        enabled: ?bool,
        welcome_channels: ?[]WelcomeChannelPayload,
        description: ?[]const u8,
        reason: ?[]const u8,
    ) !models.WelcomeScreen {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/welcome-screen",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyWelcomeScreenPayload{
            .enabled = enabled,
            .welcome_channels = welcome_channels,
            .description = description,
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

        return try std.json.parse(models.WelcomeScreen, response.body, .{});
    }
};

/// Payload for welcome channel
pub const WelcomeChannelPayload = struct {
    channel_id: u64,
    description: []const u8,
    emoji_id: ?u64 = null,
    emoji_name: ?[]const u8 = null,
};

/// Payload for modifying welcome screen
pub const ModifyWelcomeScreenPayload = struct {
    enabled: ?bool = null,
    welcome_channels: ?[]WelcomeChannelPayload = null,
    description: ?[]const u8 = null,
};

/// Welcome screen utilities
pub const GuildWelcomeScreenUtils = struct {
    pub fn isWelcomeScreenEnabled(welcome_screen: models.WelcomeScreen) bool {
        return welcome_screen.enabled;
    }

    pub fn getWelcomeChannelCount(welcome_screen: models.WelcomeScreen) usize {
        return welcome_screen.welcome_channels.len;
    }

    pub fn getWelcomeChannelById(welcome_screen: models.WelcomeScreen, channel_id: u64) ?models.WelcomeScreenChannel {
        for (welcome_screen.welcome_channels) |channel| {
            if (channel.channel_id == channel_id) {
                return channel;
            }
        }
        return null;
    }

    pub fn getWelcomeChannelEmoji(welcome_screen: models.WelcomeScreen, channel_id: u64) ?models.Emoji {
        if (getWelcomeChannelById(welcome_screen, channel_id)) |channel| {
            return channel.emoji;
        }
        return null;
    }

    pub fn getWelcomeChannelDescription(welcome_screen: models.WelcomeScreen, channel_id: u64) ?[]const u8 {
        if (getWelcomeChannelById(welcome_screen, channel_id)) |channel| {
            return channel.description;
        }
        return null;
    }

    pub fn hasWelcomeChannel(welcome_screen: models.WelcomeScreen, channel_id: u64) bool {
        return getWelcomeChannelById(welcome_screen, channel_id) != null;
    }

    pub fn getWelcomeChannelEmojiUrl(channel: models.WelcomeScreenChannel) ?[]const u8 {
        if (channel.emoji) |emoji| {
            if (emoji.id != 0) {
                return try std.fmt.allocPrint(
                    std.heap.page_allocator,
                    "https://cdn.discordapp.com/emojis/{d}.png",
                    .{emoji.id},
                );
            }
        }
        return null;
    }

    pub fn isCustomEmoji(channel: models.WelcomeScreenChannel) bool {
        if (channel.emoji) |emoji| {
            return emoji.id != 0;
        }
        return false;
    }

    pub fn isUnicodeEmoji(channel: models.WelcomeScreenChannel) bool {
        if (channel.emoji) |emoji| {
            return emoji.id == 0;
        }
        return false;
    }

    pub fn getEmojiDisplay(channel: models.WelcomeScreenChannel) []const u8 {
        if (channel.emoji) |emoji| {
            if (isCustomEmoji(channel)) {
                return emoji.name;
            } else {
                return emoji.name; // Unicode emoji
            }
        }
        return "";
    }

    pub fn formatWelcomeChannel(channel: models.WelcomeScreenChannel) []const u8 {
        var formatted = std.ArrayList(u8).init(std.heap.page_allocator);
        defer formatted.deinit();

        if (channel.emoji) |_| {
            try formatted.appendSlice(getEmojiDisplay(channel));
            try formatted.appendSlice(" ");
        }

        try formatted.appendSlice(channel.description);
        try formatted.appendSlice(" (Channel: ");
        try formatted.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{channel.channel_id}));
        try formatted.appendSlice(")");

        return formatted.toOwnedSlice();
    }

    pub fn formatWelcomeScreen(welcome_screen: models.WelcomeScreen) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Welcome Screen: ");
        try summary.appendSlice(if (isWelcomeScreenEnabled(welcome_screen)) "Enabled" else "Disabled");

        if (welcome_screen.description) |desc| {
            try summary.appendSlice(" - Description: ");
            try summary.appendSlice(desc);
        }

        try summary.appendSlice(" - Channels: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getWelcomeChannelCount(welcome_screen)}));

        return summary.toOwnedSlice();
    }

    pub fn validateWelcomeScreen(welcome_screen: models.WelcomeScreen) bool {
        // Basic validation checks
        if (welcome_screen.guild_id == 0) return false;

        // Validate welcome channels
        for (welcome_screen.welcome_channels) |channel| {
            if (!validateWelcomeChannel(channel)) {
                return false;
            }
        }

        return true;
    }

    pub fn validateWelcomeChannel(channel: models.WelcomeScreenChannel) bool {
        if (channel.channel_id == 0) return false;
        if (channel.description.len == 0) return false;

        // Validate emoji if present
        if (channel.emoji) |emoji| {
            if (emoji.name.len == 0) return false;
        }

        return true;
    }

    pub fn validateWelcomeChannelPayload(payload: WelcomeChannelPayload) bool {
        if (payload.channel_id == 0) return false;
        if (payload.description.len == 0) return false;

        // Validate emoji if present
        if (payload.emoji_name) |name| {
            if (name.len == 0) return false;
        }

        return true;
    }

    pub fn validateWelcomeScreenDescription(description: []const u8) bool {
        // Welcome screen descriptions must be 0-1000 characters
        return description.len <= 1000;
    }

    pub fn validateWelcomeChannelDescription(description: []const u8) bool {
        // Welcome channel descriptions must be 1-100 characters
        return description.len >= 1 and description.len <= 100;
    }

    pub fn getWelcomeScreenStatistics(welcome_screen: models.WelcomeScreen) struct {
        total_channels: usize,
        custom_emoji_channels: usize,
        unicode_emoji_channels: usize,
        no_emoji_channels: usize,
        has_description: bool,
        enabled: bool,
    } {
        var custom_emoji_count: usize = 0;
        var unicode_emoji_count: usize = 0;
        var no_emoji_count: usize = 0;

        for (welcome_screen.welcome_channels) |channel| {
            if (channel.emoji) |emoji| {
                if (emoji.id != 0) {
                    custom_emoji_count += 1;
                } else {
                    unicode_emoji_count += 1;
                }
            } else {
                no_emoji_count += 1;
            }
        }

        return .{
            .total_channels = getWelcomeChannelCount(welcome_screen),
            .custom_emoji_channels = custom_emoji_count,
            .unicode_emoji_channels = unicode_emoji_count,
            .no_emoji_channels = no_emoji_count,
            .has_description = welcome_screen.description != null,
            .enabled = isWelcomeScreenEnabled(welcome_screen),
        };
    }

    pub fn createWelcomeChannelPayload(
        channel_id: u64,
        description: []const u8,
        emoji_id: ?u64,
        emoji_name: ?[]const u8,
    ) WelcomeChannelPayload {
        return WelcomeChannelPayload{
            .channel_id = channel_id,
            .description = description,
            .emoji_id = emoji_id,
            .emoji_name = emoji_name,
        };
    }

    pub fn createWelcomeChannelPayloadWithCustomEmoji(
        channel_id: u64,
        description: []const u8,
        emoji_id: u64,
        emoji_name: []const u8,
    ) WelcomeChannelPayload {
        return createWelcomeChannelPayload(channel_id, description, emoji_id, emoji_name);
    }

    pub fn createWelcomeChannelPayloadWithUnicodeEmoji(
        channel_id: u64,
        description: []const u8,
        emoji_name: []const u8,
    ) WelcomeChannelPayload {
        return createWelcomeChannelPayload(channel_id, description, null, emoji_name);
    }

    pub fn createWelcomeChannelPayloadNoEmoji(
        channel_id: u64,
        description: []const u8,
    ) WelcomeChannelPayload {
        return createWelcomeChannelPayload(channel_id, description, null, null);
    }

    pub fn getWelcomeChannelsByEmojiType(
        welcome_screen: models.WelcomeScreen,
        emoji_type: EmojiType,
    ) []models.WelcomeScreenChannel {
        var filtered = std.ArrayList(models.WelcomeScreenChannel).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (welcome_screen.welcome_channels) |channel| {
            switch (emoji_type) {
                .custom => {
                    if (isCustomEmoji(channel)) {
                        filtered.append(channel) catch {};
                    }
                },
                .unicode => {
                    if (isUnicodeEmoji(channel)) {
                        filtered.append(channel) catch {};
                    }
                },
                .none => {
                    if (channel.emoji == null) {
                        filtered.append(channel) catch {};
                    }
                },
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.WelcomeScreenChannel{};
    }

    pub fn getCustomEmojiChannels(welcome_screen: models.WelcomeScreen) []models.WelcomeScreenChannel {
        return getWelcomeChannelsByEmojiType(welcome_screen, .custom);
    }

    pub fn getUnicodeEmojiChannels(welcome_screen: models.WelcomeScreen) []models.WelcomeScreenChannel {
        return getWelcomeChannelsByEmojiType(welcome_screen, .unicode);
    }

    pub fn getNoEmojiChannels(welcome_screen: models.WelcomeScreen) []models.WelcomeScreenChannel {
        return getWelcomeChannelsByEmojiType(welcome_screen, .none);
    }

    pub fn searchWelcomeChannelsByDescription(
        welcome_screen: models.WelcomeScreen,
        search_term: []const u8,
    ) []models.WelcomeScreenChannel {
        var results = std.ArrayList(models.WelcomeScreenChannel).init(std.heap.page_allocator);
        defer results.deinit();

        for (welcome_screen.welcome_channels) |channel| {
            if (std.mem.indexOf(u8, channel.description, search_term) != null) {
                results.append(channel) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.WelcomeScreenChannel{};
    }

    pub fn getWelcomeChannelSummary(channel: models.WelcomeScreenChannel) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Channel: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{channel.channel_id}));
        try summary.appendSlice(" - ");

        if (channel.emoji) |emoji| {
            try summary.appendSlice(emoji.name);
            try summary.appendSlice(" ");
        }

        try summary.appendSlice(channel.description);

        return summary.toOwnedSlice();
    }

    pub fn getWelcomeScreenFullSummary(welcome_screen: models.WelcomeScreen) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Welcome Screen: ");
        try summary.appendSlice(if (isWelcomeScreenEnabled(welcome_screen)) "Enabled" else "Disabled");

        if (welcome_screen.description) |desc| {
            try summary.appendSlice("\nDescription: ");
            try summary.appendSlice(desc);
        }

        try summary.appendSlice("\nChannels:");
        for (welcome_screen.welcome_channels, 0..) |channel, i| {
            try summary.appendSlice("\n  ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}. ", .{i + 1}));
            try summary.appendSlice(getWelcomeChannelSummary(channel));
        }

        return summary.toOwnedSlice();
    }
};

pub const EmojiType = enum {
    custom,
    unicode,
    none,
};
